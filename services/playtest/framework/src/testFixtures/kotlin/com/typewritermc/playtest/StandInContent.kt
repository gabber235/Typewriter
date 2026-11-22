package com.typewritermc.playtest

/**
 * Content standing in for what a system under test would write: it writes the id `book`, and records in
 * [events], in order, each write, removal and liveness wait, so a test sees when the attempt ran them.
 * A body adds its own events. With [neverLive], the content never runs on Paper and every wait fails;
 * with [removalFails], removing it fails.
 */
class StandInContent(
    private val neverLive: Boolean = false,
    private val removalFails: Boolean = false,
) : AttemptContent {
    val events = mutableListOf<String>()

    override val key = "stand-in"

    override val liveness =
        ContentLiveness { paper, content ->
            events += "live on ${paper.name}: present ${content.present}, absent ${content.absent}"
            if (neverLive) throw IllegalStateException("Paper never ran the stand in content")
        }

    override suspend fun write(players: List<GamePlayer>): WrittenContent {
        events += "write for ${players.joinToString { it.name }}"
        return object : WrittenContent {
            override val live = LiveContent(present = setOf("book"))

            override suspend fun change(): LiveContent {
                events += "change"
                return LiveContent(present = setOf("changed book"), absent = setOf("book"))
            }

            override suspend fun remove(): LiveContent {
                events += "remove"
                if (removalFails) throw IllegalStateException("the stand in content could not be removed")
                return LiveContent(absent = setOf("book"))
            }
        }
    }
}
