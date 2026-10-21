package com.typewritermc.realm.routes

import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.types.isValid
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.requirePortable
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import skirout.editor.v1.capability.CapabilityDefinition
import skirout.editor.v1.capability.CapabilityInvocationRequest
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.InvocationId
import skirout.editor.v1.capability.ResourceAddress
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.diagnostic.DiagnosticSeverity
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DiagnosticId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.capability.NotificationSeverity as WireNotificationSeverity
import skirout.editor.v1.capability.PanelInstruction as WirePanelInstruction

/**
 * Dispatches editor computation and command invocations through a retained Realm catalog.
 *
 * Catalog generation, capability kind, and result type are validated before provider invocation. Computations
 * return typed portable data; commands return panel instructions. The catalog lease bounds callback lifetime,
 * while invocation identity is passed through for correlation and supplies no deduplication in this adapter.
 */
class RealmCapabilityInvocationSource(
    private val catalogs: RealmCatalogStore,
) {
    suspend fun computation(request: CapabilityInvocationRequest): ComputationResult {
        val catalog =
            catalogs.captureCurrentOrNull()
                ?: return unavailableComputation(request, "Realm catalog is unavailable")
        catalog.use {
            validateBase(request, it.generation.value)?.let { failure ->
                return failure.toComputationResult(request.invocationId)
            }
            val registry = RealmCapabilityRegistry(it.capabilities)
            val descriptor =
                registry.definitions
                    .filterIsInstance<CapabilityDefinition.ComputationWrapper>()
                    .map { it.value }
                    .singleOrNull { descriptor -> descriptor.capabilityId == request.capabilityId }
                    ?: return invalidComputation(request, "Realm computation capability is unavailable")
            val expected =
                request.expectedResultType?.takeIf { it.isValid }
                    ?: return invalidComputation(request, "Realm computation result type is required")
            if (expected != descriptor.resultType.toTemplate()) {
                return invalidComputation(request, "Realm computation result type does not match its capability")
            }
            return try {
                val payload = request.payload.requirePortable()
                val value =
                    registry.requireComputation(request.capabilityId).invoke(
                        ComputationContext(request.invocationId.value),
                        RealmCapabilityRuntime(it.checked, it.nativeBindings),
                        payload,
                    )
                ComputationResult.createSuccess(
                    invocationId = request.invocationId,
                    value = value.requirePortable(),
                )
            } catch (failure: RealmCapabilityPermissionDeniedException) {
                ComputationResult.createPermissionDeniedError(
                    invocationId = request.invocationId,
                    message = failure.message ?: "Permission denied",
                )
            } catch (failure: Throwable) {
                unavailableComputation(request, failure.message ?: "Realm computation failed")
            }
        }
    }

    suspend fun command(request: CapabilityInvocationRequest): CommandResult {
        val catalog =
            catalogs.captureCurrentOrNull()
                ?: return unavailableCommand(request, "Realm catalog is unavailable")
        catalog.use {
            validateBase(request, it.generation.value)?.let { failure ->
                return failure.toCommandResult(request.invocationId)
            }
            val registry = RealmCapabilityRegistry(it.capabilities)
            val descriptor =
                registry.definitions
                    .filterIsInstance<CapabilityDefinition.CommandWrapper>()
                    .map { it.value }
                    .singleOrNull { descriptor -> descriptor.capabilityId == request.capabilityId }
                    ?: return invalidCommand(request, "Realm command capability is unavailable")
            if (request.expectedResultType != null) {
                return invalidCommand(request, "Realm command result type must be absent")
            }
            return try {
                val payload = request.payload.requirePortable()
                val outcome =
                    registry.requireCommand(descriptor.capabilityId).invoke(
                        CommandContext(request.invocationId.value),
                        RealmCapabilityRuntime(it.checked, it.nativeBindings),
                        payload,
                    )
                CommandResult.createSuccess(
                    invocationId = request.invocationId,
                    instructions = outcome.instructions.map { instruction -> instruction.toWire() },
                )
            } catch (failure: RealmCapabilityPermissionDeniedException) {
                CommandResult.createPermissionDeniedError(
                    invocationId = request.invocationId,
                    message = failure.message ?: "Permission denied",
                )
            } catch (failure: Throwable) {
                unavailableCommand(request, failure.message ?: "Realm command failed")
            }
        }
    }
}

private fun validateBase(
    request: CapabilityInvocationRequest,
    generation: String,
): InvocationValidationFailure? {
    if (request.invocationId.value.isBlank()) return InvocationValidationFailure.Invalid("Invocation ID must not be blank")
    if (request.capabilityId.value.isBlank()) return InvocationValidationFailure.Invalid("Capability ID must not be blank")
    if (request.payload == DataValue.UNKNOWN) {
        return InvocationValidationFailure.Invalid("Capability payload is missing")
    }
    if (request.generation.value != generation) return InvocationValidationFailure.Stale(generation)
    return null
}

private sealed interface InvocationValidationFailure {
    data class Invalid(
        val message: String,
    ) : InvocationValidationFailure

    data class Stale(
        val actualGeneration: String,
    ) : InvocationValidationFailure
}

private data class ComputationContext(
    override val invocationId: String,
) : RealmComputationContext

private data class CommandContext(
    override val invocationId: String,
) : RealmCommandContext

private fun InvocationValidationFailure.toComputationResult(invocationId: InvocationId): ComputationResult =
    when (this) {
        is InvocationValidationFailure.Invalid -> {
            ComputationResult.createInvalidError(invocationId = invocationId, diagnostics = listOf(realmDiagnostic(message)))
        }

        is InvocationValidationFailure.Stale -> {
            ComputationResult.createStaleGenerationError(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
        }
    }

private fun InvocationValidationFailure.toCommandResult(invocationId: InvocationId): CommandResult =
    when (this) {
        is InvocationValidationFailure.Invalid -> {
            CommandResult.createInvalidError(invocationId = invocationId, diagnostics = listOf(realmDiagnostic(message)))
        }

        is InvocationValidationFailure.Stale -> {
            CommandResult.createStaleGenerationError(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
        }
    }

private fun invalidComputation(
    request: CapabilityInvocationRequest,
    message: String,
): ComputationResult =
    ComputationResult.createInvalidError(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun unavailableComputation(
    request: CapabilityInvocationRequest,
    message: String,
): ComputationResult =
    ComputationResult.createUnavailableError(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun invalidCommand(
    request: CapabilityInvocationRequest,
    message: String,
): CommandResult =
    CommandResult.createInvalidError(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun unavailableCommand(
    request: CapabilityInvocationRequest,
    message: String,
): CommandResult =
    CommandResult.createUnavailableError(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun PanelInstruction.toWire(): WirePanelInstruction =
    when (this) {
        is PanelInstruction.InvalidateResource -> {
            WirePanelInstruction.createInvalidateResource(
                resource = resource.type.toWireResource(resource.identity.requirePortable()),
            )
        }

        is PanelInstruction.OpenResource -> {
            WirePanelInstruction.createOpenResource(
                resource = resource.type.toWireResource(resource.identity.requirePortable()),
            )
        }

        is PanelInstruction.Notify -> {
            WirePanelInstruction.createNotify(severity = severity.toWire(), message = message)
        }
    }

private fun TypeUse.toWireResource(identity: DataValue) =
    ResourceAddress(
        resourceType = this,
        identity = identity,
    )

private fun NotificationSeverity.toWire(): WireNotificationSeverity =
    when (this) {
        NotificationSeverity.INFO -> WireNotificationSeverity.INFO
        NotificationSeverity.SUCCESS -> WireNotificationSeverity.SUCCESS
        NotificationSeverity.WARNING -> WireNotificationSeverity.WARNING
        NotificationSeverity.ERROR -> WireNotificationSeverity.ERROR
    }

internal fun realmDiagnostic(message: String): Diagnostic =
    Diagnostic(
        id =
            DiagnosticId(value = "realm:capability"),
        origin =
            RuleOrigin(owner = REALM_CAPABILITY_DIAGNOSTIC_TYPE, ordinal = 0),
        code = "realm_capability",
        message = message,
        severity = DiagnosticSeverity.ERROR,
        primary = null,
        related = emptyList(),
    )

private val REALM_CAPABILITY_DIAGNOSTIC_TYPE =
    TypeDefinitionId.qualified("typewriter", "realm_capability")
