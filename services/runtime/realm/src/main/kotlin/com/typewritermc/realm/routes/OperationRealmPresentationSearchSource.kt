package com.typewritermc.realm.routes

import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.PAGE_CONTRACT_TYPE
import com.typewritermc.operations.BoundResourceOperation
import com.typewritermc.operations.BuiltinResourceOperation
import com.typewritermc.operations.LinkWithInput
import com.typewritermc.operations.MoveToBookInput
import com.typewritermc.operations.MoveToPageInput
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationResourceOption
import com.typewritermc.operations.OperationSearch
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.OperationPreparationResult
import com.typewritermc.realm.authoring.ResourceOperationRuntime
import com.typewritermc.realm.authoring.StaleOperationObservation
import com.typewritermc.realm.authoring.operationObservation
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.DataValue
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.toTemplate
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Job
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.launch
import skirout.editor.v1.search.RealmPresentationSearchRequest
import skirout.editor.v1.search.RealmPresentationSearchStatus
import skirout.editor.v1.search.RealmPresentationSearchUpdate
import java.util.concurrent.ConcurrentHashMap

/** Searches through the same pure preparation used by menus and drops. */
internal class OperationRealmPresentationSearchSource(
    private val scope: CoroutineScope,
    private val views: AuthoringViewStore,
) : RealmPresentationSearchSource {
    private val jobs = ConcurrentHashMap<String, Job>()
    private val operations = ResourceOperationRuntime(views)

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
        val operation: BoundResourceOperation
        val resultBinding: NativeBinding<OperationResourceOption>
        try {
            require(request.subscriptionId.isNotBlank() && context.inputRevision >= 0)
            require(request.generation == context.invocation.catalog && request.generation.value == lease.root.catalog.generation.value) {
                "The operation search catalog changed."
            }
            captured = context.context.decodeWorkingContext()
            invocation = context.invocation.decodeInvocation()
            baseline = lease.operationObservation(captured.confirmed, captured.upserts, captured.removals)
            val descriptor = OperationSearch.descriptors.single { it.id.value == request.capabilityId.value }
            require(SkirTypeCodec.decode(request.resultType).getOrThrow() == descriptor.resultType.toTemplate()) {
                "The operation search result type is invalid."
            }
            require(
                SkirDataValueCodec.decode(request.payload).getOrThrow() is DataValue.StringValue,
            ) { "The operation search payload is invalid." }
            val builtin =
                when (request.capabilityId.value) {
                    OperationSearch.compatibleBooks.id.value -> BuiltinResourceOperation.MoveToBook
                    OperationSearch.compatiblePages.id.value -> BuiltinResourceOperation.MoveToPage
                    else -> BuiltinResourceOperation.LinkWith
                }
            operation = baseline.catalog.operations.requireAuthoring(builtin.id.capability)
            val checked = (baseline.catalog.checked.resolve(descriptor.resultType) as Resolution.Ready).value
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
                    val candidates =
                        baseline.resources.entries
                            .asSequence()
                            .filter { (_, record) ->
                                val configured = record.configuration as? TypeSelection.Complete ?: return@filter false
                                when (request.capabilityId.value) {
                                    OperationSearch.compatibleBooks.id.value -> {
                                        baseline.catalog.checked.isNominalSubtype(
                                            configured.use.definition,
                                            BookDefinition.id,
                                        )
                                    }

                                    OperationSearch.compatiblePages.id.value -> {
                                        baseline.catalog.checked.isNominalSubtype(
                                            configured.use.definition,
                                            PAGE_CONTRACT_TYPE,
                                        )
                                    }

                                    else -> {
                                        true
                                    }
                                }
                            }.map { (id, record) ->
                                OperationResourceOption(id, record.displayLabel ?: "Unnamed resource")
                            }.filter { query.isEmpty() || query in it.label.lowercase() }
                            .sortedWith(
                                compareBy({ it.label.lowercase() }, { it.id.value }),
                            ).toList()
                    val values = mutableListOf<skirout.editor.v1.type_catalog.DataValue>()
                    for (candidate in candidates) {
                        coroutineContext.ensureActive()
                        val input: Any =
                            when (request.capabilityId.value) {
                                OperationSearch.compatibleBooks.id.value -> MoveToBookInput(candidate.id)
                                OperationSearch.compatiblePages.id.value -> MoveToPageInput(candidate.id)
                                else -> LinkWithInput(candidate.id)
                            }
                        val binding = requireNotNull(operation.input.binding)
                        require(binding.nativeClass == input::class)
                        @Suppress("UNCHECKED_CAST")
                        val payload = (binding as NativeBinding<Any>).encode(input)
                        val result =
                            operations.prepare(
                                invocation,
                                CatalogGeneration(request.generation.value),
                                operation.capability.id,
                                captured.confirmed,
                                captured.upserts,
                                captured.removals,
                                payload,
                                PreparationChoices(),
                            )
                        if (result is OperationPreparationResult.Preview || result is OperationPreparationResult.NeedsInput) {
                            values += SkirDataValueCodec.encode(resultBinding.encode(candidate)).getOrThrow()
                            if (values.size == MAX_RESULTS) break
                        }
                    }
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
                                    if (values.size ==
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
) = RealmPresentationSearchUpdate.createStaleObservation(
    subscriptionId = subscriptionId,
    observation =
        skirout.editor.v1.resource_operations.StaleAuthoringObservation(
            actual =
                skirout.editor.v1.authoring
                    .AuthoringObservationId(value = actual),
        ),
)

private const val MAX_RESULTS = 100
