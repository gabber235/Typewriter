package com.typewritermc.realm.routes

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchQuery
import com.typewritermc.capability.RealmSearchSelector
import com.typewritermc.capability.RealmSearchSelectorExpression
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.realm.RealmDiscoverySnapshotStore
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.diagnostic.TypeDiagnostic
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.search.RealmSearchSelectorExpression as WireSelectorExpression
import java.util.concurrent.ConcurrentHashMap

interface RealmPresentationSearchSource {
    suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate

    fun cancel(subscriptionId: String): Boolean
}

fun interface RealmPresentationSearchUpdatePublisher {
    suspend fun publish(update: RealmPresentationSearchUpdate)
}

class UnavailableRealmPresentationSearchSource : RealmPresentationSearchSource {
    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate = unavailableRealmPresentationSearchUpdate(request.subscriptionId)

    override fun cancel(subscriptionId: String): Boolean = false
}

class CapabilityRealmPresentationSearchSource(
    private val scope: CoroutineScope,
    private val capabilities: RealmCapabilityRegistry,
    private val prototypes: TypePrototypeRegistry,
    private val snapshots: RealmDiscoverySnapshotStore,
) : RealmPresentationSearchSource {
    private val subscriptions = ConcurrentHashMap<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        val validation = validate(request)
        if (validation != null) return validation

        subscriptions.remove(request.subscriptionId)?.cancel()
        val job =
            scope.launch(start = CoroutineStart.LAZY) {
                val values = mutableListOf<skirout.editor.v1.type_catalog.TypedValue>()
                try {
                    val provider = capabilities.requireSearch(CapabilityId(request.capabilityId.value))
                    val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
                    provider
                        .invoke(
                            SearchContext(request.subscriptionId),
                            prototypes,
                            payload,
                            request.query.toDomain(),
                        ).updates
                        .collect { update ->
                            when (update) {
                                is RealmSearchUpdate.Partial -> {
                                    values += update.values.map { SkirDataValueCodec.encode(it).getOrThrow() }
                                    updates.publish(
                                        searchSnapshot(
                                            request.subscriptionId,
                                            RealmPresentationSearchStatus.LOADING,
                                            values,
                                            update.guidance,
                                        ),
                                    )
                                }

                                RealmSearchUpdate.Complete -> {
                                    updates.publish(
                                        searchSnapshot(
                                            request.subscriptionId,
                                            RealmPresentationSearchStatus.READY,
                                            values,
                                        ),
                                    )
                                }
                            }
                        }
                } catch (failure: CancellationException) {
                    throw failure
                } catch (failure: Throwable) {
                    updates.publish(
                        unavailableRealmPresentationSearchUpdate(
                            request.subscriptionId,
                            failure.message ?: "Realm presentation search failed",
                        ),
                    )
                } finally {
                    subscriptions.remove(request.subscriptionId, coroutineContext[Job])
                }
            }
        subscriptions[request.subscriptionId] = job
        job.start()

        return searchSnapshot(
            request.subscriptionId,
            RealmPresentationSearchStatus.LOADING,
            emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean = subscriptions.remove(subscriptionId)?.let {
        it.cancel()
        true
    } ?: false

    private fun validate(request: RealmPresentationSearchRequest): RealmPresentationSearchUpdate? {
        val current = snapshots.current()
            ?: return unavailableRealmPresentationSearchUpdate(request.subscriptionId, "Realm catalog is unavailable")
        if (request.generation.value != current.discovery.generation.value) {
            return searchError(request.subscriptionId, "Realm catalog generation is stale")
        }
        val descriptor = current.capabilities
            .filterIsInstance<RealmCapabilityDescriptor.Search>()
            .singleOrNull { it.id.value == request.capabilityId.value }
            ?: return searchError(request.subscriptionId, "Realm search capability is unavailable")
        val resultType =
            when (val decoded = SkirTypeCodec.decode(request.resultType)) {
                is SkirConversionResult.Success -> decoded.value
                is SkirConversionResult.Failure ->
                    return searchError(request.subscriptionId, "Realm search result type is invalid")
            }
        if (resultType != TypeExpression.Named(descriptor.resultType)) {
            return searchError(request.subscriptionId, "Realm search result type does not match its capability")
        }
        return null
    }
}

private data class SearchContext(
    override val invocationId: String,
) : RealmSearchContext

private fun skirout.editor.v1.search.RealmSearchQuery.toDomain(): RealmSearchQuery =
    RealmSearchQuery(
        normalizedQuery = normalizedQuery,
        selectors = selectors.map { RealmSearchSelector(it.selectorId, it.key, it.value) },
        selectorExpression = selectorExpression?.toDomain(),
    )

private fun WireSelectorExpression.toDomain(): RealmSearchSelectorExpression =
    when (this) {
        is WireSelectorExpression.SelectorWrapper -> RealmSearchSelectorExpression.Selector(value.selectorId)
        is WireSelectorExpression.BinaryWrapper -> {
            when (value.operator_) {
                skirout.editor.v1.search.RealmSearchSelectorOperator.AND ->
                    RealmSearchSelectorExpression.And(value.left.toDomain(), value.right.toDomain())
                skirout.editor.v1.search.RealmSearchSelectorOperator.OR ->
                    RealmSearchSelectorExpression.Or(value.left.toDomain(), value.right.toDomain())
                else -> error("Unknown Realm search selector operator")
            }
        }
        is WireSelectorExpression.NotWrapper -> RealmSearchSelectorExpression.Not(value.expression.toDomain())
        else -> error("Unknown Realm search selector expression")
    }

private fun searchSnapshot(
    subscriptionId: String,
    status: RealmPresentationSearchStatus,
    values: List<skirout.editor.v1.type_catalog.TypedValue>,
    guidance: List<String> = emptyList(),
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createSnapshot(
        subscriptionId = subscriptionId,
        status = status,
        values = values,
        guidance = guidance,
        diagnostics = emptyList(),
    )

private fun searchError(
    subscriptionId: String,
    message: String,
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createSnapshot(
        subscriptionId = subscriptionId,
        status = RealmPresentationSearchStatus.ERROR,
        values = emptyList(),
        guidance = emptyList(),
        diagnostics = listOf(realmPresentationSearchDiagnostic(DiagnosticCode.INVALID_VALUE, message)),
    )

internal fun unavailableRealmPresentationSearchUpdate(
    subscriptionId: String,
    message: String = "Realm presentation search source is unavailable",
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createUnavailable(
        subscriptionId = subscriptionId,
        diagnostics = listOf(realmPresentationSearchDiagnostic(DiagnosticCode.INVALID_PRESENTATION, message)),
    )

internal fun realmPresentationSearchDiagnostic(
    code: DiagnosticCode,
    message: String,
): TypeDiagnostic =
    TypeDiagnostic(
        code = code,
        severity = DiagnosticSeverity.ERROR,
        message = message,
        path = null,
        relatedType = null,
        details = emptyList(),
    )
