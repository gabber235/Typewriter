package com.typewritermc.loader.rollout

import com.typewritermc.loader.FIXTURE_VERSION
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.comparables.shouldBeGreaterThanOrEqualTo
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.RolloutCommandKind
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource

val CoordinatedRolloutTest by testSuite {
    test("a combined host is staged and committed once, as one participant") {
        runTest {
            val fixture = RolloutFixture(FakeRolloutHost(ServiceId("combined")))

            fixture.rollout.rollOut(fixture.snapshot)

            fixture.state.committed()?.snapshot shouldBe fixture.snapshot
            fixture.host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            fixture.host.commands.forEach { it.command.serviceIds shouldBe setOf("combined") }
        }
    }

    test("a host may take longer than a status request to apply a command") {
        runTest {
            val fixture = RolloutFixture(FakeRolloutHost(ServiceId("combined")).apply { commandDuration = 6.seconds })

            fixture.rollout.rollOut(fixture.snapshot)

            fixture.state.committed()?.snapshot shouldBe fixture.snapshot
        }
    }

    test("reconciling a commit stages and commits it again on a host that lost its projection") {
        runTest {
            val fixture = RolloutFixture(FakeRolloutHost(ServiceId("combined")))
            fixture.rollout.rollOut(fixture.snapshot)
            val committed = requireNotNull(fixture.state.committed())
            fixture.host.commands.clear()
            fixture.host.activeProjection = null

            fixture.rollout.reconcileCommitted(committed)

            fixture.host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            fixture.state.committed() shouldBe committed
        }
    }

    listOf(false, true).forEach { reconciling ->
        val operation = if (reconciling) "reconciling a commit" else "a new rollout"
        test("a rejected commit during $operation rolls the host back to nothing and keeps the previous commit") {
            runTest {
                val fixture = RolloutFixture(FakeRolloutHost(ServiceId("combined")))
                fixture.rollout.rollOut(fixture.snapshot)
                val committed = requireNotNull(fixture.state.committed())
                fixture.host.commands.clear()
                fixture.host.activeProjection = null
                fixture.host.rejectCommits = true

                shouldThrow<IllegalArgumentException> {
                    if (reconciling) fixture.rollout.reconcileCommitted(committed) else fixture.rollout.rollOut(fixture.snapshot)
                }.message shouldBe "A rollout participant rejected the command."

                val rollback =
                    fixture.host.commands
                        .last()
                        .command as RolloutCommand.RollBackWrapper
                rollback.value.participants
                    .findByKey("combined")
                    ?.target shouldBe RollbackTarget.EMPTY
                fixture.host.status?.phase shouldBe ParticipantPhase.IDLE
                fixture.state.committed() shouldBe committed
            }
        }
    }

    test("a Realm and panel host rolls out without any primary engine host") {
        runTest {
            val host = FakeRolloutHost(ServiceId("realm-service"), REALM_AND_PANEL)
            val selection = requireNotNull(listOf(presence(host.id, REALM_AND_PANEL)).deploymentSelectionOrNull())
            val fixture = RolloutFixture(host, selection)

            fixture.rollout.rollOut(fixture.snapshot)

            fixture.rollsOutTheRealmAndPanelOnly()
        }
    }

    test("a selected primary engine host that never answers does not block the Realm host") {
        runTest {
            val host = FakeRolloutHost(ServiceId("realm-service"), REALM_AND_PANEL)
            val observed = requireNotNull(listOf(presence(host.id, REALM_AND_PANEL)).deploymentSelectionOrNull())
            val absentEngine = ServiceId("absent-engine")
            val selection =
                observed.copy(
                    primaryEngineServices = setOf(absentEngine),
                    serviceApis = observed.serviceApis + (absentEngine to FIXTURE_VERSION),
                )
            val fixture = RolloutFixture(host, selection)

            fixture.rollout.rollOut(fixture.snapshot)

            fixture.rollsOutTheRealmAndPanelOnly()
        }
    }

    test("a rollout whose Realm host stopped answering sends nothing and keeps the previous commit") {
        runTest {
            val host = FakeRolloutHost(ServiceId("realm-service"), REALM_AND_PANEL)
            val selection = requireNotNull(listOf(presence(host.id, REALM_AND_PANEL)).deploymentSelectionOrNull())
            val fixture = RolloutFixture(host, selection)
            fixture.rollout.rollOut(fixture.snapshot)
            val committed = fixture.state.committed()
            host.commands.clear()
            host.responding = false

            shouldThrow<IllegalArgumentException> { fixture.rollout.rollOut(fixture.snapshot) }

            host.commands.shouldBeEmpty()
            fixture.state.committed() shouldBe committed
        }
    }

    test("a missing status reply restarts the healthy interval a commit must wait for") {
        runTest {
            val timeSource = TestTimeSource()
            val start = timeSource.markNow()
            val healthy = mutableListOf<Duration>()
            var activeReplies = 0
            var gapAt: Duration? = null
            val host =
                FakeRolloutHost(ServiceId("combined")).apply {
                    answersStatus = { status ->
                        if (status.phase !is ParticipantPhase.ActiveWrapper) {
                            true
                        } else {
                            timeSource += STATUS_POLL
                            activeReplies++
                            // The second reply after the commit goes missing; every other one reports healthy.
                            val answered = activeReplies != 2
                            if (answered) healthy += start.elapsedNow() else gapAt = start.elapsedNow()
                            answered
                        }
                    }
                }
            val fixture =
                RolloutFixture(host, participantDeadline = 2.seconds, healthyDuration = HEALTHY_DURATION, timeSource = timeSource)

            fixture.rollout.rollOut(fixture.snapshot)

            fixture.state.committed()?.snapshot shouldBe fixture.snapshot
            val firstHealthyAfterGap = healthy.first { it > requireNotNull(gapAt) }
            (healthy.last() - firstHealthyAfterGap) shouldBeGreaterThanOrEqualTo HEALTHY_DURATION
        }
    }
}

private val REALM_AND_PANEL = setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)
private val STATUS_POLL = 100.milliseconds
private val HEALTHY_DURATION = 150.milliseconds

private suspend fun RolloutFixture.rollsOutTheRealmAndPanelOnly() {
    val committed = requireNotNull(state.committed())
    val reference = host.commands.first().projectionFor(host.id)
    committed.projections shouldBe mapOf(host.id to reference.blob.toApi())
    host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
    host.commands.forEach { it.command.serviceIds shouldBe setOf(host.id.value) }
    projections.fetch(reference).runtimes.map { it.placement } shouldContainExactly
        listOf(RuntimePlacement.PANEL_ENGINE, RuntimePlacement.REALM)
}
