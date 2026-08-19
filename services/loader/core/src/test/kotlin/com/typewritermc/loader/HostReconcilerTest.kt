package com.typewritermc.loader

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import java.time.Instant

val HostReconcilerTest by testSuite {
    test("stages every replacement before quiescing the active deployment") {
        runTest {
            val events = mutableListOf<String>()
            val store = MemoryStore()
            val reconciler = reconciler(store, events)
            reconciler.reconcile(topology(1, 1, 1))
            events.clear()

            reconciler.reconcile(topology(2, 2, 2))

            events shouldContainExactly
                listOf(
                    "stage:REALM:2",
                    "stage:ENGINE:2",
                    "quiesce:ENGINE:1",
                    "quiesce:REALM:1",
                    "stop:ENGINE:1",
                    "stop:REALM:1",
                )
            store.value shouldBe topology(2, 2, 2)
        }
    }

    test("cleans a partial stage and retains the last applied topology") {
        runTest {
            val events = mutableListOf<String>()
            val reports = mutableListOf<HostExecutionReport>()
            val store = MemoryStore()
            val reconciler = reconciler(store, events, reports, failEngineRevision = 2)
            reconciler.reconcile(topology(1, 1, 1))
            events.clear()
            reports.clear()

            val result = reconciler.reconcile(topology(2, 2, 2))

            result.shouldBeInstanceOf<ReconciliationResult.RolledBack>()
            events shouldContainExactly listOf("stage:REALM:2", "stage:ENGINE:2", "stop:REALM:2")
            store.value shouldBe topology(1, 1, 1)
            reports.single().status shouldBe ReconciliationStatus.ROLLED_BACK
        }
    }

    test("restores the last applied topology without a control plane") {
        runTest {
            val store = MemoryStore(topology(7, 3, 4))
            val events = mutableListOf<String>()
            val reconciler = reconciler(store, events)

            reconciler.restore() shouldBe topology(7, 3, 4)

            events shouldContainExactly listOf("stage:REALM:3", "stage:ENGINE:4")
        }
    }

    test("ignores stale topology revisions") {
        runTest {
            val reconciler = reconciler(MemoryStore(), mutableListOf())
            reconciler.reconcile(topology(5, 1, null))

            reconciler.reconcile(topology(4, null, null)) shouldBe ReconciliationResult.IgnoredStale(5)
        }
    }

    test("file state survives a new store instance") {
        val directory = Files.createTempDirectory("typewriter-loader-state")
        val path = directory.resolve("nested/topology.bin")
        val expected = topology(9, 12, 14)

        FileHostStateStore(path).save(expected)

        FileHostStateStore(path).load() shouldBe expected
    }
}

private fun reconciler(
    store: MemoryStore,
    events: MutableList<String>,
    reports: MutableList<HostExecutionReport> = mutableListOf(),
    failEngineRevision: Long? = null,
) = HostReconciler(
    hostId = "host",
    workDirectory = Files.createTempDirectory("typewriter-loader"),
    runtimeFactory =
        DeploymentRuntimeFactory { child, _ ->
            events += "stage:${child.kind}:${child.manifestRevision}"
            if (child.kind == ChildKind.ENGINE && child.manifestRevision == failEngineRevision) {
                error("engine staging failed")
            }
            RecordingRuntime(child, events)
        },
    stateStore = store,
    reporter = reports::add,
)

private class RecordingRuntime(
    private val child: DesiredChild,
    private val events: MutableList<String>,
) : DeploymentRuntime {
    override suspend fun quiesce(deadline: Instant) {
        events += "quiesce:${child.kind}:${child.manifestRevision}"
    }

    override suspend fun stop() {
        events += "stop:${child.kind}:${child.manifestRevision}"
    }
}

private class MemoryStore(
    var value: DesiredTopology? = null,
) : HostStateStore {
    override fun load(): DesiredTopology? = value

    override fun save(topology: DesiredTopology) {
        value = topology
    }
}

private fun topology(
    revision: Long,
    realmRevision: Long?,
    engineRevision: Long?,
) = DesiredTopology(
    revision,
    realmRevision?.let { DesiredChild(ChildKind.REALM, "realm", it) },
    engineRevision?.let { DesiredChild(ChildKind.ENGINE, "engine", it) },
)
