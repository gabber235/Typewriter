package com.typewritermc.playtest

import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes

/**
 * Content an attempt owns: written for its claimed players before its body runs, and removed again
 * before they go back to the pool. Attempts side by side share one Paper and reuse players, so content
 * that outlives its attempt would reach the next one. [key] names what is written; today each attempt
 * writes a copy of its own.
 */
interface AttemptContent {
    /** What this content is, the same for every attempt that writes it. */
    val key: String

    /** Says when written content runs on Paper. */
    val liveness: ContentLiveness

    /** Writes the content for [players] and returns it as written, once the system under test accepted it. */
    suspend fun write(players: List<GamePlayer>): WrittenContent
}

/** Content one attempt wrote. */
interface WrittenContent {
    /** What Paper runs once this content is live. */
    val live: LiveContent

    /**
     * Writes the changed form the content's declaration names, in place of what it wrote, and returns
     * what Paper runs once the change is live. A body calls it; the attempt waits until the change is
     * live before the body goes on, and removes the changed content afterwards.
     */
    suspend fun change(): LiveContent = throw UnsupportedOperationException("this content declares no changed form")

    /**
     * Removes the content and returns what Paper runs once its removal is live. A body may call it to see what
     * follows a removal; the attempt waits until the removal is live before the body goes on, and removing it again
     * afterwards changes nothing.
     */
    suspend fun remove(): LiveContent
}

/**
 * What Paper runs at some moment, in ids the content's writer chose: every id of [present] and none of
 * [absent].
 */
data class LiveContent(
    val present: Set<String> = emptySet(),
    val absent: Set<String> = emptySet(),
)

/**
 * Waits until Paper runs content. The framework calls it after each write and each removal, outside
 * every window, so the body and the next attempt meet the content as it is meant to be.
 *
 * TODO(node 9): replace with the engine's reported active publication ("applied on N of M").
 */
fun interface ContentLiveness {
    /** Returns once [paper] runs [content]; fails naming what it still runs otherwise. */
    suspend fun awaitLive(
        paper: ContentPaper,
        content: LiveContent,
    )
}

/**
 * The Paper an attempt runs on, as content liveness reads it: its [name], and what the Typewriter
 * engine on it applies now.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
interface ContentPaper {
    val name: String

    /** The publication the Typewriter engine on this Paper applied last; fails when no engine there reports it. */
    suspend fun applied(): AppliedPublication
}

/**
 * The publication a Paper's Typewriter engine applies: its [publication] id, null before its first,
 * and the resource ids it compiles [roots] of.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
data class AppliedPublication(
    val publication: String?,
    val roots: Set<String>,
)

/**
 * Returns once the Typewriter engine on this Paper applies every id of [content]'s present and none of
 * its absent, asking every [APPLIED_POLL]; fails after [within] naming the ids it still does not apply
 * and still applies.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
suspend fun ContentPaper.awaitApplied(
    content: LiveContent,
    within: Duration = 1.minutes,
) {
    var missing = content.present
    var stale = content.absent
    val live =
        withTimeoutOrNull(within) {
            while (true) {
                val applied = applied().roots
                missing = content.present - applied
                stale = content.absent intersect applied
                if (missing.isEmpty() && stale.isEmpty()) return@withTimeoutOrNull
                delay(APPLIED_POLL)
            }
        }
    checkNotNull(live) {
        val still = listOfNotNull("does not apply $missing".takeIf { missing.isNotEmpty() }, "applies $stale".takeIf { stale.isNotEmpty() })
        "$name still ${still.joinToString(" and still ")} after $within"
    }
}

/**
 * Returns once the Typewriter engine on this Paper applies the publication [selected] names, asking
 * both every [APPLIED_POLL], since a later publication may replace the selected one meanwhile; fails
 * after [within] naming the publication it still applies.
 *
 * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
 */
suspend fun ContentPaper.awaitPublication(
    within: Duration = 1.minutes,
    selected: suspend () -> String?,
) {
    var applies: String? = null
    var wanted: String? = null
    val live =
        withTimeoutOrNull(within) {
            while (true) {
                applies = applied().publication
                wanted = selected()
                if (applies == wanted) return@withTimeoutOrNull
                delay(APPLIED_POLL)
            }
        }
    checkNotNull(live) { "$name still applies publication $applies, not the selected $wanted, after $within" }
}

/** How long content liveness waits between two asks of what a Paper's engine applies. */
private val APPLIED_POLL = 250.milliseconds
