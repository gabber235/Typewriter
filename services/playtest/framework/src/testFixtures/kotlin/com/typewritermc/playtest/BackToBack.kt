package com.typewritermc.playtest

import com.typewritermc.playtest.wire.variantName
import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.wire.PlayerClaim
import skirout.harness.v1.wire.StateKind

/**
 * Registers a requirement of the framework's own test kit that runs [first] and then [then] on the same
 * [players]: between the two the pool releases and claims them again exactly as the next attempt would
 * get them, wiped and in a new region. What [first] leaves behind and [then] still finds is a leak.
 */
@TestRegistering
fun TestSuiteScope.backToBack(
    @TestElementName id: String,
    sentence: String,
    players: PlayerClaim = Players.count(1),
    demonstrates: Demonstrates = Demonstrates.HAPPY_PATH,
    first: suspend RequirementScope.() -> Unit,
    then: suspend RequirementScope.() -> Unit,
) = attempts(id, sentence, players, demonstrates, listOf(first, then))

/** [player] carries a mark of [kind], as an earlier attempt could leave it. */
suspend fun RequirementScope.mark(
    player: GamePlayer,
    kind: StateKind,
): Mark = probe.mark(player, kind)

/** [player] carries a mark of [kind], as Paper sees it: the positive check for kinds no player can see. */
suspend fun RequirementScope.holds(
    player: GamePlayer,
    kind: StateKind,
) = checkMarks(player, kind, held = true)

/** [player] carries no mark of [kind], as Paper sees it: the positive check that a wipe took it. */
suspend fun RequirementScope.lacks(
    player: GamePlayer,
    kind: StateKind,
) = checkMarks(player, kind, held = false)

private suspend fun RequirementScope.checkMarks(
    player: GamePlayer,
    kind: StateKind,
    held: Boolean,
) {
    val marks = attempt.query(player)
    val name = variantName(StateKind.typeDescriptor, kind)
    if ((kind in marks) != held) {
        val carried = marks.joinToString { variantName(StateKind.typeDescriptor, it) }.ifEmpty { "none" }
        throw AssertionError("${player.name} ${if (held) "carries no" else "still carries a"} mark of $name; Paper sees: $carried")
    }
    attempt.proved = true
}
