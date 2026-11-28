package com.typewritermc.playtest.pool

import com.sun.management.OperatingSystemMXBean
import com.typewritermc.playtest.launch.PartLimit
import java.lang.management.ManagementFactory
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/**
 * The memory the game's parts may take together, [bytes], named by where it comes from, [source]. The
 * pool, the shared Paper and every client with its display run the whole run and take their kinds'
 * limits ([PartLimit]) from the start; own Papers of restart attempts take what is left, each starting
 * only once its limit fits there ([OwnPaperRoom]). A sum of limits that fits never overcommits the budget.
 */
internal class MemoryBudget(
    val bytes: Long,
    val source: String,
) {
    /** The room own Papers wait for beside the pool's parts that run the whole run: [clients], each with a display when [displays]. */
    fun ownPaperRoom(
        clients: Int,
        displays: Boolean,
    ): OwnPaperRoom = OwnPaperRoom(leftBytes = bytes - wholeRun(clients, displays), slots = PartLimit.OWN_PAPER_SLOTS)

    /**
     * Why a pool of [clients] cannot run in this budget, as its parts that run the whole run alone take more; null when
     * they fit, also where no own Paper fits beside them.
     */
    fun overBudget(
        clients: Int,
        displays: Boolean,
    ): String? {
        val taken = wholeRun(clients, displays)
        if (taken <= bytes) return null
        val fit = max(0L, (bytes - wholeRun(0, displays)) / client(displays))
        val withDisplays = if (displays) " with their displays" else ""
        return "$clients clients$withDisplays, the shared Paper and the pool take ${gib(taken)} of the game's ${gib(bytes)} budget " +
            "($source); run at most $fit clients (cargo xtask e2e game --clients $fit)"
    }

    private fun wholeRun(
        clients: Int,
        displays: Boolean,
    ): Long = PartLimit.POOL.limitBytes + PartLimit.SHARED_PAPER.limitBytes + clients * client(displays)

    private fun client(displays: Boolean): Long = PartLimit.CLIENT.limitBytes + if (displays) PartLimit.DISPLAY.limitBytes else 0

    companion object {
        /** Half the machine's memory, where nothing gives the pool a budget of its own; the rest is the build's and the system's. */
        fun halfTheMachine(): MemoryBudget {
            val machine = (ManagementFactory.getOperatingSystemMXBean() as OperatingSystemMXBean).totalMemorySize
            return MemoryBudget(machine / 2, "half the machine")
        }

        private fun gib(bytes: Long) = String.format(Locale.ROOT, "%.1f GiB", bytes / (1024.0 * 1024 * 1024))
    }
}

/**
 * What the game's budget leaves for own Papers, [leftBytes], once the parts that run the whole run took theirs, and
 * the [slots] the build prepares for them: an own Paper starts only once its limit fits in what the running ones
 * leave, and while a slot is free.
 */
internal data class OwnPaperRoom(
    val leftBytes: Long,
    val slots: Int,
) {
    /** The most own Papers that run at once. */
    val most: Int = min(slots.toLong(), max(0L, leftBytes) / PartLimit.OWN_PAPER.limitBytes).toInt()

    /** Whether [count] own Papers fit at once. */
    fun fits(count: Int): Boolean = count <= most

    companion object {
        /** Room for an own Paper in every slot, where memory sets no bound. */
        val EVERY_SLOT = OwnPaperRoom(Long.MAX_VALUE, PartLimit.OWN_PAPER_SLOTS)
    }
}
