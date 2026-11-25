package com.typewritermc.engine.session

import com.typewritermc.engine.session.testing.SessionHarness
import com.typewritermc.identity.EngineId
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds

/**
 * Sessions through a real nats-server and the client production uses, end to end. Keys live minutes, so whatever must
 * still be there is; what must end is waited for with a bound far above the vacancy. Every ordering and timing rule is
 * proven on virtual time in LeasesTest and SessionKeeperTest.
 */
val SessionsOnNatsTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val harness = testFixture { SessionHarness.start() }
    val timings = LeaseTimings(refresh = 1.seconds, ttl = 5.minutes, vacancy = 1.seconds, retry = 100.milliseconds)

    test("SESSION-NATS a session is taken, moved to another engine and ended after the vacancy through the broker") {
        harness().createBucket()
        val old = harness().engine("engine-a", timings)
        val new = harness().engine("engine-b", timings)
        val (protagonist, session) = harness().player()

        harness().joined(old, protagonist, session)
        val began = harness().entry(protagonist, session).shouldNotBeNull().since
        harness().joined(new, protagonist, session)
        harness().eventually { !old.keeper.holds(protagonist) }
        old.keeper.disconnected(session)

        harness().entry(protagonist, session).shouldNotBeNull().since shouldBe began
        new.keeper.holders(protagonist) shouldBe setOf(EngineId("engine-b"))

        new.keeper.disconnected(session)
        harness().eventually(within = timings.vacancy + 30.seconds) { harness().entry(protagonist, session) == null }
    }
}
