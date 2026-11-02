package com.typewritermc.region.tracker

/**
 * The tier of a [RegionTracker], which decides whether the engine schedules per tick
 * reconciliation for it or only consults it on Bukkit player move events.
 */
enum class Tier {
    /** Geometry never changes between ticks for this viewer; only consulted on PlayerMove. */
    Static,

    /** Geometry or a handler's parameters change between ticks; reconciled each cycle. */
    Dynamic,
}
