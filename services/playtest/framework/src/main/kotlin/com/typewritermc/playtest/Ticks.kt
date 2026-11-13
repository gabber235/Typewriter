package com.typewritermc.playtest

/** A number of Paper ticks; a window counts ticks that really ran, never wall time. */
@JvmInline
value class Ticks(
    val count: Int,
) {
    init {
        require(count > 0) { "a window lasts at least one tick, not $count" }
    }
}

val Int.ticks: Ticks get() = Ticks(this)
