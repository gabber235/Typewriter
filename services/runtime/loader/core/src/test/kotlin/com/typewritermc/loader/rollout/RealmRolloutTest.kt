package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.rollout.testing.RealmRolloutFixture
import com.typewritermc.loader.rollout.testing.deploymentContent
import com.typewritermc.loader.rollout.testing.projectionFor
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
import skirout.service.v1.rollout.RolloutCommandKind
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

val RealmRolloutTest by testSuite {
    val realmAndPanel = setOf(RuntimePlacement.REALM, RuntimePlacement.PANEL_ENGINE)
    val engine = setOf(RuntimePlacement.PRIMARY_ENGINE)
    val engineStopped = RuntimeHealth.Unhealthy("engine stopped")

    test("a combined host is staged and committed once, as one participant") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("combined")
            fixture.start()

            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
            host.commands.forEach { it.command.serviceIds shouldBe setOf("combined") }
            fixture.runsCommitted(host) shouldBe true
        }
    }

    test("a host may take longer than a status request to apply a command") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            fixture.host("combined").commandDuration = 6.seconds
            fixture.start()

            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
        }
    }

    test("a Realm and panel host rolls out without any primary engine host") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("realm-service", realmAndPanel)
            fixture.start()

            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            val reference = host.commands.first().projectionFor(host.id)
            fixture.state.committed()?.projections shouldBe mapOf(host.id to reference)
            fixture.projections
                .fetch(reference)
                .runtimes
                .map { it.placement } shouldContainExactly
                listOf(RuntimePlacement.PANEL_ENGINE, RuntimePlacement.REALM)
        }
    }

    test("a host that lost its projection gets the committed one back") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("combined")
            fixture.start()
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
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("combined").apply { answersStatus = { replying } }
            fixture.start()
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
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("combined")
            fixture.start()
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.health = engineStopped

            fixture.until(10.seconds) { host.commandKinds.count { it == RolloutCommandKind.STAGE } == 2 }.shouldNotBeNull()
        }
    }

    test("a refused commit keeps the previous commit and leaves the host on it") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("combined")
            fixture.start()
            fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            host.failsActivation = true
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
            val fixture = RealmRolloutFixture(this)
            val host = fixture.host("realm-service", realmAndPanel)
            fixture.start()
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
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val leaver =
                fixture.host("paper", engine).apply {
                    // The Paper server goes down as soon as it runs the new projection.
                    answersStatus = { status ->
                        responding = status.phase !is ParticipantPhase.ActiveWrapper
                        responding
                    }
                }
            fixture.start()

            val committedAt = fixture.until(2.minutes) { fixture.committedGeneration() == 1L }

            committedAt.shouldNotBeNull() shouldBeLessThan 1.minutes
            fixture.runsCommitted(realmHost) shouldBe true
            realmHost.switches.size shouldBe 1

            leaver.answersStatus = { true }
            leaver.restart()
            leaver.responding = true

            fixture.until(1.minutes) { fixture.runsCommitted(leaver) }.shouldNotBeNull()
        }
    }

    test("a host that misses one presence probe while it proves a candidate keeps its proof") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            fixture.host("realm-service", realmAndPanel)
            val paper = fixture.host("paper", engine)
            fixture.start()
            fixture.until(1.minutes) { paper.generation == 1L }.shouldNotBeNull()
            fixture.wait(20.seconds)

            var missed = false
            paper.answersProbe = { missed.also { missed = true } }
            val missedAt = fixture.elapsed
            val committedAt = fixture.until(1.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            (committedAt - missedAt) shouldBeLessThan 20.seconds
        }
    }

    test("a host that joins while a candidate is proved runs the candidate and must prove it before the commit") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val joiner = fixture.host("paper", engine).apply { responding = false }
            fixture.start()
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

    test("a host that left with the candidate staged commits it when it returns after the commit") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            fixture.host("realm-service", realmAndPanel)
            val paper =
                fixture.host("paper", engine).apply {
                    // The Paper server loses its connection as soon as it staged the candidate.
                    answersStatus = { status ->
                        responding = status.phase !is ParticipantPhase.StagedWrapper
                        responding
                    }
                }
            fixture.start()
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            paper.isStaged() shouldBe true

            paper.answersStatus = { true }
            paper.responding = true

            fixture.until(1.minutes) { fixture.runsCommitted(paper) }.shouldNotBeNull()
            paper.commandKinds shouldContainExactly listOf(RolloutCommandKind.STAGE, RolloutCommandKind.COMMIT)
        }
    }

    test("a Realm host that restarts while a Paper is staged commits the candidate without aborting the Paper") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel).apply { commandDuration = 1.minutes }
            val paper = fixture.host("paper", engine)
            fixture.start()
            fixture.until(30.seconds) { paper.isStaged() }.shouldNotBeNull()

            realmHost.commandDuration = Duration.ZERO
            fixture.restartRealm(realmHost)

            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            paper.commandKinds shouldNotContain RolloutCommandKind.ABORT
            paper.switches.size shouldBe 1
            fixture.runsCommitted(paper) shouldBe true
        }
    }

    test("after a Realm host restart, a host that lost its projection gets it back although the artifacts were withdrawn") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val paper = fixture.host("paper", engine)
            fixture.start()
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            fixture.contents.withdraw(fixture.contents.content)
            fixture.restartRealm(realmHost)
            paper.restart()

            fixture.until(30.seconds) { fixture.runsCommitted(realmHost) && fixture.runsCommitted(paper) }.shouldNotBeNull()
            fixture.committedGeneration() shouldBe 1L
        }
    }

    test("a failed candidate rolls the present hosts back to their recorded projections once the committed artifacts are withdrawn") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val failing = fixture.host("paper", engine)
            fixture.start()
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()
            val committed = fixture.contents.content

            fixture.contents.content = deploymentContent("paper-2")
            fixture.until(1.minutes) { realmHost.generation == 2L && failing.generation == 2L }.shouldNotBeNull()
            fixture.contents.withdraw(committed)
            failing.health = engineStopped

            fixture.until(6.minutes) { fixture.runsCommitted(realmHost) && fixture.runsCommitted(failing) }.shouldNotBeNull()
            fixture.committedGeneration() shouldBe 1L
        }
    }

    test("a returning host gets the committed projection while another host is still being repaired") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            fixture.host("realm-service", realmAndPanel)
            val slow = fixture.host("paper-a", engine)
            val returning = fixture.host("paper-b", engine)
            fixture.start()
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
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val paper = fixture.host("paper", engine)
            fixture.start()
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            paper.failsStaging = true
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
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val failing = fixture.host("paper-a", engine)
            val leaver = fixture.host("paper-b", engine)
            fixture.start()
            fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            fixture.contents.content = deploymentContent("paper-2")
            fixture.until(1.minutes) { listOf(realmHost, failing, leaver).all { it.generation == 2L } }.shouldNotBeNull()
            failing.health = engineStopped
            leaver.responding = false

            fixture.until(6.minutes) { realmHost.generation == 1L && failing.generation == 1L }.shouldNotBeNull()

            fixture.committedGeneration() shouldBe 1L
            leaver.commandKinds shouldNotContain RolloutCommandKind.ROLL_BACK
            leaver.generation shouldBe 2L
        }
    }

    test("each member has five minutes from joining a candidate to run it healthy") {
        runTest {
            val fixture = RealmRolloutFixture(this)
            val realmHost = fixture.host("realm-service", realmAndPanel)
            val slow = fixture.host("paper-a", engine).apply { commandDuration = 3.minutes }
            val unhealthy =
                fixture.host("paper-b", engine).apply {
                    responding = false
                    health = engineStopped
                }
            fixture.start()
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
            val fixture = RealmRolloutFixture(this)
            val healthy = mutableListOf<Duration>()
            var activeReplies = 0
            var gapAt: Duration? = null
            fixture.host("combined").answersStatus = { status ->
                if (status.phase !is ParticipantPhase.ActiveWrapper) {
                    true
                } else {
                    val now = fixture.elapsed
                    activeReplies++
                    // The fifth reply after the commit goes missing; every other one reports healthy.
                    val answered = activeReplies != 5
                    if (answered) healthy += now else gapAt = now
                    answered
                }
            }
            fixture.start()

            val committedAt = fixture.until(2.minutes) { fixture.committedGeneration() == 1L }.shouldNotBeNull()

            val firstHealthyAfterGap = healthy.first { it > requireNotNull(gapAt) }
            (committedAt - firstHealthyAfterGap) shouldBeGreaterThanOrEqualTo 30.seconds
        }
    }
}
