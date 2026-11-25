package com.typewritermc.playtest.pool

import com.sun.management.OperatingSystemMXBean
import com.typewritermc.playtest.launch.PartLimit
import java.lang.management.ManagementFactory
import java.util.Locale
import kotlin.math.max
import kotlin.math.min

/**
 * The memory the pool's parts may take together, [bytes], named by where it comes from, [source]. The
 * pool, the shared Paper and every client with its display take their kinds' limits ([PartLimit]) for
 * the whole run; the own Papers of restart attempts take what is left, as many at once as fit and at
 * most one per slot. A sum of limits that fits never overcommits the budget.
 */
internal class MemoryBudget(
    val bytes: Long,
    private val source: String,
) {
    /** How many own Papers may run at once beside the pool's other parts: [clients], each with a display when [displays]. */
    fun ownPapers(
        clients: Int,
        displays: Boolean,
    ): Int = min(PartLimit.OWN_PAPER_SLOTS, max(0L, (bytes - fixed(clients, displays)) / PartLimit.OWN_PAPER.limitBytes).toInt())

    /** Why a pool of [clients] cannot run in this budget, as no own Paper fits beside its other parts; null when one does. */
    fun overBudget(
        clients: Int,
        displays: Boolean,
    ): String? {
        if (ownPapers(clients, displays) > 0) return null
        val perClient = client(displays)
        val fit = max(0L, (bytes - fixed(0, displays) - PartLimit.OWN_PAPER.limitBytes) / perClient)
        val withDisplays = if (displays) " with their displays" else ""
        return "$clients clients$withDisplays, the shared Paper and the pool take ${gib(fixed(clients, displays))} of the pool's " +
            "${gib(bytes)} ($source), leaving no room for an own Paper of ${gib(PartLimit.OWN_PAPER.limitBytes)}; " +
            "run at most $fit clients (cargo xtask e2e game --clients $fit)"
    }

    private fun fixed(
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
