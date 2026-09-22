package com.typewritermc.entity.entries.data.minecraft.itemframe

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.typewritermc.engine.paper.utils.serverVersion

/**
 * Where an item frame keeps its data, which moved when 1.21.6 made the direction it faces synced data.
 *
 * EntityLib hardcodes the newer item slot and puts the rotation on that same slot, so its
 * `ItemFrameMeta` setters corrupt the frame on every version.
 */
internal object ItemFrameMetadata {
    val hasSyncedDirection: Boolean
        get() = serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_6)

    const val DIRECTION_INDEX: Byte = 8

    val itemIndex: Byte
        get() = if (hasSyncedDirection) 9 else 8

    val rotationIndex: Byte
        get() = if (hasSyncedDirection) 10 else 9
}
