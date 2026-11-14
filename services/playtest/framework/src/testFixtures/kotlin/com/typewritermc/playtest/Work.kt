package com.typewritermc.playtest

import de.infix.testBalloon.framework.core.TestSuiteScope
import de.infix.testBalloon.framework.shared.TestElementName
import de.infix.testBalloon.framework.shared.TestRegistering
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import java.nio.file.Path

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
 * Registers a requirement of the framework's own test kit that runs [busy] and [other] at the same time,
 * each as an attempt of its own on a player of its own; once both ended, [afterward] runs as one more
 * attempt on [afterwardPlayers]. [other] starts only once [busy] holds its lease, and completes the
 * deferred it gets once its window waits for ticks, see [cueOnceOpen]; [busy] awaits it, so what [busy]
 * does next happens while that window runs.
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
    val busyLeased = CompletableDeferred<Unit>()
    val waiting = CompletableDeferred<Unit>()
    // The pool may lease the two attempts at different times; the cues hold only while both run.
    val bodies: List<suspend RequirementScope.() -> Unit> =
        listOf(
            {
                busyLeased.complete(Unit)
                busy(waiting)
            },
            {
                busyLeased.await()
                other(waiting)
            },
        )
    sideBySide(id, sentence, bodies, afterwardPlayers, afterward)
}

/** Ends [player]'s client process at once, as a crash would; the pool notices and replaces the client. */
fun RequirementScope.crashClient(player: GamePlayer) {
    val gameDir = PlaytestSettings.fromSystemProperties().poolDir.resolve("client-${player.name}")
    val client =
        ProcessHandle.allProcesses().toList().firstOrNull { process ->
            val arguments =
                process
                    .info()
                    .arguments()
                    .orElse(arrayOf())
                    .toList()
            arguments.zipWithNext().any { (flag, value) -> flag == "--gameDir" && Path.of(value) == gameDir }
        }
    checkNotNull(client) { "no client process plays ${player.name} in $gameDir" }.destroyForcibly()
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
