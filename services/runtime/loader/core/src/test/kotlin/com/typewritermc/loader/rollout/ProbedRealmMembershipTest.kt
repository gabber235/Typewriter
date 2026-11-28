package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.rollout.testing.presence
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainExactly
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import skirout.service.v1.rollout.RealmHostPresence
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

val ProbedRealmMembershipTest by testSuite {
    val paper = presence(ServiceId("paper"), setOf(RuntimePlacement.PRIMARY_ENGINE))

    test("a host that falls silent stays a member for the grace and leaves after it") {
        runTest {
            var answering = listOf(paper)
            val membership = ProbedRealmMembership({ answering }, grace = 10.seconds, timeSource = testScheduler.timeSource)
            membership.members() shouldContainExactly listOf(paper)

            answering = emptyList<RealmHostPresence>()
            advanceTimeBy(10.seconds)
            membership.members() shouldContainExactly listOf(paper)

            advanceTimeBy(1.milliseconds)
            membership.members().shouldBeEmpty()
        }
    }

    test("every answer renews the lease of the host that gave it") {
        runTest {
            var answering = listOf(paper)
            val membership = ProbedRealmMembership({ answering }, grace = 10.seconds, timeSource = testScheduler.timeSource)
            membership.members()
            answering = emptyList()
            advanceTimeBy(8.seconds)
            answering = listOf(paper)
            membership.members()
            answering = emptyList()

            advanceTimeBy(8.seconds)

            membership.members() shouldContainExactly listOf(paper)
        }
    }
}
