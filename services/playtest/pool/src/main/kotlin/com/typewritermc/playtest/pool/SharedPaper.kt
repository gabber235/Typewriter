package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Claiming
import com.typewritermc.playtest.pool.PaperRules.Do

/**
 * The life of the shared Paper [name], which the client of every one of [players] joins and every
 * attempt without a restart runs on. It steps once every client is in its world, since a stepped client
 * draws no frame and would never leave the loading screen. The game boots once every client stepped
 * with it; from then on each ready client's player serves claims. Each attempt stands in a region no
 * earlier attempt got. A client that drops off it is lost, and anything that ends the shared Paper ends
 * the game.
 */
internal class SharedPaper(
    private val name: String,
    private val players: Set<String>,
) : PaperRules {
    override val bootSeconds = BOOT_SECONDS

    private val regions = Regions(ahead = players.size)
    private val joinedPlayers = mutableSetOf<String>()
    private val readyPlayers = mutableSetOf<String>()
    private var stepping = false
    private var booted = false

    override fun claim(attempt: Long): Claiming = Claiming(regions.next(), listOf(Do.Claim(attempt), Do.RegionsAhead(regions.ahead())))

    override fun connected(): List<Do> {
        stepping = false
        return listOf(Do.RegionsAhead(regions.ahead()), Do.Connect)
    }

    override fun closed(): List<Do> = listOf(Do.Fail("$name closed its pool connection"))

    override fun joined(player: String): List<Do> {
        joinedPlayers += player
        if (stepping || !joinedPlayers.containsAll(players)) return listOf()
        stepping = true
        return listOf(Do.Step)
    }

    override fun ready(player: String): List<Do> {
        readyPlayers += player
        if (booted || !readyPlayers.containsAll(players)) return listOf(Do.Free(player))
        booted = true
        return listOf(Do.Free(player), Do.Booted)
    }

    override fun arriving(player: String): List<Do> {
        joinedPlayers -= player
        readyPlayers -= player
        return listOf()
    }

    override fun dropped(
        player: String,
        reason: String,
        paperAlive: Boolean,
    ): List<Do> {
        joinedPlayers -= player
        readyPlayers -= player
        return listOf(Do.Lose(player, "it lost its Paper: $reason"))
    }

    override fun resumed(tick: Int): List<Do> = listOf()

    override fun restart(request: Long): List<Do> =
        listOf(Do.Note("an attempt asked to restart $name, which only an attempt with a Paper of its own may restart"))

    override fun failed(cause: String): List<Do> = listOf(Do.Fail(cause))

    override fun ended(
        attempt: Long,
        why: String,
    ): List<Do> = listOf()

    override fun exited(code: Int): List<Do> = listOf(Do.Fail("$name exited with code $code"))

    override fun bootTimedOut(boot: Int): List<Do> =
        if (booted) listOf() else listOf(Do.Fail("the game was not ready within $BOOT_SECONDS s"))

    companion object {
        /** How long the game may take from its start until every client stepped with the shared Paper once. */
        const val BOOT_SECONDS = 300L
    }
}
