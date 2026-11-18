package com.typewritermc.playtest

import java.util.UUID

/** One player of a warm client, held by an attempt while the pool leases it. */
data class GamePlayer(
    val name: String,
    val uuid: UUID,
)
