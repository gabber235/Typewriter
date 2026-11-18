package com.typewritermc.playtest

import skirout.harness.v1.wire.Perception
import skirout.harness.v1.wire.Region
import skirout.harness.v1.wire.BlockPos as WireBlockPos

/** The world position of [at], a position counted from the middle of this region. */
internal fun Region.world(at: BlockPos): WireBlockPos = WireBlockPos(x = x + at.x, y = at.y, z = z + at.z)

/** The world x of [x], counted from the middle of this region. */
internal fun Region.worldX(x: Double): Double = this.x + x

/** The world z of [z], counted from the middle of this region. */
internal fun Region.worldZ(z: Double): Double = this.z + z

/** [perception] with every position in it counted from the middle of this region, as the requirement names them. */
internal fun Region.local(perception: Perception): Perception =
    perception.copy(
        camera = perception.camera?.let { it.copy(x = it.x - x, z = it.z - z) },
        blocks = perception.blocks.map { it.copy(at = it.at.copy(x = it.at.x - x, z = it.at.z - z)) },
    )
