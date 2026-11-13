package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Block
import com.typewritermc.playtest.wire.Message.Camera
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.BlockPos as WireBlockPos

/** The world position of [at], a position counted from the middle of this region. */
internal fun Region.world(at: BlockPos): WireBlockPos = WireBlockPos(x + at.x, at.y, z + at.z)

/** The world x of [x], counted from the middle of this region. */
internal fun Region.worldX(x: Double): Double = this.x + x

/** The world z of [z], counted from the middle of this region. */
internal fun Region.worldZ(z: Double): Double = this.z + z

/** [perception] with every position in it counted from the middle of this region, as the requirement names them. */
internal fun Region.local(perception: Perception): Perception =
    Perception(
        perception.tick(),
        perception.texts(),
        perception.chat(),
        perception.camera()?.let { Camera(it.x() - x, it.y(), it.z() - z, it.yaw(), it.pitch(), it.fov(), it.scoped()) },
        perception.items(),
        perception.blocks().map { Block(WireBlockPos(it.at().x() - x, it.at().y(), it.at().z() - z), it.block(), it.seen(), it.changed()) },
        perception.entities(),
    )
