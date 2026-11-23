package com.typewritermc.engine.events

/**
 * The one engine piece that drains the chain queue: it decides when queued chains go to a [ChainWorker]. Every engine
 * kind provides exactly one, and an engine without one fails at start, so no engine kind leaves chains waiting forever.
 * Paper drains at the end of every tick; an engine without ticks drains at once.
 */
interface ChainPickup {
    /** A chain was just queued. A pickup on a clock leaves it for the next drain; one that drains at once drains here. */
    fun queued()
}

/** The pickup of an engine without ticks, such as the panel engine: every queued chain goes to a worker at once. */
class ImmediateChainPickup(
    private val worker: ChainWorker,
) : ChainPickup {
    override fun queued() = worker.pickup()
}
