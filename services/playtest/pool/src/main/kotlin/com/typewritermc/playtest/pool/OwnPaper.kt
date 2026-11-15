package com.typewritermc.playtest.pool

/**
 * The life of the Paper of its own that a restart attempt runs on, as the rules the pool follows: what
 * the pool does at each thing it hears. The attempt's players wait on the shared Paper while it boots
 * and are told to join only once it is up. Each restart kills it as a crash would and boots it again on
 * the same folder and port; the players' clients, dropped by the kill, draw nothing until it is up
 * again. A Paper that exits on its own, or does not come back within the boot limit, is lost: only its
 * attempt fails.
 */
internal class OwnPaper(
    val name: String,
    private val players: Set<String>,
) {
    /** What the pool does next. */
    sealed interface Do {
        /** Starts the Paper process on its folder and port; again after a kill. */
        data object Boot : Do

        /** Tells each player's client to join this Paper. */
        data object Connect : Do

        /** Paper runs a tick only when its step policy grants it, from now on. */
        data object Step : Do

        /** The players belong to the attempt: wiped, in its region, then leased. */
        data object Claim : Do

        /** Back after a kill, the players belong to the attempt again, unwiped and where Paper put them. */
        data object Resume : Do

        /** Ends the Paper process at once, as a crash would, so it saves nothing. */
        data object Kill : Do

        /** Answers the attempt's restart [request]: every player is back after [tick] of the new Paper. */
        data class Restarted(
            val request: Long,
            val tick: Int,
        ) : Do

        /** The Paper is lost for [cause]: the attempt fails, the process ends, the players go back to the shared Paper. */
        data class Lost(
            val cause: String,
        ) : Do

        /** The attempt ended: the players go back to the shared Paper and this Paper stops. */
        data object Return : Do
    }

    private enum class Phase { BOOTING, JOINING, READYING, RUNNING, RESUMING, KILLED, OVER }

    private var phase = Phase.BOOTING
    private var claimed = false
    private var restart: Long? = null
    private val joinedPlayers = mutableSetOf<String>()
    private val readyPlayers = mutableSetOf<String>()

    /** Boots so far, the first included: a boot limit names the boot it is for. */
    var boots = 0
        private set

    /** Whether a player's client losing this Paper now is part of the plan: it was killed, or the attempt is over. */
    val dropsExpected: Boolean
        get() = phase == Phase.KILLED || phase == Phase.OVER || (phase == Phase.BOOTING && restart != null)

    /** The first boot, once the attempt holds its players. */
    fun start(): List<Do> = boot()

    /** The plugin of the Paper booted last connected to the pool: Paper is done starting. */
    fun connected(): List<Do> {
        if (phase != Phase.BOOTING) return listOf()
        phase = Phase.JOINING
        return listOf(Do.Connect)
    }

    /** [player]'s client is in this Paper's world. */
    fun joined(player: String): List<Do> {
        if (phase != Phase.JOINING || player !in players) return listOf()
        joinedPlayers += player
        if (!joinedPlayers.containsAll(players)) return listOf()
        phase = Phase.READYING
        return listOf(Do.Step)
    }

    /** [player]'s client steps with this Paper. */
    fun ready(player: String): List<Do> {
        if (phase != Phase.READYING || player !in players) return listOf()
        readyPlayers += player
        if (!readyPlayers.containsAll(players)) return listOf()
        if (claimed) {
            phase = Phase.RESUMING
            return listOf(Do.Resume)
        }
        claimed = true
        phase = Phase.RUNNING
        return listOf(Do.Claim)
    }

    /** Paper resumed the attempt after a restart; its players' clients hold all it sends from after [tick] on. */
    fun resumed(tick: Int): List<Do> {
        val request = restart
        if (phase != Phase.RESUMING || request == null) return listOf()
        phase = Phase.RUNNING
        restart = null
        return listOf(Do.Restarted(request, tick))
    }

    /** The attempt asks, as [request], for its Paper to be killed and booted again. */
    fun restart(request: Long): List<Do> {
        if (phase != Phase.RUNNING) return listOf()
        restart = request
        phase = Phase.KILLED
        return listOf(Do.Kill)
    }

    /** The Paper process ended with [code]. */
    fun exited(code: Int): List<Do> =
        when (phase) {
            Phase.OVER -> listOf()
            Phase.KILLED -> boot()
            Phase.RUNNING -> lost("$name exited with code $code while its attempt ran")
            else -> lost("$name exited with code $code while it booted")
        }

    /** The limit for boot [boot] ran out; boots count from 1. */
    fun bootTimedOut(boot: Int): List<Do> {
        val booting = phase in setOf(Phase.BOOTING, Phase.JOINING, Phase.READYING, Phase.RESUMING)
        return if (boot == boots && booting) lost("$name did not boot within $BOOT_SECONDS s") else listOf()
    }

    /** Paper could not do what the attempt needs, for [cause]: it is lost. */
    fun failed(cause: String): List<Do> = if (phase == Phase.OVER) listOf() else lost(cause)

    /** Whether this Paper serves its attempt no more: the attempt ended or the Paper is lost. */
    val over: Boolean get() = phase == Phase.OVER

    /** The attempt ended. */
    fun ended(): List<Do> {
        if (phase == Phase.OVER) return listOf()
        phase = Phase.OVER
        return listOf(Do.Return)
    }

    private fun boot(): List<Do> {
        phase = Phase.BOOTING
        boots++
        joinedPlayers.clear()
        readyPlayers.clear()
        return listOf(Do.Boot)
    }

    private fun lost(cause: String): List<Do> {
        phase = Phase.OVER
        return listOf(Do.Lost(cause))
    }

    companion object {
        /** How long one boot may take, from its start until every player is back. */
        const val BOOT_SECONDS = 120L
    }
}
