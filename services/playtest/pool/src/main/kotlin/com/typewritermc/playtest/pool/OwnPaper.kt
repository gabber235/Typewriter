package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Claiming
import com.typewritermc.playtest.pool.PaperRules.Do
import skirout.harness.v1.wire.Region

/**
 * The life of the Paper of its own that a restart attempt runs on. The attempt's players wait on the
 * shared Paper while it boots and are told to join only once it is up. Each restart kills it as a crash
 * would and boots it again on the same folder and port; the players' clients, dropped by the kill, draw
 * nothing until it is up again. A Paper that exits on its own, or does not come back within the boot
 * limit, is lost: only its attempt fails.
 */
internal class OwnPaper(
    private val name: String,
    private val players: Set<String>,
) : PaperRules {
    private enum class Phase { BOOTING, JOINING, READYING, RUNNING, RESUMING, KILLED, OVER }

    override val bootSeconds = BOOT_SECONDS

    private var phase = Phase.BOOTING
    private var attempt = 0L
    private var claimed = false
    private var restart: Long? = null
    private var boots = 0
    private val joinedPlayers = mutableSetOf<String>()
    private val readyPlayers = mutableSetOf<String>()

    // A player's client losing this Paper now is part of the plan: it was killed, or the attempt is over.
    private val dropsExpected: Boolean
        get() = phase == Phase.KILLED || phase == Phase.OVER || (phase == Phase.BOOTING && restart != null)

    /** Alone on its Paper, the attempt stands in the region at the spawn; the first boot follows. */
    override fun claim(attempt: Long): Claiming {
        this.attempt = attempt
        return Claiming(REGION, boot())
    }

    override fun connected(): List<Do> {
        val ahead = Do.RegionsAhead(listOf(REGION))
        if (phase != Phase.BOOTING) return listOf(ahead)
        phase = Phase.JOINING
        return listOf(ahead, Do.Gather(attempt), Do.Connect)
    }

    // Its end shows in its process's exit.
    override fun closed(): List<Do> = listOf()

    override fun joined(player: String): List<Do> {
        if (phase != Phase.JOINING || player !in players) return listOf()
        joinedPlayers += player
        if (!joinedPlayers.containsAll(players)) return listOf()
        phase = Phase.READYING
        return listOf(Do.Step)
    }

    /**
     * A player steps with this boot. After a restart, what its client recorded until now shows the killed
     * Paper: a stepped client hears of the kill only once the pool moves it, so it may still record the
     * last ticks it ran there after the kill, and only its first step here, which it reports before
     * anything it records here, divides the two.
     */
    override fun ready(player: String): List<Do> {
        if (phase != Phase.READYING || player !in players) return listOf()
        readyPlayers += player
        val forget = if (claimed) listOf(Do.Forget(player)) else listOf()
        if (!readyPlayers.containsAll(players)) return forget
        if (claimed) {
            phase = Phase.RESUMING
            return forget + Do.Resume(attempt)
        }
        claimed = true
        phase = Phase.RUNNING
        return listOf(Do.Claim(attempt))
    }

    // Each boot gathers the players again.
    override fun arriving(player: String): List<Do> = listOf()

    /** A drop off a killed Paper, a Paper whose attempt is over, or a Paper whose process died is no loss of the client. */
    override fun dropped(
        player: String,
        reason: String,
        paperAlive: Boolean,
    ): List<Do> = if (dropsExpected || !paperAlive) listOf(Do.Forget(player)) else listOf(Do.Lose(player, "it lost its Paper: $reason"))

    override fun resumed(tick: Int): List<Do> {
        val request = restart
        if (phase != Phase.RESUMING || request == null) return listOf()
        phase = Phase.RUNNING
        restart = null
        return listOf(Do.Restarted(attempt, request, tick))
    }

    override fun restart(request: Long): List<Do> {
        if (phase != Phase.RUNNING) return listOf()
        restart = request
        phase = Phase.KILLED
        return listOf(Do.Kill(attempt))
    }

    /** A killed Paper boots again; one that exits on its own is lost and gone; once over, its exit is the end. */
    override fun exited(code: Int): List<Do> =
        when (phase) {
            Phase.OVER -> listOf(Do.Gone)
            Phase.KILLED -> boot()
            Phase.RUNNING -> lost("$name exited with code $code while its attempt ran") + Do.Gone
            else -> lost("$name exited with code $code while it booted") + Do.Gone
        }

    override fun bootTimedOut(boot: Int): List<Do> {
        val booting = phase in setOf(Phase.BOOTING, Phase.JOINING, Phase.READYING, Phase.RESUMING)
        return if (boot == boots && booting) lost("$name did not boot within $BOOT_SECONDS s") else listOf()
    }

    override fun failed(cause: String): List<Do> = if (phase == Phase.OVER) listOf() else lost(cause)

    override fun ended(
        attempt: Long,
        why: String,
    ): List<Do> {
        if (phase == Phase.OVER) return listOf()
        phase = Phase.OVER
        return listOf(Do.Note("stops, as attempt $attempt ended: $why"), Do.Return(attempt))
    }

    private fun boot(): List<Do> {
        phase = Phase.BOOTING
        boots++
        joinedPlayers.clear()
        readyPlayers.clear()
        return listOf(Do.Boot(boots))
    }

    private fun lost(cause: String): List<Do> {
        phase = Phase.OVER
        return listOf(Do.Lost(attempt, cause))
    }

    companion object {
        /** How long one boot may take, from its start until every player is back. */
        const val BOOT_SECONDS = 120L

        /** The region at the spawn, where an attempt alone on its Paper stands. */
        val REGION = Region(x = 0, z = 0)
    }
}
