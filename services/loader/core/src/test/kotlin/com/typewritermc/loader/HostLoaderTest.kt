package com.typewritermc.loader

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.yield
import java.nio.file.Files

val HostLoaderTest by testSuite {
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
                DesiredTopology(1, realm = DesiredChild(ChildKind.REALM, "realm", 1)),
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
                    realm = DesiredChild(ChildKind.REALM, "realm", 8),
                    engine = DesiredChild(ChildKind.ENGINE, "paper", 9),
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
