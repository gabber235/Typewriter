package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.core.CliktCommand
import com.github.ajalt.clikt.core.Context
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.registrar.AccessTokenFailureReason
import com.typewritermc.services.libs.registrar.CredentialStorageError
import com.typewritermc.services.libs.registrar.IdentityIssueError
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarStage
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopFailure
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.SentinelFailureReason
import java.time.Duration
import java.time.Instant

class StatusCommand(
    private val context: RealmShellContext,
) : CliktCommand(name = "status") {
    override fun help(context: Context) = "Show the current status of the Realm service"
    override fun run() {
        val uptime = Duration.between(context.startTime, Instant.now())
        val uptimeFormatted = formatDuration(uptime)

        echo("Realm Service Status")
        echo("Version: ${context.version}")
        echo("Uptime:  $uptimeFormatted")

        displayRegistrationStatus()
    }

    private fun displayRegistrationStatus() {
        echo("")
        echo("Registration Status")
        val snapshot = context.registrarSnapshot
        echo("Sequence: ${snapshot.sequence}")
        echo("Attempt:  ${snapshot.attempt}")

        when (val state = snapshot.state) {
            RegistrarState.Idle -> echo("Status: Idle")
            RegistrarState.LoadingIdentity -> echo("Status: Loading Identity")
            RegistrarState.IssuingIdentity -> echo("Status: Issuing Identity")
            is RegistrarState.PersistingIdentity -> {
                echo("Status: Persisting Identity")
                displayIdentity(state.identity.serviceId, state.identity.displayName)
            }
            is RegistrarState.AcquiringAccessToken -> {
                echo("Status: Acquiring Access Token")
                displayIdentity(state.identity.serviceId, state.identity.displayName)
            }
            RegistrarState.AcquiringSentinelCredentials -> echo("Status: Acquiring Sentinel Credentials")
            is RegistrarState.Connecting -> {
                echo("Status: Connecting")
                echo("Connection Attempt: ${state.attempt}")
            }
            is RegistrarState.AwaitingBinding -> {
                echo("Status: Awaiting Binding")
                displayIdentity(state.identity.serviceId, state.identity.displayName)
                echo("Token: [REDACTED]")
            }
            is RegistrarState.Reauthorizing -> {
                echo("Status: Reauthorizing")
                displayBinding(state.binding.organizationId, state.binding.organizationName)
            }
            is RegistrarState.Ready -> {
                echo("Status: Ready")
                displayIdentity(state.session.identity.serviceId, state.session.identity.displayName)
                displayBinding(state.session.binding.organizationId, state.session.binding.organizationName)
                echo("Connection Generation: ${state.connectionGeneration}")
            }
            is RegistrarState.Degraded -> {
                echo("Status: Degraded")
                echo("Stage: ${state.stage.displayName()}")
                echo("Error: ${state.failure.displayName()}")
                echo("Retry Attempt: ${state.retry.attempt}")
                echo("Retry Delay: ${state.retry.delay}")
                state.session?.let {
                    displayIdentity(it.identity.serviceId, it.identity.displayName)
                    displayBinding(it.binding.organizationId, it.binding.organizationName)
                }
            }
            is RegistrarState.Failed -> {
                echo("Status: Failed")
                echo("Error: ${state.failure.displayName()}")
                echo("Identity Outcome Ambiguous: ${state.identityOutcomeMayBeAmbiguous}")
            }
            RegistrarState.Stopping -> echo("Status: Stopping")
            is RegistrarState.Stopped -> {
                echo("Status: Stopped")
                echo("Shutdown: ${state.result.displayName()}")
            }
        }
    }

    private fun displayIdentity(serviceId: String, displayName: String) {
        echo("Service ID: $serviceId")
        echo("Service: $displayName")
    }

    private fun displayBinding(organizationId: String, organizationName: String?) {
        echo("Org ID: $organizationId")
        echo("Org: ${organizationName ?: "Unknown"}")
    }

    private fun formatDuration(duration: Duration): String {
        val hours = duration.toHours()
        val minutes = duration.toMinutesPart()
        val seconds = duration.toSecondsPart()
        return "%02d:%02d:%02d".format(hours, minutes, seconds)
    }
}

private fun RegistrarStage.displayName(): String = name.lowercase().replace('_', ' ')

private fun RegistrarFailure.displayName(): String = when (this) {
    is RegistrarFailure.Configuration -> "configuration $slug"
    is RegistrarFailure.CredentialStorage -> "credential storage ${error.displayName()}"
    is RegistrarFailure.IdentityIssuance -> "identity issuance ${reason.displayName()}"
    is RegistrarFailure.AccessToken -> "access token ${reason.displayName()}"
    is RegistrarFailure.Sentinel -> "sentinel ${reason.displayName()}"
    is RegistrarFailure.Messaging -> "messaging ${operation.name.lowercase().replace('_', ' ')}"
    RegistrarFailure.ServiceNotFound -> "service not found"
    is RegistrarFailure.ProtocolIncompatible -> "protocol incompatible for $operation with variant $variant"
    is RegistrarFailure.Internal -> "internal $slug"
}

private fun CredentialStorageError.displayName(): String = when (this) {
    is CredentialStorageError.Unavailable -> "unavailable $slug"
    is CredentialStorageError.Corrupt -> "corrupt $slug"
    is CredentialStorageError.UnsupportedVersion -> "unsupported version $version"
}

private fun IdentityIssueError.displayName(): String = when (this) {
    is IdentityIssueError.Rejected -> "rejected ${reason.name.lowercase().replace('_', ' ')}"
    is IdentityIssueError.Unavailable -> "unavailable"
    is IdentityIssueError.Protocol -> "protocol $variant"
}

private fun AccessTokenFailureReason.displayName(): String = name.lowercase().replace('_', ' ')

private fun SentinelFailureReason.displayName(): String = name.lowercase().replace('_', ' ')

private fun RegistrarStopResult.displayName(): String = when (this) {
    RegistrarStopResult.Success -> "completed"
    is RegistrarStopResult.Failure -> failures.joinToString { it.displayName() }
}

private fun RegistrarStopFailure.displayName(): String = when (this) {
    is RegistrarStopFailure.Runtime -> operation.name.lowercase().replace('_', ' ')
    is RegistrarStopFailure.Internal -> "internal $slug"
}
