package com.typewritermc.realm.routes

import com.typewritermc.authoring.text
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.choiceId
import com.typewritermc.operations.requireValid
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringActionPrepare
import com.typewritermc.protocol.transport.generated.resourceDropCandidatesResolve
import com.typewritermc.protocol.transport.generated.resourceOperationsResolve
import com.typewritermc.realm.operation.OperationCatalogChanged
import com.typewritermc.realm.operation.OperationPreparationResult
import com.typewritermc.realm.operation.OperationResolutionFailure
import com.typewritermc.realm.operation.ResourceOperationRuntime
import com.typewritermc.realm.operation.StaleOperationObservation
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.requirePortable
import com.typewritermc.types.requireValid
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toResourceIds
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInputProblem
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveDropCandidatesRequest
import skirout.editor.v1.resource_operations.ResolveDropCandidatesResult
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId
import skirout.editor.v1.resource_operations.OperationInvocation as SkirOperationInvocation

/**
 * Adapts operation requests on generated Realm routes into validated working observations.
 *
 * Broker grants govern route access. This adapter validates caller supplied overlay and choice identities,
 * while the runtime verifies catalog, saved observation, availability, and origin before preparing a preview.
 * Input revisions are echoed for client response ordering and do not authorize saved state writes.
 */
internal class ResourceOperationRoutes(
    private val runtime: ResourceOperationRuntime,
    private val address: RealmRouteScope,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(address.resourceOperationsResolve) { call -> resolve(call.request) }
            unary(address.resourceDropCandidatesResolve) { call -> resolveDropCandidates(call.request) }
            unary(address.authoringActionPrepare) { call -> prepare(call.request) }
        }

    internal fun resolve(request: ResolveResourceOperationsRequest): ResolveResourceOperationsResult =
        try {
            val context = request.context.decodeWorkingContext()
            val resolved =
                runtime.resolve(
                    request.invocation.decodeInvocation(),
                    request.invocation.catalog,
                    context.confirmed,
                    context.upserts,
                    context.removals,
                )
            ResolveResourceOperationsResult.ResolvedWrapper(resolved)
        } catch (stale: StaleOperationObservation) {
            ResolveResourceOperationsResult.createStaleObservationError(actual = AuthoringObservationId(value = stale.actual))
        } catch (stale: OperationCatalogChanged) {
            ResolveResourceOperationsResult.createCatalogChangedError(
                actualGeneration =
                    stale.actual,
            )
        } catch (denied: RealmCapabilityPermissionDeniedException) {
            ResolveResourceOperationsResult.createPermissionDeniedError(
                diagnostics =
                    listOf(
                        operationDiagnostic(
                            "permission_denied",
                            denied.message ?: "Permission denied",
                        ),
                    ),
            )
        } catch (failed: OperationResolutionFailure) {
            if (failed.cause is RealmCapabilityPermissionDeniedException) {
                ResolveResourceOperationsResult.createPermissionDeniedError(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "permission_denied",
                                failed.cause?.message ?: "Permission denied",
                            ),
                        ),
                )
            } else {
                ResolveResourceOperationsResult.createFailedError(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "resolution_failed",
                                failed.message ?: "Operation availability failed",
                            ),
                        ),
                )
            }
        } catch (invalid: IllegalArgumentException) {
            invalid.rethrowExceptional()
            ResolveResourceOperationsResult.createInvalidError(
                diagnostics =
                    listOf(
                        operationDiagnostic(
                            "invalid_operation_context",
                            invalid.message ?: "The operation context is invalid",
                        ),
                    ),
            )
        }

    internal fun resolveDropCandidates(request: ResolveDropCandidatesRequest): ResolveDropCandidatesResult =
        try {
            val context = request.context.decodeWorkingContext()
            val candidates =
                runtime.resolveDropCandidates(
                    request.invocation.decodeInvocation(),
                    request.invocation.catalog,
                    context.confirmed,
                    context.upserts,
                    context.removals,
                )
            ResolveDropCandidatesResult.ResolvedWrapper(candidates)
        } catch (stale: StaleOperationObservation) {
            ResolveDropCandidatesResult.createStaleObservationError(actual = AuthoringObservationId(value = stale.actual))
        } catch (stale: OperationCatalogChanged) {
            ResolveDropCandidatesResult.createCatalogChangedError(actualGeneration = stale.actual)
        } catch (denied: RealmCapabilityPermissionDeniedException) {
            ResolveDropCandidatesResult.createPermissionDeniedError(
                diagnostics = listOf(operationDiagnostic("permission_denied", denied.message ?: "Permission denied")),
            )
        } catch (failed: OperationResolutionFailure) {
            if (failed.cause is RealmCapabilityPermissionDeniedException) {
                ResolveDropCandidatesResult.createPermissionDeniedError(
                    diagnostics = listOf(operationDiagnostic("permission_denied", failed.cause?.message ?: "Permission denied")),
                )
            } else {
                ResolveDropCandidatesResult.createFailedError(
                    diagnostics = listOf(operationDiagnostic("resolution_failed", failed.message ?: "Drop candidates failed")),
                )
            }
        } catch (invalid: IllegalArgumentException) {
            invalid.rethrowExceptional()
            ResolveDropCandidatesResult.createInvalidError(
                diagnostics =
                    listOf(operationDiagnostic("invalid_operation_context", invalid.message ?: "The operation context is invalid")),
            )
        }

    internal suspend fun prepare(request: PrepareAuthoringActionRequest): AuthoringActionResult =
        try {
            require(request.inputRevision >= 0) { "The operation input revision is invalid." }
            require(request.capability.value.isNotBlank()) { "The authoring capability is required." }
            val context = request.context.decodeWorkingContext()
            val choices = request.choices.map { it.requireValid() }
            require(choices.map { it.choiceId }.distinct().size == choices.size) { "Operation choices require unique identities." }
            when (
                val result =
                    runtime.prepare(
                        request.invocation.decodeInvocation(),
                        request.invocation.catalog,
                        request.capability,
                        context.confirmed,
                        context.upserts,
                        context.removals,
                        request.input?.let {
                            it.requirePortable()
                        },
                        PreparationChoices(choices),
                    )
            ) {
                is OperationPreparationResult.Preview -> {
                    AuthoringActionResult.createPreview(
                        invocationId = request.invocation.invocationId,
                        inputRevision = request.inputRevision,
                        edit = result.edit,
                        confirmation = result.confirmation,
                        selection =
                            result.selection?.let(OperationSelectionEffect::ReplaceWrapper)
                                ?: OperationSelectionEffect.UNCHANGED,
                    )
                }

                is OperationPreparationResult.NeedsInput -> {
                    AuthoringActionResult.createNeedsInput(
                        invocationId = request.invocation.invocationId,
                        inputRevision = request.inputRevision,
                        normalizedInput = result.input?.requirePortable(),
                        problems =
                            result.missing.map {
                                OperationInputProblem(
                                    path = it,
                                    code = "required",
                                    message = "Complete this input",
                                )
                            },
                        choices = result.choices,
                    )
                }

                is OperationPreparationResult.Invalid -> {
                    AuthoringActionResult.createInvalidError(
                        diagnostics =
                            result.problems.map {
                                operationDiagnostic(it.code, it.code.replace('_', ' '), it.location)
                            },
                    )
                }

                is OperationPreparationResult.Unavailable -> {
                    AuthoringActionResult.createUnavailableError(
                        diagnostics = listOf(operationDiagnostic("operation_unavailable", result.reason)),
                    )
                }

                is OperationPreparationResult.Failed -> {
                    if (result.cause is RealmCapabilityPermissionDeniedException) {
                        AuthoringActionResult.createPermissionDeniedError(
                            diagnostics =
                                listOf(
                                    operationDiagnostic(
                                        "permission_denied",
                                        result.cause.message ?: "Permission denied",
                                    ),
                                ),
                        )
                    } else {
                        AuthoringActionResult.createFailedError(
                            diagnostics =
                                listOf(
                                    operationDiagnostic(
                                        "preparation_failed",
                                        result.cause.message ?: "Operation preparation failed",
                                    ),
                                ),
                        )
                    }
                }
            }
        } catch (stale: StaleOperationObservation) {
            AuthoringActionResult.createStaleObservationError(actual = AuthoringObservationId(value = stale.actual))
        } catch (stale: OperationCatalogChanged) {
            AuthoringActionResult.createCatalogChangedError(
                actualGeneration =
                    stale.actual,
            )
        } catch (failed: OperationResolutionFailure) {
            if (failed.cause is RealmCapabilityPermissionDeniedException) {
                AuthoringActionResult.createPermissionDeniedError(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "permission_denied",
                                failed.cause?.message ?: "Permission denied",
                            ),
                        ),
                )
            } else {
                AuthoringActionResult.createFailedError(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "resolution_failed",
                                failed.message ?: "Operation availability failed",
                            ),
                        ),
                )
            }
        } catch (invalid: IllegalArgumentException) {
            invalid.rethrowExceptional()
            AuthoringActionResult.createInvalidError(
                diagnostics =
                    listOf(
                        operationDiagnostic(
                            "invalid_operation_context",
                            invalid.message ?: "The operation context is invalid",
                        ),
                    ),
            )
        }
}

internal data class DecodedOperationContext(
    val confirmed: String,
    val upserts: Map<ResourceId, AuthoringRecord>,
    val removals: Set<ResourceId>,
)

internal fun OperationWorkingContext.decodeWorkingContext(): DecodedOperationContext {
    require(confirmedObservation.value.isNotBlank()) { "The saved authoring observation is required." }
    val upserts = overlay.upserts.map { it.resource.requireValid() to it.content.requireValid() }
    val removals = overlay.removals.map { it.requireValid() }
    require(
        upserts
            .map {
                it.first
            }.distinct()
            .size == upserts.size && removals.distinct().size == removals.size,
    ) { "An operation overlay contains duplicate identities." }
    return DecodedOperationContext(confirmedObservation.value, upserts.toMap(), removals.toSet())
}

internal fun SkirOperationInvocation.decodeInvocation(): OperationInvocation {
    require(catalog.value.isNotBlank()) { "The catalog generation is required." }
    return OperationInvocation(
        invocationId.value,
        targets.toResourceIds(),
        OperationOrigin(origin.container?.toResourceId(), origin.occurrences.map { it.requireValid() }),
    )
}

private fun operationDiagnostic(
    code: String,
    message: String,
    location: ValueLocation? = null,
) = AuthoringDiagnostic(
    code = code,
    message = message,
    resource = location?.resource,
    path = location?.path,
)
