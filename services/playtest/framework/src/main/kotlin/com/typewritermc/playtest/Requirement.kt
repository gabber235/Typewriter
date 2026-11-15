package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import de.infix.testBalloon.framework.core.TestCompartment
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.invocation
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering

/** What a requirement's case demonstrates: the path it exists for, a failure it reports, or an edge it holds at. */
typealias Demonstrates = Message.Demonstrates

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
 * test JVM once the pool has [players] free, each wiped and standing in a region of the world that is
 * the attempt's own. A failed attempt goes to the end of the pool's line and runs again on warm
 * clients, up to 4 attempts in total; a pass after a failure is flaky and fails the test like a
 * failure. [demonstrates] says what the case shows, in the run file. With [restartsPaper] the attempt
 * runs on a Paper of its own, which the body may kill and boot again with
 * [RequirementScope.restartPaper]; the shared Paper and every other attempt never notice.
 */
@TestRegistering
fun TestSuiteScope.requirement(
    @TestElementName id: String,
    sentence: String,
    players: Int = 1,
    demonstrates: Demonstrates = Demonstrates.HAPPY_PATH,
    restartsPaper: Boolean = false,
    body: suspend RequirementScope.() -> Unit,
) = attempts(id, sentence, players, demonstrates, listOf(body), restartsPaper)

/**
 * Registers one requirement whose attempt runs [bodies] in order; before each body after the first the
 * pool releases and claims the same players again, as the next attempt would get them. Only the
 * framework's own test kit runs more than one body, to prove the wipe.
 */
@TestRegistering
internal fun TestSuiteScope.attempts(
    @TestElementName id: String,
    sentence: String,
    players: Int,
    demonstrates: Demonstrates,
    bodies: List<suspend RequirementScope.() -> Unit>,
    restartsPaper: Boolean = false,
) {
    require(players >= 1) { "$id claims $players players; a requirement claims at least 1" }
    register(id, sentence, RequirementCode.of(bodies.first())) { session ->
        session.attempt(PoolSession.Planned("$id $sentence", id, players, demonstrates, bodies, restartsPaper))
    }
}

/**
 * Registers one requirement whose bodies, made afresh for each attempt by [bodies], run side by side,
 * each as an attempt of its own on one player, reported as cases of their own: the pool claims and
 * leases their players at the same moment. Once all ended, [afterward] runs as one more attempt on
 * [afterwardPlayers]. Only the framework's own test kit runs attempts side by side, to prove what one
 * attempt does never changes another's verdict.
 */
@TestRegistering
internal fun TestSuiteScope.sideBySide(
    @TestElementName id: String,
    sentence: String,
    demonstrates: Demonstrates,
    bodies: () -> List<suspend RequirementScope.() -> Unit>,
    afterwardPlayers: Int = 1,
    afterward: (suspend RequirementScope.() -> Unit)? = null,
) {
    register(id, sentence, RequirementCode.of(bodies)) { session ->
        val made = bodies()
        val count = made.size + if (afterward == null) 0 else 1
        val failures =
            session
                .sideBySide(
                    made.mapIndexed { index, body ->
                        PoolSession.Planned("$id $sentence (attempt ${index + 1} of $count)", id, 1, demonstrates, listOf(body))
                    },
                ).filterNotNull()
        failures.firstOrNull()?.let { first -> first.also { failures.drop(1).forEach(it::addSuppressed) } }
            ?: afterward?.let {
                session.attempt(
                    PoolSession.Planned("$id $sentence (attempt $count of $count)", id, afterwardPlayers, demonstrates, listOf(it)),
                )
            }
    }
}

/**
 * Registers the test "[id] [sentence]": it makes the requirement's attempts as the run's policy asks,
 * each with [attempt], which returns why it failed or null, and ends as their verdict says. Which tests
 * a run runs is testBalloon's selection (`cargo xtask e2e game --only`).
 */
private fun TestSuiteScope.register(
    id: String,
    sentence: String,
    code: RequirementCode,
    attempt: suspend (PoolSession) -> Throwable?,
) {
    val plan = RunPlan.current
    val testId = "$id $sentence"
    test(testId) {
        val session = session(id)
        plan.policy.attempt(plan.quarantines(id, testId)) { attempt(session) }.conclude(code)
    }
}

private fun session(id: String): PoolSession =
    checkNotNull(
        currentSession,
    ) { "$id is not in the GameCompartment: register requirements in testSuite(compartment = { GameCompartment })" }.getOrThrow()
