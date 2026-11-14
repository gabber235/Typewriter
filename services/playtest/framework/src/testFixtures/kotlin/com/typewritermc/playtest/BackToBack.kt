package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Kind
import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering

/**
 * Registers a requirement of the framework's own test kit that runs [first] and then [then] on the same
 * [players]: between the two the pool releases and claims them again exactly as the next attempt would
 * get them, wiped and in a new region. What [first] leaves behind and [then] still finds is a leak.
 */
@TestRegistering
fun TestSuiteScope.backToBack(
    @TestElementName id: String,
    sentence: String,
    players: Int = 1,
    first: suspend RequirementScope.() -> Unit,
    then: suspend RequirementScope.() -> Unit,
) = attempts(id, sentence, players, listOf(first, then))

/** [player] carries a mark of [kind], as an earlier attempt could leave it. */
suspend fun RequirementScope.mark(
    player: GamePlayer,
    kind: Kind,
): Mark = probe.mark(player, kind)

/** The kinds of state [player] carries a mark of, as Paper sees them: the proof for kinds no player can see. */
suspend fun RequirementScope.marks(player: GamePlayer): List<Kind> = attempt.query(player)
