package com.typewritermc.realm.shell.commands

import com.github.ajalt.clikt.testing.test
import com.typewritermc.realm.shell.RealmShellContext
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarStage
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.RegistrationToken
import com.typewritermc.services.libs.registrar.RetrySchedule
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldNotContain
import io.mockk.mockk
import kotlinx.coroutines.flow.MutableStateFlow
import java.time.Instant
import kotlin.time.Duration.Companion.seconds

val StatusCommandTest by testSuite {
    test("displays each startup lifecycle state") {
        val states = listOf(
            RegistrarState.Idle to "Status: Idle",
            RegistrarState.LoadingIdentity to "Status: Loading Identity",
            RegistrarState.IssuingIdentity to "Status: Issuing Identity",
            RegistrarState.PersistingIdentity(identity) to "Status: Persisting Identity",
            RegistrarState.AcquiringAccessToken(identity) to "Status: Acquiring Access Token",
            RegistrarState.AcquiringSentinelCredentials to "Status: Acquiring Sentinel Credentials",
            RegistrarState.Connecting(3) to "Connection Attempt: 3",
            RegistrarState.Reauthorizing(OrganizationBinding("organization123", null)) to "Status: Reauthorizing",
        )

        states.forEach { (state, expected) ->
            val context = RealmShellContext(
                startTime = Instant.parse("2026-08-02T12:00:00Z"),
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, state)),
            )
            StatusCommand(context).test().output shouldContain expected
        }
    }

    test("displays awaiting binding without revealing the registration token") {
        val state = RegistrarState.AwaitingBinding(identity, RegistrationToken("SECRET12345"))
        val context = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, state)),
        )

        val output = StatusCommand(context).test().output

        output shouldContain "Status: Awaiting Binding"
        output shouldContain "Service ID: service123"
        output shouldContain "Token: [REDACTED]"
        output shouldNotContain "SECRET12345"
    }

    test("displays ready service and organization identity") {
        val state = RegistrarState.Ready(readySession(), connectionGeneration = 4)
        val context = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, state)),
        )

        val output = StatusCommand(context).test().output

        output shouldContain "Status: Ready"
        output shouldContain "Service ID: service123"
        output shouldContain "Org ID: organization123"
        output shouldContain "Org: Test Organization"
        output shouldContain "Connection Generation: 4"
    }

    test("displays degraded stage failure and retry context") {
        val state = RegistrarState.Degraded(
            session = readySession(),
            stage = RegistrarStage.HEARTBEAT,
            failure = RegistrarFailure.Messaging(MessagingOperation.HEARTBEAT),
            retry = RetrySchedule(attempt = 7, delay = 5.seconds),
        )
        val context = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, state)),
        )

        val output = StatusCommand(context).test().output

        output shouldContain "Status: Degraded"
        output shouldContain "Stage: heartbeat"
        output shouldContain "Error: messaging heartbeat"
        output shouldContain "Retry Attempt: 7"
        output shouldContain "Retry Delay: 5s"
    }

    test("displays terminal failure") {
        val state = RegistrarState.Failed(
            failure = RegistrarFailure.Internal("registration_unavailable"),
            identityOutcomeMayBeAmbiguous = true,
        )
        val context = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, state)),
        )

        val output = StatusCommand(context).test().output

        output shouldContain "Status: Failed"
        output shouldContain "Error: internal registration_unavailable"
        output shouldContain "Identity Outcome Ambiguous: true"
    }

    test("displays stopping and stopped states") {
        val stoppingContext = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Stopping)),
        )
        StatusCommand(stoppingContext).test().output shouldContain "Status: Stopping"

        val stopped = RegistrarState.Stopped(RegistrarStopResult.Success)
        val stoppedContext = RealmShellContext(
            startTime = Instant.parse("2026-08-02T12:00:00Z"),
            registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, stopped)),
        )
        val output = StatusCommand(stoppedContext).test().output

        output shouldContain "Status: Stopped"
        output shouldContain "Shutdown: completed"
    }
}

private val identity = ServiceIdentity(
    serviceId = "service123",
    displayName = "Realm Service",
    username = "realm_service",
    roles = listOf(ServiceRole.Realm("1.0.0")),
)

private fun readySession() = ReadySession(
    identity = identity,
    binding = OrganizationBinding("organization123", "Test Organization"),
    communicator = mockk<Communicator>(),
)
