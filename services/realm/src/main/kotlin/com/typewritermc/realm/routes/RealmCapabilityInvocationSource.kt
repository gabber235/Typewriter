package com.typewritermc.realm.routes

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.realm.RealmDiscoverySnapshotStore
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.capability.CapabilityInvocationRequest
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.capability.NotificationSeverity as WireNotificationSeverity
import skirout.editor.v1.capability.PanelInstruction as WirePanelInstruction
import skirout.editor.v1.diagnostic.DiagnosticCode
import skirout.editor.v1.type_catalog.CatalogGeneration

class RealmCapabilityInvocationSource(
    private val capabilities: RealmCapabilityRegistry,
    private val prototypes: TypePrototypeRegistry,
    private val snapshots: RealmDiscoverySnapshotStore,
) {
    suspend fun computation(request: CapabilityInvocationRequest): ComputationResult {
        validateBase(request)?.let { return it.toComputationResult(request.invocationId) }
        val descriptor =
            snapshots.current()?.capabilities
                ?.filterIsInstance<RealmCapabilityDescriptor.Computation>()
                ?.singleOrNull { it.id.value == request.capabilityId.value }
                ?: return invalidComputation(request, "Realm computation capability is unavailable")
        val expected = request.expectedResultType?.decode()
            ?: return invalidComputation(request, "Realm computation result type is required")
        if (expected != TypeExpression.Named(descriptor.resultType)) {
            return invalidComputation(request, "Realm computation result type does not match its capability")
        }

        return try {
            val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
            val value =
                capabilities.requireComputation(CapabilityId(request.capabilityId.value)).invoke(
                    ComputationContext(request.invocationId.value),
                    prototypes,
                    payload,
                )
            ComputationResult.createSuccess(
                invocationId = request.invocationId,
                value = SkirDataValueCodec.encode(value).getOrThrow(),
            )
        } catch (failure: RealmCapabilityPermissionDeniedException) {
            ComputationResult.createPermissionDenied(
                invocationId = request.invocationId,
                message = failure.message ?: "Permission denied",
            )
        } catch (failure: Throwable) {
            ComputationResult.createUnavailable(
                invocationId = request.invocationId,
                diagnostics = listOf(capabilityDiagnostic(failure)),
            )
        }
    }

    suspend fun command(request: CapabilityInvocationRequest): CommandResult {
        validateBase(request)?.let { return it.toCommandResult(request.invocationId) }
        val descriptor =
            snapshots.current()?.capabilities
                ?.filterIsInstance<RealmCapabilityDescriptor.Command>()
                ?.singleOrNull { it.id.value == request.capabilityId.value }
                ?: return invalidCommand(request, "Realm command capability is unavailable")
        if (request.expectedResultType != null) {
            return invalidCommand(request, "Realm command result type must be absent")
        }

        return try {
            val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
            val outcome =
                capabilities.requireCommand(descriptor.id).invoke(
                    CommandContext(request.invocationId.value),
                    prototypes,
                    payload,
                )
            CommandResult.createSuccess(
                invocationId = request.invocationId,
                instructions = outcome.instructions.map { it.toWire() },
            )
        } catch (failure: RealmCapabilityPermissionDeniedException) {
            CommandResult.createPermissionDenied(
                invocationId = request.invocationId,
                message = failure.message ?: "Permission denied",
            )
        } catch (failure: Throwable) {
            CommandResult.createUnavailable(
                invocationId = request.invocationId,
                diagnostics = listOf(capabilityDiagnostic(failure)),
            )
        }
    }

    private fun validateBase(request: CapabilityInvocationRequest): InvocationValidationFailure? {
        if (request.invocationId.value.isBlank()) return InvocationValidationFailure.Invalid("Invocation ID must not be blank")
        if (request.capabilityId.value.isBlank()) return InvocationValidationFailure.Invalid("Capability ID must not be blank")
        if (request.payload == skirout.editor.v1.type_catalog.TypedValue.UNKNOWN) {
            return InvocationValidationFailure.Invalid("Capability payload is missing")
        }
        val current = snapshots.current()
            ?: return InvocationValidationFailure.Unavailable("Realm catalog is unavailable")
        if (request.generation.value != current.discovery.generation.value) {
            return InvocationValidationFailure.Stale(current.discovery.generation.value)
        }
        return null
    }
}

private sealed interface InvocationValidationFailure {
    data class Invalid(val message: String) : InvocationValidationFailure
    data class Unavailable(val message: String) : InvocationValidationFailure
    data class Stale(val actualGeneration: String) : InvocationValidationFailure
}

private data class ComputationContext(
    override val invocationId: String,
) : RealmComputationContext

private data class CommandContext(
    override val invocationId: String,
) : RealmCommandContext

private fun InvocationValidationFailure.toComputationResult(
    invocationId: skirout.editor.v1.capability.InvocationId,
): ComputationResult =
    when (this) {
        is InvocationValidationFailure.Invalid ->
            ComputationResult.createInvalid(invocationId = invocationId, diagnostics = listOf(capabilityDiagnostic(message)))
        is InvocationValidationFailure.Unavailable ->
            ComputationResult.createUnavailable(invocationId = invocationId, diagnostics = listOf(capabilityDiagnostic(message)))
        is InvocationValidationFailure.Stale ->
            ComputationResult.createStaleGeneration(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
    }

private fun InvocationValidationFailure.toCommandResult(
    invocationId: skirout.editor.v1.capability.InvocationId,
): CommandResult =
    when (this) {
        is InvocationValidationFailure.Invalid ->
            CommandResult.createInvalid(invocationId = invocationId, diagnostics = listOf(capabilityDiagnostic(message)))
        is InvocationValidationFailure.Unavailable ->
            CommandResult.createUnavailable(invocationId = invocationId, diagnostics = listOf(capabilityDiagnostic(message)))
        is InvocationValidationFailure.Stale ->
            CommandResult.createStaleGeneration(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
    }

private fun skirout.editor.v1.type_catalog.TypeExpression.decode(): TypeExpression? =
    when (val result = SkirTypeCodec.decode(this)) {
        is SkirConversionResult.Success -> result.value
        is SkirConversionResult.Failure -> null
    }

private fun invalidComputation(
    request: CapabilityInvocationRequest,
    message: String,
): ComputationResult =
    ComputationResult.createInvalid(
        invocationId = request.invocationId,
        diagnostics = listOf(capabilityDiagnostic(message)),
    )

private fun invalidCommand(
    request: CapabilityInvocationRequest,
    message: String,
): CommandResult =
    CommandResult.createInvalid(
        invocationId = request.invocationId,
        diagnostics = listOf(capabilityDiagnostic(message)),
    )

private fun capabilityDiagnostic(failure: Throwable) =
    capabilityDiagnostic(failure.message ?: "Realm capability failed")

private fun capabilityDiagnostic(message: String) =
    realmPresentationSearchDiagnostic(DiagnosticCode.INVALID_VALUE, message)

private fun PanelInstruction.toWire(): WirePanelInstruction =
    when (this) {
        is PanelInstruction.InvalidateResource ->
            WirePanelInstruction.createInvalidateResource(
                resource = resource.type.toWireResource(SkirDataValueCodec.encode(resource.identity).getOrThrow()),
            )
        is PanelInstruction.OpenResource ->
            WirePanelInstruction.createOpenResource(
                resource = resource.type.toWireResource(SkirDataValueCodec.encode(resource.identity).getOrThrow()),
            )
        is PanelInstruction.Notify ->
            WirePanelInstruction.createNotify(severity = severity.toWire(), message = message)
    }

private fun com.typewritermc.types.ResolvedTypeRef.toWireResource(
    identity: skirout.editor.v1.type_catalog.TypedValue,
) = skirout.editor.v1.capability.ResourceAddress(
    resourceType = SkirTypeCodec.encode(this).getOrThrow(),
    identity = identity,
)

private fun NotificationSeverity.toWire(): WireNotificationSeverity =
    when (this) {
        NotificationSeverity.INFO -> WireNotificationSeverity.INFO
        NotificationSeverity.SUCCESS -> WireNotificationSeverity.SUCCESS
        NotificationSeverity.WARNING -> WireNotificationSeverity.WARNING
        NotificationSeverity.ERROR -> WireNotificationSeverity.ERROR
    }
