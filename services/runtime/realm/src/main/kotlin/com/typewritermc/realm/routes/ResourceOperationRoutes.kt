package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.PreparationChoice
import com.typewritermc.operations.PreparationChoiceAnswer
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.authoring.OperationCatalogChanged
import com.typewritermc.realm.authoring.OperationPreparationResult
import com.typewritermc.realm.authoring.OperationResolutionFailure
import com.typewritermc.realm.authoring.ResourceOperationRuntime
import com.typewritermc.realm.authoring.StaleOperationObservation
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.ResourceId
import com.typewritermc.types.skir.SkirAuthoringValueCodec
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirOperationCodec
import com.typewritermc.types.skir.getOrThrow
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.authoring.AuthoringDiagnostic
import skirout.editor.v1.authoring.AuthoringObservationId
import skirout.editor.v1.resource_operations.AuthoringActionResult
import skirout.editor.v1.resource_operations.OperationInputProblem
import skirout.editor.v1.resource_operations.OperationSelectionEffect
import skirout.editor.v1.resource_operations.OperationWorkingContext
import skirout.editor.v1.resource_operations.PreparationChoiceId
import skirout.editor.v1.resource_operations.PreparationCounterpartOption
import skirout.editor.v1.resource_operations.PreparationSourceOption
import skirout.editor.v1.resource_operations.PrepareAuthoringActionRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsRequest
import skirout.editor.v1.resource_operations.ResolveResourceOperationsResult
import skirout.editor.v1.authoring.CounterpartChoice as WireCounterpart
import skirout.editor.v1.resource_operations.PreparationChoice as WireChoice
import skirout.editor.v1.resource_operations.PreparationChoiceAnswer as WireAnswer

/**
 * Adapts operation requests on generated Realm routes into validated working observations.
 *
 * Broker grants govern route access. This adapter validates caller supplied overlay and choice identities,
 * while the runtime verifies catalog, saved observation, availability, and origin before preparing a preview.
 * Input revisions are echoed for client response ordering and do not authorize saved state writes.
 */
internal class ResourceOperationRoutes(
    private val runtime: ResourceOperationRuntime,
    private val contracts: EditorContracts,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.resolveResourceOperations) { call -> resolve(call.request) }
            unary(contracts.prepareAuthoringAction) { call -> prepare(call.request) }
        }

    internal fun resolve(request: ResolveResourceOperationsRequest): ResolveResourceOperationsResult =
        try {
            val context = request.context.decodeWorkingContext()
            val resolved =
                runtime.resolve(
                    request.invocation.decodeInvocation(),
                    CatalogGeneration(request.invocation.catalog.value),
                    context.confirmed,
                    context.upserts,
                    context.removals,
                )
            ResolveResourceOperationsResult.ResolvedWrapper(SkirOperationCodec.encode(resolved).getOrThrow())
        } catch (stale: StaleOperationObservation) {
            ResolveResourceOperationsResult.createStaleObservation(actual = AuthoringObservationId(value = stale.actual))
        } catch (stale: OperationCatalogChanged) {
            ResolveResourceOperationsResult.createCatalogChanged(
                actualGeneration =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = stale.actual.value),
            )
        } catch (denied: RealmCapabilityPermissionDeniedException) {
            ResolveResourceOperationsResult.createPermissionDenied(
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
                ResolveResourceOperationsResult.createPermissionDenied(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "permission_denied",
                                failed.cause?.message ?: "Permission denied",
                            ),
                        ),
                )
            } else {
                ResolveResourceOperationsResult.createFailed(
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
            ResolveResourceOperationsResult.createInvalid(
                diagnostics =
                    listOf(
                        operationDiagnostic(
                            "invalid_operation_context",
                            invalid.message ?: "The operation context is invalid",
                        ),
                    ),
            )
        }

    internal suspend fun prepare(request: PrepareAuthoringActionRequest): AuthoringActionResult =
        try {
            require(request.inputRevision >= 0) { "The operation input revision is invalid." }
            require(request.capability.value.isNotBlank()) { "The authoring capability is required." }
            val context = request.context.decodeWorkingContext()
            val choices =
                request.choices.map { answer ->
                    when (answer) {
                        is WireAnswer.SourceWrapper -> {
                            answer.value.choiceId.value to
                                PreparationChoiceAnswer.Source(SkirAuthoringValueCodec.decode(answer.value.occurrence).getOrThrow())
                        }

                        is WireAnswer.CounterpartWrapper -> {
                            answer.value.choiceId.value to
                                PreparationChoiceAnswer.Counterpart(answer.value.counterpart.decodeCounterpart())
                        }

                        else -> {
                            error("Unknown operation choice answer")
                        }
                    }
                }
            require(
                choices
                    .map {
                        it.first
                    }.distinct()
                    .size == choices.size && choices.all { it.first.isNotBlank() },
            ) { "Operation choices require unique identities." }
            when (
                val result =
                    runtime.prepare(
                        request.invocation.decodeInvocation(),
                        CatalogGeneration(request.invocation.catalog.value),
                        CapabilityId(request.capability.value),
                        context.confirmed,
                        context.upserts,
                        context.removals,
                        request.input?.let {
                            SkirDataValueCodec.decode(it).getOrThrow()
                        },
                        PreparationChoices(choices.toMap()),
                    )
            ) {
                is OperationPreparationResult.Preview -> {
                    AuthoringActionResult.createPreview(
                        invocationId = request.invocation.invocationId,
                        inputRevision = request.inputRevision,
                        edit = SkirAuthoringOperationCodec.encode(result.edit).getOrThrow(),
                        confirmation = result.confirmation?.let(SkirOperationCodec::encode),
                        selection =
                            result.selection?.let {
                                OperationSelectionEffect.ReplaceWrapper(
                                    it.map { id ->
                                        skirout.editor.v1.type_catalog
                                            .ResourceId(value = id.value)
                                    },
                                )
                            }
                                ?: OperationSelectionEffect.UNCHANGED,
                    )
                }

                is OperationPreparationResult.NeedsInput -> {
                    AuthoringActionResult.createNeedsInput(
                        invocationId = request.invocation.invocationId,
                        inputRevision = request.inputRevision,
                        normalizedInput = result.input?.let { SkirDataValueCodec.encode(it).getOrThrow() },
                        problems =
                            result.missing.map {
                                OperationInputProblem(
                                    path = SkirAuthoringValueCodec.encode(it.path).getOrThrow(),
                                    code = "required",
                                    message = "Complete this input",
                                )
                            },
                        choices = result.choices.map { it.toWire() },
                    )
                }

                is OperationPreparationResult.Invalid -> {
                    AuthoringActionResult.createInvalid(
                        diagnostics =
                            result.problems.map {
                                operationDiagnostic(it.code, it.code.replace('_', ' '), it.location)
                            },
                    )
                }

                is OperationPreparationResult.Unavailable -> {
                    AuthoringActionResult.createUnavailable(
                        diagnostics = listOf(operationDiagnostic("operation_unavailable", result.reason)),
                    )
                }

                is OperationPreparationResult.Failed -> {
                    if (result.cause is RealmCapabilityPermissionDeniedException) {
                        AuthoringActionResult.createPermissionDenied(
                            diagnostics =
                                listOf(
                                    operationDiagnostic(
                                        "permission_denied",
                                        result.cause.message ?: "Permission denied",
                                    ),
                                ),
                        )
                    } else {
                        AuthoringActionResult.createFailed(
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
            AuthoringActionResult.createStaleObservation(actual = AuthoringObservationId(value = stale.actual))
        } catch (stale: OperationCatalogChanged) {
            AuthoringActionResult.createCatalogChanged(
                actualGeneration =
                    skirout.editor.v1.type_catalog
                        .CatalogGeneration(value = stale.actual.value),
            )
        } catch (failed: OperationResolutionFailure) {
            if (failed.cause is RealmCapabilityPermissionDeniedException) {
                AuthoringActionResult.createPermissionDenied(
                    diagnostics =
                        listOf(
                            operationDiagnostic(
                                "permission_denied",
                                failed.cause?.message ?: "Permission denied",
                            ),
                        ),
                )
            } else {
                AuthoringActionResult.createFailed(
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
            AuthoringActionResult.createInvalid(
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
    val upserts = overlay.upserts.map { ResourceId(it.resource.value) to SkirAuthoringValueCodec.decode(it.content).getOrThrow() }
    val removals = overlay.removals.map { ResourceId(it.value) }
    require(
        upserts
            .map {
                it.first
            }.distinct()
            .size == upserts.size && removals.distinct().size == removals.size,
    ) { "An operation overlay contains duplicate identities." }
    return DecodedOperationContext(confirmedObservation.value, upserts.toMap(), removals.toSet())
}

internal fun skirout.editor.v1.resource_operations.OperationInvocation.decodeInvocation(): OperationInvocation {
    require(catalog.value.isNotBlank()) { "The catalog generation is required." }
    return OperationInvocation(
        invocationId.value,
        targets.map {
            ResourceId(it.value)
        },
        OperationOrigin(
            origin.container?.let {
                ResourceId(it.value)
            },
            origin.occurrences.map { SkirAuthoringValueCodec.decode(it).getOrThrow() },
        ),
    )
}

private fun PreparationChoice.toWire(): WireChoice =
    when (this) {
        is PreparationChoice.Source -> {
            WireChoice.createSource(
                choiceId = PreparationChoiceId(value = id),
                label = label,
                candidates =
                    candidates.map {
                        PreparationSourceOption(
                            label =
                                it.id.location.path
                                    .toString(),
                            occurrence = SkirAuthoringValueCodec.encode(it).getOrThrow(),
                        )
                    },
            )
        }

        is PreparationChoice.Counterpart -> {
            WireChoice.createCounterpart(
                choiceId = PreparationChoiceId(value = id),
                label = label,
                source = SkirAuthoringValueCodec.encode(source).getOrThrow(),
                candidates =
                    candidates.map {
                        PreparationCounterpartOption(
                            label =
                                when (it) {
                                    is CounterpartChoice.Existing -> {
                                        it.occurrence.id.location.path
                                            .toString()
                                    }

                                    is CounterpartChoice.New -> {
                                        "Create in ${it.containing.path}"
                                    }
                                },
                            counterpart = it.toWire(),
                        )
                    },
            )
        }
    }

private fun CounterpartChoice.toWire(): WireCounterpart =
    when (this) {
        is CounterpartChoice.Existing -> {
            WireCounterpart.ExistingWrapper(SkirAuthoringValueCodec.encode(occurrence).getOrThrow())
        }

        is CounterpartChoice.New -> {
            WireCounterpart.createNew(
                containing = SkirAuthoringValueCodec.encode(containing).getOrThrow(),
                prepared = SkirAuthoringOperationCodec.encode(prepared).getOrThrow(),
            )
        }
    }

private fun WireCounterpart.decodeCounterpart(): CounterpartChoice =
    when (this) {
        is WireCounterpart.ExistingWrapper -> {
            CounterpartChoice.Existing(SkirAuthoringValueCodec.decode(value).getOrThrow())
        }

        is WireCounterpart.NewWrapper -> {
            CounterpartChoice.New(
                SkirAuthoringValueCodec.decode(value.containing).getOrThrow(),
                SkirAuthoringOperationCodec.decode(value.prepared).getOrThrow(),
            )
        }

        else -> {
            throw IllegalArgumentException("Unknown counterpart choice")
        }
    }

private fun operationDiagnostic(
    code: String,
    message: String,
    location: ValueLocation? = null,
) = AuthoringDiagnostic(
    code = code,
    message = message,
    resource =
        location?.let {
            skirout.editor.v1.type_catalog
                .ResourceId(value = it.resource.value)
        },
    path = location?.let { SkirAuthoringValueCodec.encode(it.path).getOrThrow() },
)
