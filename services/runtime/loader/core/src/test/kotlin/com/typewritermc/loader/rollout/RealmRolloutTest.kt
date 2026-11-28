package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.rollout.testing.FakeRolloutHost
import com.typewritermc.loader.rollout.testing.RealmRolloutFixture
import com.typewritermc.loader.rollout.testing.deploymentContent
import com.typewritermc.loader.rollout.testing.projectionFor
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.comparables.shouldBeGreaterThanOrEqualTo
import io.kotest.matchers.comparables.shouldBeLessThan
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.RolloutCommandKind
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

val RealmRolloutTest by testSuite {
    val realmAndPanel = setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)
    val engine = setOf(RuntimePlacement.PRIMARY_ENGINE)

    test("a combined host is staged and committed once, as one participant") {
        runTest {
            val host = FakeRolloutHost(ServiceId("combined"))
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }

            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            host.commands.forEach { it.command.serviceIds shouldBe setOf("combined") }
            fixture.runsCommitted(host) shouldBe true
        }
    }

    test("a host may take longer than a status request to apply a command") {
        runTest {
            val host = FakeRolloutHost(ServiceId("combined")).apply { commandDuration = 6.seconds }
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }

            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
        }
    }

    test("a Realm and panel host rolls out without any primary engine host") {
        runTest {
            val host = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }

            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            val reference = host.commands.first().projectionFor(host.id)
            fixture.state.committed()?.projections shouldBe mapOf(host.id to reference.blob.toApi())
            fixture.projections
                .fetch(reference)
                .runtimes
                .map { it.placement } shouldContainExactly
                listOf(RuntimePlacement.PANEL_ENGINE, RuntimePlacement.REALM)
        }
    }

    test("a host that lost its projection gets the committed one back") {
        runTest {
            val host = FakeRolloutHost(ServiceId("combined"))
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            val committed = fixture.state.committed()

            host.restart()

            fixture.until(10.seconds) { fixture.runsCommitted(host) }.shouldNotBeNull()
            fixture.state.committed() shouldBe committed
        }
    }

    test("a committed host whose status replies go missing keeps running without being staged again") {
        runTest {
            var replying = true
            val host = FakeRolloutHost(ServiceId("combined")).apply { answersStatus = { replying } }
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            fixture.wait(6.minutes)

            replying = false
            fixture.wait(10.seconds)
            replying = true
            fixture.wait(1.minutes)

            host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
        }
    }

    test("a committed host that reports its projection unhealthy is staged again") {
        runTest {
            val host = FakeRolloutHost(ServiceId("combined"))
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.health = ProjectionHealth.createUnhealthy(reasons = listOf("engine stopped"))

            fixture.until(10.seconds) { host.commandKinds.count { it == RolloutCommandKind.STAGE } == 2 }.shouldNotBeNull()
        }
    }

    test("a refused commit keeps the previous commit and leaves the host on it") {
        runTest {
            val host = FakeRolloutHost(ServiceId("combined"))
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.refuses = setOf(RolloutCommandKind.COMMIT)
            fixture.contents.content = deploymentContent("paper-2")
            fixture.wait(2.minutes)

            host.commandKinds.count { it == RolloutCommandKind.COMMIT } shouldBeGreaterThanOrEqualTo 2
            fixture.committedGeneration() shouldBe 1L
            host.switches.size shouldBe 1
            fixture.runsCommitted(host) shouldBe true
        }
    }

    test("a Realm whose host stopped answering sends nothing and keeps the previous commit") {
        runTest {
            val host = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            val committed = fixture.state.committed()
            host.commands.clear()

            host.responding = false
            fixture.contents.content = deploymentContent("paper-2")
            fixture.wait(2.minutes)

            host.commands shouldBe emptyList()
            fixture.state.committed() shouldBe committed
        }
    }

    test("a primary engine host that leaves while the rollout proves stability does not hold back the Realm host") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val leaver =
                FakeRolloutHost(ServiceId("paper"), engine).apply {
                    // The Paper server restarts as soon as it runs the new projection.
                    answersStatus = { status ->
                        responding = status.phase !is ParticipantPhase.ActiveWrapper
                        responding
                    }
                }
            val fixture = RealmRolloutFixture(this, listOf(realmHost, leaver)).apply { start() }

            val committedAt = fixture.until(2.minutes) { fixture.committedGeneration() == 1L }

            committedAt.shouldNotBeNull() shouldBeLessThan 1.minutes
            fixture.runsCommitted(realmHost) shouldBe true
            realmHost.switches.size shouldBe 1
        }
    }

    test("a host that joins while a candidate is proved runs the candidate and must prove it before the commit") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val joiner = FakeRolloutHost(ServiceId("paper"), engine).apply { responding = false }
            val fixture = RealmRolloutFixture(this, listOf(realmHost, joiner)).apply { start() }
            fixture.until(1.minutes) { realmHost.generation == 1L }.shouldNotBeNull()
            fixture.wait(10.seconds)

            joiner.responding = true
            val joinerActiveAt = fixture.until(1.minutes) { joiner.generation == 1L }.shouldNotBeNull()
            val committedAt = fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            (committedAt - joinerActiveAt) shouldBeGreaterThanOrEqualTo 30.seconds
            joiner.switches.size shouldBe 1
            fixture.runsCommitted(joiner) shouldBe true
        }
    }

    test("a returning host gets the committed projection while another host is still being repaired") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val slow = FakeRolloutHost(ServiceId("paper-a"), engine)
            val returning = FakeRolloutHost(ServiceId("paper-b"), engine)
            val fixture = RealmRolloutFixture(this, listOf(realmHost, slow, returning)).apply { start() }
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            slow.commandDuration = 4.minutes
            slow.restart()
            fixture.wait(5.seconds)
            returning.restart()
            val restartedAt = fixture.elapsed

            val runsAt = fixture.until(1.minutes) { fixture.runsCommitted(returning) }.shouldNotBeNull()
            (runsAt - restartedAt) shouldBeLessThan 15.seconds
            fixture.runsCommitted(slow) shouldBe false
        }
    }

    test("a candidate a host fails to stage is aborted without switching any running host") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val paper = FakeRolloutHost(ServiceId("paper"), engine)
            val fixture = RealmRolloutFixture(this, listOf(realmHost, paper)).apply { start() }
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            paper.refuses = setOf(RolloutCommandKind.STAGE)
            fixture.contents.content = deploymentContent("paper-2")
            fixture.until(1.minutes) { RolloutCommandKind.ABORT in realmHost.commandKinds }.shouldNotBeNull()
            fixture.wait(1.minutes)

            realmHost.switches.size shouldBe 1
            paper.switches.size shouldBe 1
            fixture.committedGeneration() shouldBe 1L
        }
    }

    test("a failed candidate is rolled back on the hosts still present and never sent to a host that left") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val failing = FakeRolloutHost(ServiceId("paper-a"), engine)
            val leaver = FakeRolloutHost(ServiceId("paper-b"), engine)
            val fixture = RealmRolloutFixture(this, listOf(realmHost, failing, leaver)).apply { start() }
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            fixture.contents.content = deploymentContent("paper-2")
            fixture.until(1.minutes) { listOf(realmHost, failing, leaver).all { it.generation == 2L } }.shouldNotBeNull()
            failing.health = ProjectionHealth.createUnhealthy(reasons = listOf("engine stopped"))
            leaver.responding = false

            fixture.until(6.minutes) { realmHost.generation == 1L && failing.generation == 1L }.shouldNotBeNull()

            fixture.committedGeneration() shouldBe 1L
            leaver.commandKinds shouldNotContain RolloutCommandKind.ROLL_BACK
            leaver.generation shouldBe 2L
        }
    }

    test("each member has five minutes from joining a candidate to run it healthy") {
        runTest {
            val realmHost = FakeRolloutHost(ServiceId("realm-service"), realmAndPanel)
            val slow = FakeRolloutHost(ServiceId("paper-a"), engine).apply { commandDuration = 3.minutes }
            val unhealthy =
                FakeRolloutHost(ServiceId("paper-b"), engine).apply {
                    responding = false
                    health = ProjectionHealth.createUnhealthy(reasons = listOf("engine stopped"))
                }
            val fixture = RealmRolloutFixture(this, listOf(realmHost, slow, unhealthy)).apply { start() }
            fixture.wait(1.minutes)
            // Only the first stage is slow: it keeps the candidate open until after the joiner arrives.
            slow.commandDuration = Duration.ZERO
            unhealthy.responding = true

            val revertedAt = fixture.until(10.minutes) { RolloutCommandKind.ROLL_BACK in realmHost.commandKinds }

            revertedAt.shouldNotBeNull() shouldBeGreaterThanOrEqualTo 6.minutes
            revertedAt shouldBeLessThan 6.minutes + 10.seconds
            fixture.committedGeneration().shouldBeNull()
        }
    }

    test("a missing status reply restarts the healthy interval a host must prove") {
        runTest {
            var fixture: RealmRolloutFixture? = null
            val healthy = mutableListOf<Duration>()
            var activeReplies = 0
            var gapAt: Duration? = null
            val host =
                FakeRolloutHost(ServiceId("combined")).apply {
                    answersStatus = { status ->
                        if (status.phase !is ParticipantPhase.ActiveWrapper) {
                            true
                        } else {
                            val now = requireNotNull(fixture).elapsed
                            activeReplies++
                            // The fifth reply after the commit goes missing; every other one reports healthy.
                            val answered = activeReplies != 5
                            if (answered) healthy += now else gapAt = now
                            answered
                        }
                    }
                }
            fixture = RealmRolloutFixture(this, listOf(host)).apply { start() }

            val committedAt = fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            val firstHealthyAfterGap = healthy.first { it > requireNotNull(gapAt) }
            (committedAt - firstHealthyAfterGap) shouldBeGreaterThanOrEqualTo 30.seconds
        }
    }
}
