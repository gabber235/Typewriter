package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.testing.hostedSession
import com.typewritermc.protocol.transport.ServiceRouteScope
import com.typewritermc.protocol.transport.generated.hostExecutionReport
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import kotlinx.coroutines.test.runTest
import skirout.service.v1.topology.ChildRuntimeState
import skirout.service.v1.topology.ChildRuntimeStatus
import skirout.service.v1.topology.ReportHostExecutionResponse
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset

val BackendHostExecutionReporterTest by testSuite {
    val now = Instant.parse("2026-10-26T12:00:00Z")
    val host = ServiceId("host")
    val scope = ServiceRouteScope(host.value)
    val reporter = BackendHostExecutionReporter(Clock.fixed(now, ZoneOffset.UTC))

    test("a report tells the backend which assigned runtimes are absent") {
        runTest {
            val transport = FakeMessageTransport().apply { answer(scope.hostExecutionReport, ReportHostExecutionResponse.createSuccess()) }

            reporter.report(
                HostExecutionObservation(
                    ExecutionRevision(host, 7),
                    setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE),
                    status = null,
                ),
                hostedSession(transport),
            )

            val sent = scope.hostExecutionReport.requestCodec.decode(transport.requests.single().payload)
            sent.topologyRevision shouldBe 7
            sent.realmState shouldBe
                ChildRuntimeState(status = ChildRuntimeStatus.ABSENT, activeArtifactVersion = null, message = null, updatedAt = now)
            sent.engineState shouldBe null
        }
    }

    test("a report the backend already superseded is accepted, so the host does not retry it") {
        runTest {
            val transport =
                FakeMessageTransport().apply {
                    answer(
                        scope.hostExecutionReport,
                        ReportHostExecutionResponse.createStaleRevisionError(),
                    )
                }

            reporter.report(
                HostExecutionObservation(ExecutionRevision(host, 7), setOf(RuntimePlacement.REALM), status = null),
                hostedSession(transport),
            )
        }
    }

    test("a report the backend failed to store fails, so the host retries it") {
        runTest {
            val transport =
                FakeMessageTransport().apply {
                    answer(
                        scope.hostExecutionReport,
                        ReportHostExecutionResponse.createInternalError(),
                    )
                }

            shouldThrow<IllegalStateException> {
                reporter.report(
                    HostExecutionObservation(ExecutionRevision(host, 7), setOf(RuntimePlacement.REALM), status = null),
                    hostedSession(transport),
                )
            }.message.orEmpty() shouldStartWith "Host execution report failed"
        }
    }

    test("a report that never reached the backend fails, so the host retries it") {
        runTest {
            val transport = FakeMessageTransport().apply { failNextRequest(TransportError.Unavailable()) }

            shouldThrow<IllegalStateException> {
                reporter.report(
                    HostExecutionObservation(ExecutionRevision(host, 7), setOf(RuntimePlacement.REALM), status = null),
                    hostedSession(transport),
                )
            }.message.orEmpty() shouldStartWith "Host execution report failed"
        }
    }
}
