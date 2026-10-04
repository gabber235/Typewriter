package com.typewritermc.realm.routes

import com.typewritermc.capability.CapabilityId
import com.typewritermc.capability.NotificationSeverity
import com.typewritermc.capability.PanelInstruction
import com.typewritermc.capability.RealmCapabilityDescriptor
import com.typewritermc.capability.RealmCapabilityPermissionDeniedException
import com.typewritermc.capability.RealmCapabilityRegistry
import com.typewritermc.capability.RealmCapabilityRuntime
import com.typewritermc.capability.RealmCommandContext
import com.typewritermc.capability.RealmComputationContext
import com.typewritermc.realm.catalog.RealmCatalogStore
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.skir.SkirConversionResult
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.capability.CapabilityInvocationRequest
import skirout.editor.v1.capability.CommandResult
import skirout.editor.v1.capability.ComputationResult
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.capability.NotificationSeverity as WireNotificationSeverity
import skirout.editor.v1.capability.PanelInstruction as WirePanelInstruction

class RealmCapabilityInvocationSource(
    private val catalogs: RealmCatalogStore,
) {
    suspend fun computation(request: CapabilityInvocationRequest): ComputationResult {
        val catalog =
            runCatching { catalogs.captureCurrent() }.getOrNull()
                ?: return unavailableComputation(request, "Realm catalog is unavailable")
        catalog.use {
            validateBase(request, it.generation.value)?.let { failure ->
                return failure.toComputationResult(request.invocationId)
            }
            val registry = RealmCapabilityRegistry(it.capabilities)
            val descriptor =
                registry.descriptors
                    .filterIsInstance<RealmCapabilityDescriptor.Computation>()
                    .singleOrNull { descriptor -> descriptor.id.value == request.capabilityId.value }
                    ?: return invalidComputation(request, "Realm computation capability is unavailable")
            val expected =
                request.expectedResultType?.decode()
                    ?: return invalidComputation(request, "Realm computation result type is required")
            if (expected != descriptor.resultType.toTemplate()) {
                return invalidComputation(request, "Realm computation result type does not match its capability")
            }
            return try {
                val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
                val value =
                    registry.requireComputation(CapabilityId(request.capabilityId.value)).invoke(
                        ComputationContext(request.invocationId.value),
                        RealmCapabilityRuntime(it.checked, it.nativeBindings),
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
                unavailableComputation(request, failure.message ?: "Realm computation failed")
            }
        }
    }

    suspend fun command(request: CapabilityInvocationRequest): CommandResult {
        val catalog =
            runCatching { catalogs.captureCurrent() }.getOrNull()
                ?: return unavailableCommand(request, "Realm catalog is unavailable")
        catalog.use {
            validateBase(request, it.generation.value)?.let { failure ->
                return failure.toCommandResult(request.invocationId)
            }
            val registry = RealmCapabilityRegistry(it.capabilities)
            val descriptor =
                registry.descriptors
                    .filterIsInstance<RealmCapabilityDescriptor.Command>()
                    .singleOrNull { descriptor -> descriptor.id.value == request.capabilityId.value }
                    ?: return invalidCommand(request, "Realm command capability is unavailable")
            if (request.expectedResultType != null) {
                return invalidCommand(request, "Realm command result type must be absent")
            }
            return try {
                val payload = SkirDataValueCodec.decode(request.payload).getOrThrow()
                val outcome =
                    registry.requireCommand(descriptor.id).invoke(
                        CommandContext(request.invocationId.value),
                        RealmCapabilityRuntime(it.checked, it.nativeBindings),
                        payload,
                    )
                CommandResult.createSuccess(
                    invocationId = request.invocationId,
                    instructions = outcome.instructions.map { instruction -> instruction.toWire() },
                )
            } catch (failure: RealmCapabilityPermissionDeniedException) {
                CommandResult.createPermissionDenied(
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
    if (request.payload == skirout.editor.v1.type_catalog.DataValue.UNKNOWN) {
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

private fun InvocationValidationFailure.toComputationResult(invocationId: skirout.editor.v1.capability.InvocationId): ComputationResult =
    when (this) {
        is InvocationValidationFailure.Invalid -> {
            ComputationResult.createInvalid(invocationId = invocationId, diagnostics = listOf(realmDiagnostic(message)))
        }

        is InvocationValidationFailure.Stale -> {
            ComputationResult.createStaleGeneration(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
        }
    }

private fun InvocationValidationFailure.toCommandResult(invocationId: skirout.editor.v1.capability.InvocationId): CommandResult =
    when (this) {
        is InvocationValidationFailure.Invalid -> {
            CommandResult.createInvalid(invocationId = invocationId, diagnostics = listOf(realmDiagnostic(message)))
        }

        is InvocationValidationFailure.Stale -> {
            CommandResult.createStaleGeneration(
                invocationId = invocationId,
                actualGeneration = CatalogGeneration(value = actualGeneration),
            )
        }
    }

private fun skirout.editor.v1.type_catalog.TypeTemplate.decode(): TypeTemplate? =
    when (val result = SkirTypeCodec.decode(this)) {
        is SkirConversionResult.Success -> result.value
        is SkirConversionResult.Failure -> null
    }

private fun TypeUse.toTemplate(): TypeTemplate =
    when (this) {
        is TypeUse.Named -> TypeTemplate.Named(definition, arguments.map { it.toTemplate() })
        is TypeUse.Nullable -> TypeTemplate.Nullable(value.toTemplate())
        is TypeUse.Scalar -> TypeTemplate.Scalar(kind)
    }

private fun invalidComputation(
    request: CapabilityInvocationRequest,
    message: String,
): ComputationResult =
    ComputationResult.createInvalid(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun unavailableComputation(
    request: CapabilityInvocationRequest,
    message: String,
): ComputationResult =
    ComputationResult.createUnavailable(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun invalidCommand(
    request: CapabilityInvocationRequest,
    message: String,
): CommandResult =
    CommandResult.createInvalid(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun unavailableCommand(
    request: CapabilityInvocationRequest,
    message: String,
): CommandResult =
    CommandResult.createUnavailable(
        invocationId = request.invocationId,
        diagnostics = listOf(realmDiagnostic(message)),
    )

private fun PanelInstruction.toWire(): WirePanelInstruction =
    when (this) {
        is PanelInstruction.InvalidateResource -> {
            WirePanelInstruction.createInvalidateResource(
                resource = resource.type.toWireResource(SkirDataValueCodec.encode(resource.identity).getOrThrow()),
            )
        }

        is PanelInstruction.OpenResource -> {
            WirePanelInstruction.createOpenResource(
                resource = resource.type.toWireResource(SkirDataValueCodec.encode(resource.identity).getOrThrow()),
            )
        }

        is PanelInstruction.Notify -> {
            WirePanelInstruction.createNotify(severity = severity.toWire(), message = message)
        }
    }

private fun TypeUse.toWireResource(identity: skirout.editor.v1.type_catalog.DataValue) =
    skirout.editor.v1.capability.ResourceAddress(
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

internal fun realmDiagnostic(message: String): skirout.editor.v1.diagnostic.Diagnostic =
    skirout.editor.v1.diagnostic.Diagnostic(
        id =
            skirout.editor.v1.type_catalog
                .DiagnosticId(value = "realm:capability"),
        origin =
            skirout.editor.v1.type_catalog.RuleOrigin(
                owner =
                    (
                        SkirTypeCodec.encode(TypeUse.Named(REALM_CAPABILITY_DIAGNOSTIC_TYPE)).getOrThrow() as
                            skirout.editor.v1.type_catalog.TypeUse.NamedWrapper
                    ).value.definition,
                ordinal = 0,
            ),
        code = "realm_capability",
        message = message,
        severity = skirout.editor.v1.diagnostic.DiagnosticSeverity.ERROR,
        primary = null,
        related = emptyList(),
    )

private val REALM_CAPABILITY_DIAGNOSTIC_TYPE =
    TypeDefinitionId(TypeId.Qualified("typewriter", "realm_capability"), 1)
