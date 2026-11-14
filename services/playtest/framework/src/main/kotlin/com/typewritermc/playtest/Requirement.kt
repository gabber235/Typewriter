package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.TestCompartment
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.invocation
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.supervisorScope

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
 * the attempt's own.
 */
@TestRegistering
fun TestSuiteScope.requirement(
    @TestElementName id: String,
    sentence: String,
    players: Int = 1,
    body: suspend RequirementScope.() -> Unit,
) = attempts(id, sentence, players, listOf(body))

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
    bodies: List<suspend RequirementScope.() -> Unit>,
) {
    require(players >= 1) { "$id claims $players players; a requirement claims at least 1" }
    test("$id $sentence") {
        session(id).attempt(testId = "$id $sentence", requirement = id, players = players, bodies = bodies)
    }
}

/**
 * Registers one requirement whose [bodies] run at the same time, each as an attempt of its own on one
 * player, reported as cases of their own; once all ended, [afterward] runs as one more attempt on
 * [afterwardPlayers]. Only the framework's own test kit runs attempts side by side, to prove what one
 * attempt does never changes another's verdict.
 */
@TestRegistering
internal fun TestSuiteScope.sideBySide(
    @TestElementName id: String,
    sentence: String,
    bodies: List<suspend RequirementScope.() -> Unit>,
    afterwardPlayers: Int = 1,
    afterward: (suspend RequirementScope.() -> Unit)? = null,
) {
    val count = bodies.size + if (afterward == null) 0 else 1
    test("$id $sentence") {
        val session = session(id)
        // Every attempt runs to its own end, so one failing never cancels the others' verdicts.
        val failures =
            supervisorScope {
                bodies
                    .mapIndexed { index, body ->
                        async {
                            runCatching {
                                session.attempt("$id $sentence (attempt ${index + 1} of $count)", id, players = 1, bodies = listOf(body))
                            }.exceptionOrNull()
                        }
                    }.awaitAll()
                    .filterNotNull()
            }
        failures.firstOrNull()?.let { first -> throw first.also { failures.drop(1).forEach(it::addSuppressed) } }
        afterward?.let { session.attempt("$id $sentence (attempt $count of $count)", id, afterwardPlayers, listOf(it)) }
    }
}

private fun session(id: String): PoolSession =
    checkNotNull(
        currentSession,
    ) { "$id is not in the GameCompartment: register requirements in testSuite(compartment = { GameCompartment })" }.getOrThrow()
