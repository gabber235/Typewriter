package com.typewritermc.loader

import com.typewritermc.loader.rollout.invalidatesHostedMessagingSession
import com.typewritermc.loader.testing.binding
import com.typewritermc.loader.testing.degradedState
import com.typewritermc.services.libs.registrar.RegistrarState
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val HostedMessagingSessionPolicyTest by testSuite {
    test("transport degradation invalidates the hosted messaging session") {
        degradedState().invalidatesHostedMessagingSession() shouldBe true
    }

    test("intentional reauthorization retains the hosted messaging session") {
        RegistrarState.Reauthorizing(binding).invalidatesHostedMessagingSession() shouldBe false
    }
}
