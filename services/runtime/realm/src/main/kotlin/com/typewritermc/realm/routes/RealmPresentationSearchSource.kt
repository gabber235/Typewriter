package com.typewritermc.realm.routes

import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmSearchContext
import com.typewritermc.capability.RealmSearchUpdate
import com.typewritermc.capability.ResourceOperationSearchContext
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.realm.authoring.AuthoredReadView
import com.typewritermc.realm.authoring.AuthoringLease
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.realm.catalog.RealmCatalogLease
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.realm.operation.StaleOperationObservation
import com.typewritermc.realm.operation.operationObservation
import com.typewritermc.types.isValid
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.toSkir
import com.typewritermc.types.toTemplate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.launch
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.DataValue
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

/**
 * Owns active presentation search jobs and their retained provider catalogs.
 *
 * Reusing a subscription identity cancels its previous job. Provider partial batches accumulate into complete
 * snapshots, and explicit completion marks them ready. Operation searches also retain the caller working
 * baseline and check its saved observation before publishing updates. Explicit cancellation and the supplied
 * scope bound lifetime; the unary startup response does not own the continuing search job.
 */
class CapabilityRealmPresentationSearchSource(
    private val scope: CoroutineScope,
    private val catalogs: RealmCatalogStore,
    private val views: AuthoringViewStore,
    private val operationSearch: RealmPresentationSearchSource = OperationRealmPresentationSearchSource(scope, views),
) : RealmPresentationSearchSource {
    private val subscriptions = ConcurrentHashMap<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        cancel(request.subscriptionId)
        val capability = request.capabilityId
        if (views.read { it.catalog.operations.candidateSearch(capability) != null }) {
            return operationSearch.watch(request, updates)
        }
        val catalog =
            catalogs.captureCurrentOrNull()
                ?: return unavailableRealmPresentationSearchUpdate(request.subscriptionId, "Realm catalog is unavailable")
        validate(request, catalog)?.let { failure ->
            catalog.close()
            return failure
        }
        val operation =
            try {
                captureOperation(request)
            } catch (stale: StaleOperationObservation) {
                catalog.close()
                return staleSearch(request.subscriptionId, stale.actual)
            } catch (failure: Exception) {
                catalog.close()
                return unavailableRealmPresentationSearchUpdate(
                    request.subscriptionId,
                    failure.message ?: "Operation search context is invalid",
                )
            }

        val job =
            scope.launch(start = CoroutineStart.LAZY) {
                val values = mutableListOf<DataValue>()
                try {
                    val registry = RealmCapabilityRegistry(catalog.capabilities)
                    val provider = registry.requireSearch(capability)
                    val payload = request.payload.requirePortable()
                    provider
                        .invoke(
                            SearchContext(request.subscriptionId, operation?.context),
                            RealmCapabilityRuntime(catalog.checked, catalog.nativeBindings),
                            payload,
                            request.query,
                        ).updates
                        .collect { update ->
                            operation?.requireCurrent()
                            when (update) {
                                is RealmSearchUpdate.Partial -> {
                                    values += update.values.map { value -> value.requirePortable() }
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
                } catch (stale: StaleOperationObservation) {
                    updates.publish(staleSearch(request.subscriptionId, stale.actual))
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
                    operation?.lease?.close()
                    subscriptions.remove(request.subscriptionId, coroutineContext[Job])
                }
            }
        subscriptions[request.subscriptionId] = job
        job.invokeOnCompletion {
            catalog.close()
            operation?.lease?.close()
        }
        job.start()
        return searchSnapshot(request.subscriptionId, RealmPresentationSearchStatus.LOADING, emptyList())
    }

    override fun cancel(subscriptionId: String): Boolean {
        val ordinary =
            subscriptions.remove(subscriptionId)?.let { job ->
                job.cancel()
                true
            } ?: false
        val operation = operationSearch.cancel(subscriptionId)
        return ordinary || operation
    }

    private fun captureOperation(request: RealmPresentationSearchRequest): CapturedOperationSearch? {
        val context = request.operationContext ?: return null
        val lease = views.capture()
        try {
            require(
                context.inputRevision >= 0 && request.generation == context.invocation.catalog &&
                    request.generation.value == lease.root.catalog.generation.value,
            )
            val invocation = context.invocation.decodeInvocation()
            val captured = context.context.decodeWorkingContext()
            val baseline = lease.operationObservation(captured.confirmed, captured.upserts, captured.removals)
            require(invocation.targets.all { it.toSkir() in baseline.resources }) { "The operation search selection changed." }
            require(invocation.origin.occurrences.all { baseline.links[it.id] == it }) { "The operation search origin changed." }
            return CapturedOperationSearch(
                lease,
                invocation,
                CapturedAuthoringReads(AuthoredReadView.Original(baseline)),
                captured.confirmed,
                views,
            )
        } catch (failure: Throwable) {
            lease.close()
            throw failure
        }
    }

    private fun validate(
        request: RealmPresentationSearchRequest,
        catalog: RealmCatalogLease,
    ): RealmPresentationSearchUpdate? {
        if (request.generation.value != catalog.generation.value) {
            return searchError(request.subscriptionId, "Realm catalog generation is stale")
        }
        val descriptor =
            RealmCapabilityRegistry(catalog.capabilities)
                .definitions
                .filterIsInstance<CapabilityDefinition.SearchWrapper>()
                .map { it.value }
                .singleOrNull { it.capabilityId == request.capabilityId }
                ?: return searchError(request.subscriptionId, "Realm search capability is unavailable")
        val resultType =
            request.resultType.takeIf { it.isValid }
                ?: return searchError(request.subscriptionId, "Realm search result type is invalid")
        if (resultType != descriptor.resultType.toTemplate()) {
            return searchError(request.subscriptionId, "Realm search result type does not match its capability")
        }
        return null
    }
}

private data class SearchContext(
    override val invocationId: String,
    override val operationContext: ResourceOperationSearchContext? = null,
) : RealmSearchContext

private data class CapturedOperationSearch(
    val lease: AuthoringLease,
    val invocation: OperationInvocation,
    val reads: CapturedAuthoringReads,
    val observation: String,
    val views: AuthoringViewStore,
) {
    val context get() = ResourceOperationSearchContext(invocation, reads)

    fun requireCurrent() {
        val health = reads.health()
        check(health.failures.isEmpty() && health.incomplete.isEmpty()) { "Operation search reads did not produce complete evidence" }
        val actual = views.read { it.observationId }
        if (actual != observation) throw StaleOperationObservation(actual)
    }
}

private fun searchSnapshot(
    subscriptionId: String,
    status: RealmPresentationSearchStatus,
    values: List<DataValue>,
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
        status = RealmPresentationSearchStatus.SEARCH_FAILED_ERROR,
        values = emptyList(),
        guidance = emptyList(),
        diagnostics = listOf(realmDiagnostic(message)),
    )

internal fun unavailableRealmPresentationSearchUpdate(
    subscriptionId: String,
    message: String = "Realm presentation search source is unavailable",
): RealmPresentationSearchUpdate =
    RealmPresentationSearchUpdate.createUnavailableError(
        subscriptionId = subscriptionId,
        diagnostics = listOf(realmDiagnostic(message)),
    )
