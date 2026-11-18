package com.typewritermc.playtest.wire

import skirout.harness.v1.wire.Block
import skirout.harness.v1.wire.BlockPos
import skirout.harness.v1.wire.Camera
import skirout.harness.v1.wire.ChatLine
import skirout.harness.v1.wire.Entity
import skirout.harness.v1.wire.Item
import skirout.harness.v1.wire.Perception
import skirout.harness.v1.wire.Text
import java.util.UUID

/**
 * A perception record of [tick], perceived at its end unless [partial] says otherwise, that shows
 * nothing yet; a case adds what it shows with `copy`.
 */
fun perception(
    tick: Int,
    partial: Float = 1f,
    frame: Int = -1,
): Perception = Perception.partial(tick = tick, partial = partial, frame = frame)

/** A camera at this eye position, looking south and level with a 70 degree view, without the spyglass. */
fun camera(
    x: Double = 0.5,
    y: Double = 101.62,
    z: Double = 0.5,
    fov: Float = 70f,
    scoped: Boolean = false,
): Camera = Camera(x = x, y = y, z = z, yaw = 0f, pitch = 0f, fov = fov, scoped = scoped)

/** A legible run of [text] that [element] drew. */
fun text(
    element: String,
    text: String,
): Text = Text(element = element, text = text)

/** A chat line of [text] that arrived in [tick]. */
fun chatLine(
    tick: Int,
    text: String,
): ChatLine = ChatLine(tick = tick, text = text)

/** [count] of [item] the GUI draws in [slot] of [element], [selected] when the selection frame marks it. */
fun item(
    element: String,
    slot: Int,
    selected: Boolean,
    item: String,
    count: Int,
): Item = Item(element = element, slot = slot, selected = selected, item = item, count = count)

/** A block position in the world. */
fun blockPos(
    x: Int,
    y: Int,
    z: Int,
): BlockPos = BlockPos(x = x, y = y, z = z)

/** A watched [block] at [at], [seen] as it is, last changed in [changed] or -1. */
fun watchedBlock(
    at: BlockPos,
    block: String,
    seen: Boolean,
    changed: Int,
): Block = Block(at = at, block = block, seen = seen, changed = changed)

/** A watched entity the frame draws, owning [share] of it, or null when the frame was not measured. */
fun drawnEntity(
    uuid: UUID,
    hurt: Boolean,
    name: String?,
    share: Double?,
): Entity = Entity(uuid = uuid.toString(), hurt = hurt, name = name, share = share)
