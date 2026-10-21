package com.typewritermc.realm.routes

import com.typewritermc.operations.CandidateSearch
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationResourceOption
import com.typewritermc.realm.authoring.AuthoredReadView
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.RealmOperationReads
import com.typewritermc.realm.authoring.StaleOperationObservation
import com.typewritermc.realm.authoring.applicableIn
import com.typewritermc.realm.authoring.guarded
import com.typewritermc.realm.authoring.operationObservation
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toTemplate
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.resource_operations.StaleAuthoringObservation
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.DataValue
import java.util.concurrent.ConcurrentHashMap

/**
 * Searches the declared candidates of one operation input field, the source of the search input generated forms show
 * for resource identity fields. Results are filtered by the declared accepts check and the query, never by dry runs of
 * the operation's preparation, and capped at [MAX_RESULTS].
 */
internal class OperationRealmPresentationSearchSource(
    private val scope: CoroutineScope,
    private val views: AuthoringViewStore,
) : RealmPresentationSearchSource {
    private val jobs = ConcurrentHashMap<String, Job>()

    override suspend fun watch(
        request: RealmPresentationSearchRequest,
        updates: RealmPresentationSearchUpdatePublisher,
    ): RealmPresentationSearchUpdate {
        jobs.remove(request.subscriptionId)?.cancel()
        val lease = views.capture()
        val context =
            request.operationContext ?: run {
                lease.close()
                return unavailableRealmPresentationSearchUpdate(request.subscriptionId, "This search requires an operation selection")
            }
        val baseline: AuthoringView
        val captured: DecodedOperationContext
        val invocation: OperationInvocation
        val search: CandidateSearch
        val resultBinding: NativeBinding<OperationResourceOption>
        try {
            require(request.subscriptionId.isNotBlank() && context.inputRevision >= 0)
            require(request.generation == context.invocation.catalog && request.generation.value == lease.root.catalog.generation.value) {
                "The operation search catalog changed."
            }
            captured = context.context.decodeWorkingContext()
            invocation = context.invocation.decodeInvocation()
            baseline = lease.operationObservation(captured.confirmed, captured.upserts, captured.removals)
            search =
                requireNotNull(baseline.catalog.operations.candidateSearch(request.capabilityId)) {
                    "The operation search is unavailable."
                }
            require(request.resultType.requireValid() == search.descriptor.resultType.toTemplate()) {
                "The operation search result type is invalid."
            }
            require(
                request.payload.requirePortable() is DataValue.StringValueWrapper,
            ) { "The operation search payload is invalid." }
            require(search.operation in invocation.applicableIn(baseline, CapturedAuthoringReads(AuthoredReadView.Original(baseline)))) {
                "The operation does not apply to the search selection."
            }
            val checked = (baseline.catalog.checked.resolve(search.descriptor.resultType) as Resolution.Ready).value
            val binding = baseline.catalog.nativeBindings.bind(checked)
            require(binding.nativeClass == OperationResourceOption::class)
            @Suppress("UNCHECKED_CAST")
            resultBinding = binding as NativeBinding<OperationResourceOption>
        } catch (stale: StaleOperationObservation) {
            lease.close()
            return staleSearch(request.subscriptionId, stale.actual)
        } catch (failure: Exception) {
            lease.close()
            return unavailableRealmPresentationSearchUpdate(
                request.subscriptionId,
                failure.message ?: "The operation search is unavailable",
            )
        }
        val job =
            scope.launch(start = CoroutineStart.LAZY) {
                try {
                    val query =
                        request.query.normalizedQuery
                            .trim()
                            .lowercase()
                    val reads = CapturedAuthoringReads(AuthoredReadView.Original(baseline))
                    val active = coroutineContext
                    val options =
                        search.operation
                            .guarded(reads) {
                                search.field
                                    .acceptedCandidates(invocation.targets, RealmOperationReads(reads))
                                    .filterIsInstance<ResourceId>()
                                    .mapNotNull { id ->
                                        active.ensureActive()
                                        val record = baseline.resources[id] ?: return@mapNotNull null
                                        val label = with(reads) { baseline.catalog.displays.label(record, baseline.catalog.checked) }
                                        OperationResourceOption(id, label ?: "Unnamed resource")
                                    }.filter { query.isEmpty() || query in it.label.lowercase() }
                                    .take(MAX_RESULTS + 1)
                                    .toList()
                            }
                    val values =
                        options
                            .take(MAX_RESULTS)
                            .sortedWith(compareBy({ it.label.lowercase() }, { it.id.value }))
                            .map { resultBinding.encode(it).requirePortable() }
                    val actual = views.read { it.observationId }
                    if (actual != captured.confirmed) {
                        updates.publish(staleSearch(request.subscriptionId, actual))
                    } else {
                        updates.publish(
                            RealmPresentationSearchUpdate.createSnapshot(
                                subscriptionId = request.subscriptionId,
                                status = RealmPresentationSearchStatus.READY,
                                values = values,
                                guidance =
                                    if (options.size >
                                        MAX_RESULTS
                                    ) {
                                        listOf("Refine your search to see more resources")
                                    } else {
                                        emptyList()
                                    },
                                diagnostics = emptyList(),
                            ),
                        )
                    }
                } catch (stale: StaleOperationObservation) {
                    updates.publish(staleSearch(request.subscriptionId, stale.actual))
                } catch (failure: Exception) {
                    failure.rethrowExceptional()
                    updates.publish(
                        unavailableRealmPresentationSearchUpdate(
                            request.subscriptionId,
                            failure.message ?: "Operation search failed",
                        ),
                    )
                } finally {
                    lease.close()
                    jobs.remove(request.subscriptionId, coroutineContext[Job])
                }
            }
        jobs[request.subscriptionId] = job
        job.invokeOnCompletion { lease.close() }
        job.start()
        return RealmPresentationSearchUpdate.createSnapshot(
            subscriptionId = request.subscriptionId,
            status = RealmPresentationSearchStatus.LOADING,
            values = emptyList(),
            guidance = emptyList(),
            diagnostics = emptyList(),
        )
    }

    override fun cancel(subscriptionId: String): Boolean =
        jobs.remove(subscriptionId)?.let {
            it.cancel()
            true
        } ?: false
}

internal fun staleSearch(
    subscriptionId: String,
    actual: String,
) = RealmPresentationSearchUpdate.createStaleObservationError(
    subscriptionId = subscriptionId,
    observation =
        StaleAuthoringObservation(
            actual =
                AuthoringObservationId(value = actual),
        ),
)

private const val MAX_RESULTS = 100
