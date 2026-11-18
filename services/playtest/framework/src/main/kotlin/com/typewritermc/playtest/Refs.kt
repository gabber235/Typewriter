package com.typewritermc.playtest

import java.util.UUID

/** A block position in the world. */
data class BlockPos(
    val x: Int,
    val y: Int,
    val z: Int,
) {
    override fun toString() = "$x $y $z"
}

/** A block a probe placed at [at]; the player's client watches it for the rest of the attempt. */
data class BlockRef(
    val at: BlockPos,
    val block: String,
) {
    override fun toString() = "$block at $at"
}

/** An entity a probe spawned; the player's client watches it for the rest of the attempt. */
data class EntityRef(
    val uuid: UUID,
    val type: String,
) {
    override fun toString() = type.removePrefix("minecraft:")
}
