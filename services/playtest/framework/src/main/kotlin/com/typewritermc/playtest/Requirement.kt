package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.TestCompartment
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.invocation
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering

/**
 * The compartment every game requirement registers in. Its tests start at once and each waits in the
 * pool for its players; one pool session serves the whole test JVM and, once every test finished,
 * has the pool write the run's `TestRun`.
 */
object GameCompartment : TestCompartment(
    name = "Game",
    testConfig =
        TestConfig
            .invocation(TestConfig.Invocation.Concurrent)
            .aroundAll { all ->
                // testBalloon drops a compartment's own failure, so a session that cannot open fails
                // every requirement instead, each with the reason.
                val session = runCatching { PoolSession.open() }
                currentSession = session
                all()
                session.getOrNull()?.end()
            },
)

/** The test JVM's pool session, once the [GameCompartment] opened it. */
@Volatile
private var currentSession: Result<PoolSession>? = null

/**
 * Registers one requirement as one testBalloon test named "[id] [sentence]". Its body runs in this
 * test JVM on a leased player once the pool has one free.
 */
@TestRegistering
fun TestSuiteScope.requirement(
    @TestElementName id: String,
    sentence: String,
    body: suspend RequirementScope.() -> Unit,
) {
    test("$id $sentence") {
        val session =
            checkNotNull(
                currentSession,
            ) { "$id is not in the GameCompartment: register requirements in testSuite(compartment = { GameCompartment })" }
        session.getOrThrow().attempt(testId = "$id $sentence", requirement = id, body = body)
    }
}
