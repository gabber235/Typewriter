package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope

/**
 * [player]'s work [name] runs off Paper's main thread for [millis] of wall clock, counted as any plugin
 * counts its work, then sends [then] as a chat line.
 */
suspend fun RequirementScope.work(
    player: GamePlayer,
    name: String,
    millis: Int,
    then: String,
): Mark = probe.work(player, name, millis, then)

/**
 * Registers a requirement of the framework's own test kit that runs [busy] and [other] side by side, each
 * as an attempt of its own on a player of its own, leased at the same moment; once both ended,
 * [afterward] runs as one more attempt on [afterwardPlayers]. [other] completes the deferred it gets
 * once its window waits for ticks, see [cueOnceOpen]; [busy] awaits it, so what [busy] does next happens
 * while that window runs.
 */
@TestRegistering
fun TestSuiteScope.alongside(
    @TestElementName id: String,
    sentence: String,
    busy: suspend RequirementScope.(otherWaits: Deferred<Unit>) -> Unit,
    other: suspend RequirementScope.(waiting: CompletableDeferred<Unit>) -> Unit,
    afterwardPlayers: Int = 1,
    afterward: (suspend RequirementScope.() -> Unit)? = null,
) {
    val waiting = CompletableDeferred<Unit>()
    sideBySide(id, sentence, listOf({ busy(waiting) }, { other(waiting) }), afterwardPlayers, afterward)
}

/**
 * Runs [window], a `within`, and completes [waiting] as soon as the window asked Paper for its ticks,
 * before any of them ran; returns what [window] returns.
 */
suspend fun <T> cueOnceOpen(
    waiting: CompletableDeferred<Unit>,
    window: suspend () -> T,
): T =
    coroutineScope {
        // Undispatched, the window sends its step request before the first suspension, so before the cue.
        val verdict = async(start = CoroutineStart.UNDISPATCHED) { window() }
        waiting.complete(Unit)
        verdict.await()
    }
