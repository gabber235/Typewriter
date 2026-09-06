package com.typewritermc.loader

import com.typewritermc.loader.rollout.invalidatesHostedMessagingSession
import com.typewritermc.services.libs.registrar.MessagingOperation
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarStage
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RetrySchedule
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.seconds

val HostedMessagingSessionPolicyTest by testSuite {
    test("transport degradation invalidates the hosted messaging session") {
        degradedState().invalidatesHostedMessagingSession() shouldBe true
    }

    test("intentional reauthorization retains the hosted messaging session") {
        RegistrarState.Reauthorizing(binding).invalidatesHostedMessagingSession() shouldBe false
    }
}

private val binding = OrganizationBinding("organization", "Organization")
private val readySession =
    ReadySession(
        ServiceIdentity("service", "Service", "service-user", ServiceRole.Host("1")),
        binding,
    )

private fun degradedState() =
    RegistrarState.DegradedAfterReady(
        readySession,
        RegistrarStage.CONNECTING,
        RegistrarFailure.Messaging(MessagingOperation.CONNECTIVITY),
        RetrySchedule(1, 1.seconds),
    )
