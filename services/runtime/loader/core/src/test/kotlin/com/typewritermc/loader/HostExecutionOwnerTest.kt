package com.typewritermc.loader

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.rollout.ArtifactHostAssignment
import com.typewritermc.loader.rollout.DesiredHostExecution
import com.typewritermc.loader.rollout.ExecutionRevision
import com.typewritermc.loader.rollout.HostAssignmentRuntime
import com.typewritermc.loader.rollout.HostExecutionObservation
import com.typewritermc.loader.rollout.HostExecutionOwner
import com.typewritermc.loader.rollout.ParticipantStatus
import com.typewritermc.loader.rollout.RealmId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val HostExecutionOwnerTest by testSuite {
    test("initial empty and consecutive empty revisions are reported without runtime creation") {
        val owner = HostExecutionOwner { error("Empty intent cannot create a runtime") }
        val reports = mutableListOf<HostExecutionObservation>()
        for (revision in listOf(4L, 5L)) {
            val desired = desired(revision, null)
            owner.apply(desired, null)
            owner.report(desired, 1L, reports::add)
            owner.report(desired, 1L, reports::add)
        }
        reports.map { it.revision.value } shouldBe listOf(4L, 5L)
        reports.map { it.roles } shouldBe listOf(emptySet(), emptySet())
        owner.hasRuntime shouldBe false
    }

    test("failed removal retains resources and cannot report completion before cleanup succeeds") {
        val runtime = TestRuntime(assignment)
        val owner = HostExecutionOwner { runtime }
        val removal = desired(2, null)
        val reports = mutableListOf<HostExecutionObservation>()
        owner.apply(desired(1, assignment), null)
        runtime.failClose = true
        shouldThrow<IllegalStateException> { owner.apply(removal, null) }
        owner.report(removal, 1L, reports::add)
        owner.hasRuntime shouldBe true
        reports shouldBe emptyList()
        runtime.failClose = false
        owner.apply(removal, null)
        owner.report(removal, 1L, reports::add)
        runtime.closeCalls shouldBe 2
        owner.hasRuntime shouldBe false
        reports.single().revision.value shouldBe 2
    }

    test("failed delivery retries on reconnect without reopening or repeating completed cleanup") {
        val runtime = TestRuntime(assignment)
        val owner = HostExecutionOwner { runtime }
        val removal = desired(2, null)
        owner.apply(desired(1, assignment), null)
        owner.apply(removal, null)
        owner.report(removal, null) { error("Disconnected host cannot send") }
        shouldThrow<IllegalStateException> { owner.report(removal, 1L) { error("Transport unavailable") } }
        val reports = mutableListOf<HostExecutionObservation>()
        owner.report(removal, 2L, reports::add)
        owner.report(removal, 2L, reports::add)
        runtime.closeCalls shouldBe 1
        reports.size shouldBe 1
    }

    test("new desired revision supersedes failed delivery of an older revision") {
        val owner = HostExecutionOwner { TestRuntime(it) }
        val old = desired(1, null)
        owner.apply(old, null)
        shouldThrow<IllegalStateException> { owner.report(old, 1L) { error("Offline") } }
        val newest = desired(2, null)
        owner.apply(newest, null)
        val reports = mutableListOf<HostExecutionObservation>()
        owner.report(old, 1L, reports::add)
        owner.report(newest, 1L, reports::add)
        reports.map { it.revision.value } shouldBe listOf(2L)
    }

    test("returning to prior intent after failed removal retries cleanup before acknowledging") {
        val runtimes = mutableListOf<TestRuntime>()
        val owner = HostExecutionOwner { TestRuntime(it).also(runtimes::add) }
        val original = desired(1, assignment)
        owner.apply(original, null)
        runtimes.single().failClose = true
        shouldThrow<IllegalStateException> { owner.apply(desired(2, null), null) }
        owner.isApplied(original) shouldBe false
        runtimes.single().failClose = false
        owner.apply(original, null)
        runtimes.size shouldBe 2
        owner.isApplied(original) shouldBe true
    }

    test("standalone assignments never produce backend reports") {
        val owner = HostExecutionOwner { TestRuntime(it) }
        val local = DesiredHostExecution(null, assignment)
        owner.apply(local, null)
        owner.report(local, 1L) { error("Standalone mode must not report") }
        owner.isApplied(local) shouldBe true
    }
}

private val assignment = ArtifactHostAssignment(RealmId("realm"), setOf(RuntimePlacement.PRIMARY_ENGINE))

private fun desired(
    revision: Long,
    assignment: ArtifactHostAssignment?,
) = DesiredHostExecution(ExecutionRevision("service", revision), assignment)

private class TestRuntime(
    override val assignment: ArtifactHostAssignment,
) : HostAssignmentRuntime {
    override val status: ParticipantStatus? = null
    var failClose = false
    var closeCalls = 0

    override suspend fun replaceSession(session: HostedMessagingSession?) = Unit

    override suspend fun close() {
        closeCalls++
        check(!failClose) { "Runtime shutdown failed" }
    }
}
