package com.typewritermc.realm.routes

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.realm.catalog.RealmCatalogLease
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
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
    private val catalogs: RealmCatalogStore,
) : RealmPresentationSearchSource {
    private val subscriptions = ConcurrentHashMap<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        val catalog =
            runCatching { catalogs.captureCurrent() }.getOrNull()
                ?: return unavailableRealmPresentationSearchUpdate(request.subscriptionId, "Realm catalog is unavailable")
        validate(request, catalog)?.let { failure ->
            catalog.close()
            return failure
        }

        subscriptions.remove(request.subscriptionId)?.cancel()
        val job =
            scope.launch(start = CoroutineStart.LAZY) {
                val values = mutableListOf<skirout.editor.v1.type_catalog.DataValue>()
                try {
                    val registry = RealmCapabilityRegistry(catalog.capabilities)
                    val provider = registry.requireSearch(CapabilityId(request.capabilityId.value))
                    val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
                    provider
                        .invoke(
                            SearchContext(request.subscriptionId),
                            RealmCapabilityRuntime(catalog.checked, catalog.nativeBindings),
                            payload,
                            request.query.toDomain(),
                        ).updates
                        .collect { update ->
                            when (update) {
                                is RealmSearchUpdate.Partial -> {
                                    values += update.values.map { value -> SkirDataValueCodec.encode(value).getOrThrow() }
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
                    catalog.close()
                    subscriptions.remove(request.subscriptionId, coroutineContext[Job])
                }
            }
        subscriptions[request.subscriptionId] = job
        job.start()
        return searchSnapshot(request.subscriptionId, RealmPresentationSearchStatus.LOADING, emptyList())
    }

    override fun cancel(subscriptionId: String): Boolean =
        subscriptions.remove(subscriptionId)?.let { job ->
            job.cancel()
            true
        } ?: false

    private fun validate(
        request: RealmPresentationSearchRequest,
        catalog: RealmCatalogLease,
    ): RealmPresentationSearchUpdate? {
        if (request.generation.value != catalog.generation.value) {
            return searchError(request.subscriptionId, "Realm catalog generation is stale")
        }
        val descriptor =
            RealmCapabilityRegistry(catalog.capabilities)
                .descriptors
                .filterIsInstance<RealmCapabilityDescriptor.Search>()
                .singleOrNull { it.id.value == request.capabilityId.value }
                ?: return searchError(request.subscriptionId, "Realm search capability is unavailable")
        val resultType =
            when (val decoded = SkirTypeCodec.decode(request.resultType)) {
                is SkirConversionResult.Success -> {
                    decoded.value
                }

                is SkirConversionResult.Failure -> {
                    return searchError(request.subscriptionId, "Realm search result type is invalid")
                }
            }
        if (resultType != descriptor.resultType.toTemplate()) {
            return searchError(request.subscriptionId, "Realm search result type does not match its capability")
        }
        return null
    }
}

private data class SearchContext(
    override val invocationId: String,
) : RealmSearchContext

private fun searchSnapshot(
    subscriptionId: String,
    status: RealmPresentationSearchStatus,
    values: List<skirout.editor.v1.type_catalog.DataValue>,
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
        diagnostics = listOf(realmDiagnostic(message)),
    )

internal fun unavailableRealmPresentationSearchUpdate(
    subscriptionId: String,
    message: String = "Realm presentation search source is unavailable",
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createUnavailable(
        subscriptionId = subscriptionId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun TypeUse.toTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map { it.toTemplate() })
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.toTemplate())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }
