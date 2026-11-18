package com.typewritermc.playtest

/** A stimulus took effect between ticks: [tick] had ended, so its effects can show from the next tick on. */
data class Mark(
    val tick: Int,
)
