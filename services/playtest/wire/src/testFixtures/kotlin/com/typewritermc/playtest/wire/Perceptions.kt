package com.typewritermc.playtest.wire

import com.typewritermc.playtest.wire.Message.Block
import com.typewritermc.playtest.wire.Message.Camera
import com.typewritermc.playtest.wire.Message.ChatLine
import com.typewritermc.playtest.wire.Message.Entity
import com.typewritermc.playtest.wire.Message.Item
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.Text

/** A perception record of [tick] that shows only what the arguments name. */
fun perception(
    tick: Int,
    texts: List<Text> = listOf(),
    chat: List<ChatLine> = listOf(),
    camera: Camera? = null,
    items: List<Item> = listOf(),
    blocks: List<Block> = listOf(),
    entities: List<Entity> = listOf(),
): Perception = Perception(tick, texts, chat, camera, items, blocks, entities)

/** A camera at this eye position, looking south and level with a 70 degree view, without the spyglass. */
fun camera(
    x: Double = 0.5,
    y: Double = 101.62,
    z: Double = 0.5,
    fov: Float = 70f,
    scoped: Boolean = false,
): Camera = Camera(x, y, z, 0f, 0f, fov, scoped)
