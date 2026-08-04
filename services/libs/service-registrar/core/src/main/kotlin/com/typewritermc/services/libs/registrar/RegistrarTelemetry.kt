package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.TelemetryEventAttributes

internal fun MainSpanScope.recordRegistrarStateChanged(
    previous: RegistrarState,
    snapshot: RegistrarSnapshot,
) {
    val state = snapshot.state
    if (state is RegistrarState.Ready && previous is RegistrarState.Ready && state.connectionGeneration == previous.connectionGeneration) {
        return
    }
    event(
        name = "registrar.state.changed",
        projection = state.projection(),
    ) {
        attribute("registrar.state", state.wireValue())
        attribute("registrar.attempt", snapshot.attempt)
        state.attributes(this)
    }
}

private fun RegistrarState.projection(): EventProjection =
    when (this) {
        RegistrarState.Idle -> {
            EventProjection.TraceOnly
        }

        RegistrarState.LoadingIdentity -> {
            EventProjection.log(LogSeverity.INFO, "Loading the saved service identity")
        }

        RegistrarState.IssuingIdentity -> {
            EventProjection.log(LogSeverity.INFO, "Requesting a new service identity")
        }

        is RegistrarState.PersistingIdentity -> {
            EventProjection.log(LogSeverity.INFO, "Saving the service identity")
        }

        is RegistrarState.AcquiringAccessToken -> {
            EventProjection.log(LogSeverity.INFO, "Acquiring a service access token")
        }

        RegistrarState.AcquiringSentinelCredentials -> {
            EventProjection.log(LogSeverity.INFO, "Acquiring messaging credentials")
        }

        is RegistrarState.Connecting -> {
            EventProjection.log(LogSeverity.INFO, "Connecting to messaging, attempt ${displayAttempt(attempt)}")
        }

        is RegistrarState.AwaitingBinding -> {
            EventProjection.log(LogSeverity.INFO, "Waiting for service binding in the Typewriter Panel")
        }

        is RegistrarState.Reauthorizing -> {
            EventProjection.log(LogSeverity.INFO, "Applying organization permissions")
        }

        is RegistrarState.Ready -> {
            EventProjection.log(LogSeverity.INFO, "Service registration is ready")
        }

        is RegistrarState.Degraded -> {
            EventProjection.log(
                LogSeverity.WARN,
                "Service registration is unavailable. Retrying in ${retry.delay}.",
            )
        }

        is RegistrarState.Failed -> {
            EventProjection.log(LogSeverity.ERROR, "Service registration failed")
        }

        RegistrarState.Stopping -> {
            EventProjection.log(LogSeverity.INFO, "Stopping service registration")
        }

        is RegistrarState.Stopped -> {
            when (result) {
                RegistrarStopResult.Success -> EventProjection.log(LogSeverity.INFO, "Service registration stopped")
                is RegistrarStopResult.Failure -> EventProjection.log(LogSeverity.ERROR, "Service registration stopped with errors")
            }
        }
    }

private fun RegistrarState.attributes(attributes: TelemetryEventAttributes) {
    when (this) {
        RegistrarState.Idle,
        RegistrarState.LoadingIdentity,
        RegistrarState.IssuingIdentity,
        RegistrarState.AcquiringSentinelCredentials,
        RegistrarState.Stopping,
        -> {}

        is RegistrarState.PersistingIdentity -> {
            attributes.attribute("service.id", identity.serviceId)
        }

        is RegistrarState.AcquiringAccessToken -> {
            attributes.attribute("service.id", identity.serviceId)
        }

        is RegistrarState.Connecting -> {
            attributes.attribute("registrar.connection.attempt", attempt)
        }

        is RegistrarState.AwaitingBinding -> {
            attributes.attribute("service.id", identity.serviceId)
        }

        is RegistrarState.Reauthorizing -> {
            attributes.attribute("user.org.id", binding.organizationId)
        }

        is RegistrarState.Ready -> {
            attributes.attribute("service.id", session.identity.serviceId)
            attributes.attribute("user.org.id", session.binding.organizationId)
            attributes.attribute("registrar.connection.generation", connectionGeneration)
            attributes.attribute("operation.outcome", "ready")
        }

        is RegistrarState.Degraded -> {
            attributes.attribute("workflow.stage", stage.wireValue())
            attributes.attribute("retry.attempt", retry.attempt)
            attributes.attribute("retry.delay_ms", retry.delay.inWholeMilliseconds)
            attributes.failure(failure)
        }

        is RegistrarState.Failed -> {
            attributes.attribute("operation.outcome", "failed")
            attributes.attribute("identity.outcome_may_be_ambiguous", identityOutcomeMayBeAmbiguous)
            attributes.failure(failure)
        }

        is RegistrarState.Stopped -> {
            when (val stopped = result) {
                RegistrarStopResult.Success -> {
                    attributes.attribute("operation.outcome", "completed")
                }

                is RegistrarStopResult.Failure -> {
                    attributes.attribute("operation.outcome", "failed")
                    attributes.attribute("registrar.stop.failure_count", stopped.failures.size)
                }
            }
        }
    }
}

private fun TelemetryEventAttributes.failure(failure: RegistrarFailure) {
    attribute("registrar.failure.type", failure.wireType())
    failure.wireReason()?.let { attribute("registrar.failure.reason", it) }
    attribute("registrar.failure.recoverable", failure.telemetryRecoverable())
}

private fun RegistrarFailure.telemetryRecoverable(): Boolean =
    when (this) {
        is RegistrarFailure.CredentialStorage -> error.recoverable

        is RegistrarFailure.AccessToken -> recoverable

        is RegistrarFailure.Sentinel -> recoverable

        is RegistrarFailure.Messaging -> recoverable

        is RegistrarFailure.Configuration,
        is RegistrarFailure.IdentityIssuance,
        RegistrarFailure.ServiceNotFound,
        is RegistrarFailure.ProtocolIncompatible,
        is RegistrarFailure.Internal,
        -> false
    }

private fun RegistrarState.wireValue(): String =
    when (this) {
        RegistrarState.Idle -> "idle"
        RegistrarState.LoadingIdentity -> "loading_identity"
        RegistrarState.IssuingIdentity -> "issuing_identity"
        is RegistrarState.PersistingIdentity -> "persisting_identity"
        is RegistrarState.AcquiringAccessToken -> "acquiring_access_token"
        RegistrarState.AcquiringSentinelCredentials -> "acquiring_sentinel_credentials"
        is RegistrarState.Connecting -> "connecting"
        is RegistrarState.AwaitingBinding -> "awaiting_binding"
        is RegistrarState.Reauthorizing -> "reauthorizing"
        is RegistrarState.Ready -> "ready"
        is RegistrarState.Degraded -> "degraded"
        is RegistrarState.Failed -> "failed"
        RegistrarState.Stopping -> "stopping"
        is RegistrarState.Stopped -> "stopped"
    }

private fun RegistrarStage.wireValue(): String =
    when (this) {
        RegistrarStage.STORAGE -> "storage"
        RegistrarStage.ACCESS_TOKEN -> "access_token"
        RegistrarStage.SENTINEL -> "sentinel"
        RegistrarStage.CONNECTING -> "connecting"
        RegistrarStage.BINDING -> "binding"
        RegistrarStage.REAUTHORIZING -> "reauthorizing"
        RegistrarStage.HEARTBEAT -> "heartbeat"
    }

private fun RegistrarFailure.wireType(): String =
    when (this) {
        is RegistrarFailure.Configuration -> "configuration"
        is RegistrarFailure.CredentialStorage -> "credential_storage"
        is RegistrarFailure.IdentityIssuance -> "identity_issuance"
        is RegistrarFailure.AccessToken -> "access_token"
        is RegistrarFailure.Sentinel -> "sentinel"
        is RegistrarFailure.Messaging -> "messaging"
        RegistrarFailure.ServiceNotFound -> "service_not_found"
        is RegistrarFailure.ProtocolIncompatible -> "protocol_incompatible"
        is RegistrarFailure.Internal -> "internal"
    }

private fun RegistrarFailure.wireReason(): String? =
    when (this) {
        is RegistrarFailure.Configuration -> slug
        is RegistrarFailure.CredentialStorage -> error.wireReason()
        is RegistrarFailure.IdentityIssuance -> reason.wireReason()
        is RegistrarFailure.AccessToken -> reason.wireValue()
        is RegistrarFailure.Sentinel -> reason.wireValue()
        is RegistrarFailure.Messaging -> operation.wireValue()
        RegistrarFailure.ServiceNotFound -> null
        is RegistrarFailure.ProtocolIncompatible -> variant
        is RegistrarFailure.Internal -> slug
    }

private fun CredentialStorageError.wireReason(): String =
    when (this) {
        is CredentialStorageError.Unavailable -> slug
        is CredentialStorageError.Corrupt -> slug
        is CredentialStorageError.UnsupportedVersion -> "unsupported_version"
    }

private fun IdentityIssueError.wireReason(): String =
    when (this) {
        is IdentityIssueError.Rejected -> reason.wireValue()
        is IdentityIssueError.Unavailable -> "unavailable"
        is IdentityIssueError.Protocol -> variant
    }

private fun AccessTokenFailureReason.wireValue(): String =
    when (this) {
        AccessTokenFailureReason.UNAVAILABLE -> "unavailable"
        AccessTokenFailureReason.REJECTED -> "rejected"
        AccessTokenFailureReason.PROTOCOL -> "protocol"
    }

private fun SentinelFailureReason.wireValue(): String =
    when (this) {
        SentinelFailureReason.UNAVAILABLE -> "unavailable"
        SentinelFailureReason.REJECTED -> "rejected"
        SentinelFailureReason.PROTOCOL -> "protocol"
        SentinelFailureReason.STALE -> "stale"
    }

private fun MessagingOperation.wireValue(): String =
    when (this) {
        MessagingOperation.RUNTIME_CREATE -> "runtime_create"
        MessagingOperation.CONNECT -> "connect"
        MessagingOperation.BINDING_WATCH -> "binding_watch"
        MessagingOperation.BINDING_QUERY -> "binding_query"
        MessagingOperation.REAUTHORIZE -> "reauthorize"
        MessagingOperation.HEARTBEAT -> "heartbeat"
        MessagingOperation.SHUTDOWN -> "shutdown"
        MessagingOperation.CONNECTIVITY -> "connectivity"
    }

private fun IdentityRejectionReason.wireValue(): String =
    when (this) {
        IdentityRejectionReason.MALFORMED_REQUEST -> "malformed_request"
        IdentityRejectionReason.UNKNOWN_ROLE -> "unknown_role"
        IdentityRejectionReason.ROLES_REQUIRED -> "roles_required"
        IdentityRejectionReason.ROLE_UNKNOWN_PROPERTY -> "role_unknown_property"
        IdentityRejectionReason.ROLE_TYPE_INVALID -> "role_type_invalid"
        IdentityRejectionReason.ROLE_VERSION_BLANK -> "role_version_blank"
        IdentityRejectionReason.ROLE_INVALID -> "role_invalid"
        IdentityRejectionReason.CUSTOM_ROLE_NAME_REQUIRED -> "custom_role_name_required"
        IdentityRejectionReason.CUSTOM_ROLE_NAME_INVALID -> "custom_role_name_invalid"
        IdentityRejectionReason.BUILTIN_ROLE_NAME_FORBIDDEN -> "builtin_role_name_forbidden"
        IdentityRejectionReason.ENGINE_ROLE_DUPLICATE -> "engine_role_duplicate"
        IdentityRejectionReason.REALM_ROLE_DUPLICATE -> "realm_role_duplicate"
        IdentityRejectionReason.CUSTOM_ROLE_DUPLICATE -> "custom_role_duplicate"
    }

private fun displayAttempt(attempt: Long): Long = if (attempt == Long.MAX_VALUE) attempt else attempt + 1
