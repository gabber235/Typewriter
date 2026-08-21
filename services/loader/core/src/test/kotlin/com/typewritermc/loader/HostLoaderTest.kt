package com.typewritermc.loader

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.OrganizationBinding
import com.typewritermc.services.libs.registrar.ReadySession
import com.typewritermc.services.libs.registrar.RegistrarFailure
import com.typewritermc.services.libs.registrar.RegistrarResult
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import java.nio.file.Files

val HostLoaderTest by testSuite {
    test("owns registration around every managed child") {
        runTest {
            val events = mutableListOf<String>()
            val directory = Files.createTempDirectory("typewriter-service-lifecycle")
            val controlPlane = RecordingControlPlane()
            val service = RecordingLoaderService(events)
            val loader =
                HostLoader(
                    HostEntrypoint.STANDALONE,
                    directory,
                    controlPlane,
                    DeploymentRuntimeFactory { child, _ ->
                        events += "child.start"
                        object : DeploymentRuntime {
                            override suspend fun quiesce(deadline: java.time.Instant) {
                                events += "child.quiesce"
                            }

                            override suspend fun stop() {
                                events += "child.stop"
                            }
                        }
                    },
                    this,
                    service,
                )

            val host = loader.start()
            controlPlane.desired.emit(DesiredTopology(1, realm = DesiredChild(ChildKind.REALM, "realm", "realm", 1)))
            yield()
            yield()
            host.stop()

            events shouldContainExactly
                listOf("service.start", "child.start", "child.quiesce", "child.stop", "service.stop")
        }
    }

    test("stops registration when service startup fails") {
        runTest {
            val events = mutableListOf<String>()
            val loader =
                HostLoader(
                    HostEntrypoint.STANDALONE,
                    Files.createTempDirectory("typewriter-service-start-failure"),
                    RecordingControlPlane(),
                    FakeDeploymentRuntimeFactory(),
                    this,
                    RecordingLoaderService(events, failStart = true),
                )

            val failure = runCatching { loader.start() }.exceptionOrNull()

            failure?.message shouldBe
                "Loader registration start failed: Internal(slug=service_start_failed)"
            events shouldContainExactly listOf("service.start", "service.stop")
        }
    }

    test("registers the entrypoint and reports watched topology") {
        runTest {
            val directory = Files.createTempDirectory("typewriter-online-host")
            val controlPlane = RecordingControlPlane()
            val loader =
                HostLoader(
                    HostEntrypoint.STANDALONE,
                    directory,
                    controlPlane,
                    FakeDeploymentRuntimeFactory(),
                    this,
                )

            val host = loader.start()
            controlPlane.desired.emit(
                DesiredTopology(1, realm = DesiredChild(ChildKind.REALM, "realm", "realm", 1)),
            )
            yield()
            yield()

            controlPlane.registeredEntrypoint shouldBe HostEntrypoint.STANDALONE
            controlPlane.reports shouldContainExactly
                listOf(HostExecutionReport(1, ReconciliationStatus.ACTIVE))
            HostIdentityStore(directory.resolve("state/host-id")).load() shouldBe "registered-host"
            host.stop()
        }
    }

    test("restores verified state when registration is offline") {
        runTest {
            val directory = Files.createTempDirectory("typewriter-offline-host")
            val state =
                DesiredTopology(
                    revision = 4,
                    realm = DesiredChild(ChildKind.REALM, "realm", "realm", 8),
                    engine = DesiredChild(ChildKind.ENGINE, "engine", "paper", 9),
                )
            HostIdentityStore(directory.resolve("state/host-id")).save("persisted-host")
            FileHostStateStore(directory.resolve("state/topology.bin")).save(state)
            val staged = mutableListOf<String>()
            val loader =
                HostLoader(
                    HostEntrypoint.PAPER,
                    directory,
                    OfflineControlPlane,
                    DeploymentRuntimeFactory { child, context ->
                        staged += "${context.hostId}:${child.runtimeId}:${child.manifestRevision}"
                        FakeDeploymentRuntime(child)
                    },
                    this,
                )

            val host = loader.start()

            staged shouldContainExactly listOf("persisted-host:realm:8", "persisted-host:paper:9")
            host.stop()
        }
    }
}

private class RecordingLoaderService(
    private val events: MutableList<String>,
    private val failStart: Boolean = false,
) : LoaderService {
    override val openTelemetry: OpenTelemetry = OpenTelemetry.noop()
    override val telemetry: ServiceTelemetry = openTelemetry.serviceTelemetry("test.loader")
    private val session =
        ReadySession(
            ServiceIdentity(
                "loader",
                "Loader",
                "loader",
                ServiceRole.Host("1.0.0"),
            ),
            OrganizationBinding("organization", "Organization"),
        )
    override val states =
        MutableStateFlow(
            RegistrarSnapshot(
                1,
                1,
                RegistrarState.Ready(session, 1),
            ),
        )

    override suspend fun start(): RegistrarResult<ReadySession> {
        events += "service.start"
        if (failStart) return RegistrarResult.Failure(RegistrarFailure.Internal("service_start_failed"))
        return RegistrarResult.Success(session)
    }

    override suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> =
        RegistrarResult.Failure(
            RegistrarFailure.Internal("not_used"),
        )

    override suspend fun stop(): RegistrarStopResult {
        events += "service.stop"
        return RegistrarStopResult.Success
    }
}

private class RecordingControlPlane : HostControlPlane {
    val desired = MutableSharedFlow<DesiredTopology>(replay = 1)
    val reports = mutableListOf<HostExecutionReport>()
    var registeredEntrypoint: HostEntrypoint? = null

    override suspend fun register(entrypoint: HostEntrypoint): HostRegistration {
        registeredEntrypoint = entrypoint
        return HostRegistration("registered-host", entrypoint)
    }

    override fun watchExecution(hostId: String): Flow<DesiredTopology> = desired

    override suspend fun report(
        hostId: String,
        report: HostExecutionReport,
    ) {
        reports += report
    }
}

private object OfflineControlPlane : HostControlPlane {
    override suspend fun register(entrypoint: HostEntrypoint): HostRegistration = error("offline")

    override fun watchExecution(hostId: String): Flow<DesiredTopology> = emptyFlow()

    override suspend fun report(
        hostId: String,
        report: HostExecutionReport,
    ) = Unit
}
