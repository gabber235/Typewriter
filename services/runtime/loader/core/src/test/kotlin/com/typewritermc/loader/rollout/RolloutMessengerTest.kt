package com.typewritermc.loader.rollout

import com.typewritermc.loader.rollout.testing.deliverRolloutReply
import com.typewritermc.loader.rollout.testing.participant
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.rolloutCommand
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import kotlin.time.Duration.Companion.minutes

@OptIn(ExperimentalCoroutinesApi::class)
val RolloutMessengerTest by testSuite {
    test("a command completes once every listed participant replied, failures included") {
        runTest {
            val transport = FakeMessageTransport()
            val communicator =
                Communicator(transport, OpenTelemetry.noop().serviceTelemetry("rollout messenger test"), ContextPropagators.noop())
            val scope = RealmRouteScope(organizationId = "organization", realmId = "realm")
            val messenger = CommunicatorRolloutMessenger(scope, communicator)
            val request =
                ApplyRolloutCommandRequest(
                    attempt = RolloutAttempt(ordinal = 1, generation = 1),
                    command = RolloutCommand.createStage(participants = listOf(participant("realm-host"), participant("engine-host"))),
                )
            val failed = ApplyRolloutCommandResponse.createCommandFailedError(serviceId = "engine-host", reason = "stage failed")
            val accepted = ApplyRolloutCommandResponse.createAccepted(serviceId = "realm-host")

            val replies = async { messenger.command(request, 5.minutes) }
            runCurrent()
            val published =
                transport.publications.single()
            published.address shouldBe scope.rolloutCommand.requestAddress.render(scope)
            scope.rolloutCommand.requestCodec.decode(published.payload) shouldBe request

            deliverRolloutReply(transport, scope, requireNotNull(published.replyTo), failed)
            runCurrent()
            replies.isCompleted shouldBe false

            deliverRolloutReply(transport, scope, requireNotNull(published.replyTo), accepted)
            runCurrent()

            replies.isCompleted shouldBe true
            replies.await() shouldContainExactly listOf(failed, accepted)
            transport.close()
        }
    }
}
