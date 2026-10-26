package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.hostExecutionReport
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.test.runTest
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.ReportHostExecutionResponse
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

val BackendHostExecutionReporterTest by testSuite {
    test("a report tells the backend which assigned runtimes are absent") {
        runTest {
            val transport = FakeMessageTransport().answering(ReportHostExecutionResponse.createSuccess())

            reporter.report(observation(setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)), session(transport))

            val sent = scope.hostExecutionReport.requestCodec.decode(transport.requests().single().payload)
            sent.topologyRevision shouldBe 7
            sent.realmState shouldBe
                ChildRuntimeState(status = ChildRuntimeStatus.ABSENT, activeArtifactVersion = null, message = null, updatedAt = NOW)
            sent.engineState shouldBe null
        }
    }

    test("a report the backend already superseded is accepted, so the host does not retry it") {
        runTest {
            val transport = FakeMessageTransport().answering(ReportHostExecutionResponse.createStaleRevisionError())

            reporter.report(observation(setOf(RuntimePlacement.REALM)), session(transport))
        }
    }

    test("a report the backend failed to store fails, so the host retries it") {
        runTest {
            val transport = FakeMessageTransport().answering(ReportHostExecutionResponse.createInternalError())

            shouldThrow<IllegalStateException> {
                reporter.report(observation(setOf(RuntimePlacement.REALM)), session(transport))
            }.message.orEmpty() shouldStartWith "Host execution report failed"
        }
    }

    test("a report that never reached the backend fails, so the host retries it") {
        runTest {
            val transport = FakeMessageTransport().apply { failNextRequest(TransportError.Unavailable()) }

            shouldThrow<IllegalStateException> {
                reporter.report(observation(setOf(RuntimePlacement.REALM)), session(transport))
            }.message.orEmpty() shouldStartWith "Host execution report failed"
        }
    }
}

private val NOW = Instant.parse("2026-10-26T12:00:00Z")
private val HOST = ServiceId("host")
private val scope = ServiceRouteScope(HOST.value)
private val reporter = BackendHostExecutionReporter(Clock.fixed(NOW, ZoneOffset.UTC))

private fun observation(roles: Set<RuntimePlacement>) = HostExecutionObservation(ExecutionRevision(HOST, 7), roles, status = null)

private fun session(transport: FakeMessageTransport) =
    HostedMessagingSession(
        1,
        "organization",
        Communicator(transport, OpenTelemetry.noop().serviceTelemetry("host execution report test"), ContextPropagators.noop()),
    )

private fun FakeMessageTransport.answering(response: ReportHostExecutionResponse) =
    apply {
        respondWith { request, _ ->
            TransportResult.Success(InboundMessage(request.address, scope.hostExecutionReport.responseCodec.encode(response)))
        }
    }

private fun FakeMessageTransport.requests() = actions.filterIsInstance<FakeMessageTransport.Action.Request>().map { it.message }
