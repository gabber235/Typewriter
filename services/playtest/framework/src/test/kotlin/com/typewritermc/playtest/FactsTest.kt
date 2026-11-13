package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Block
import com.typewritermc.playtest.wire.Message.Entity
import com.typewritermc.playtest.wire.Message.Item
import com.typewritermc.playtest.wire.Message.Text
import com.typewritermc.playtest.wire.camera
import com.typewritermc.playtest.wire.perception
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.util.UUID
import com.typewritermc.playtest.wire.Message.BlockPos as WireBlockPos

val FactsTest by testSuite {
    val before = Stimulus(100, perception(100, camera = camera(y = 101.62)))

    test("suggestions pass only when the list shows exactly those names in that order") {
        val shown = perception(103, texts = listOf(Text("suggestions", "shop"), Text("suggestions", "spawn"), Text("other", "/warp s")))

        suggestions("shop", "spawn").shownIn(shown, before) shouldBe true
        suggestions("spawn", "shop").shownIn(shown, before) shouldBe false
        suggestions("shop").shownIn(shown, before) shouldBe false
        suggestions("shop", "spawn", "spire").shownIn(shown, before) shouldBe false
    }

    test("suggestions ignore the same words drawn outside the suggestion list") {
        val typed = perception(103, texts = listOf(Text("other", "shop"), Text("chat", "spawn")))

        suggestions("shop", "spawn").shownIn(typed, before) shouldBe false
    }

    test("held is the hotbar item the selection frame marks, with or without the minecraft namespace") {
        val hotbar =
            perception(
                103,
                items = listOf(Item("hotbar", 0, false, "minecraft:spyglass", 1), Item("hotbar", 1, true, "minecraft:stick", 1)),
            )

        held("stick").shownIn(hotbar, before) shouldBe true
        held("minecraft:stick").shownIn(hotbar, before) shouldBe true
        held("spyglass").shownIn(hotbar, before) shouldBe false
    }

    test("an item in another element is neither held nor in the off hand nor carried") {
        val screen = perception(103, items = listOf(Item("screen", 9, false, "minecraft:stick", 16)))

        held("stick").shownIn(screen, before) shouldBe false
        offhand("stick").shownIn(screen, before) shouldBe false
        carried("stick").shownIn(screen, before) shouldBe false
    }

    test("the off hand and the pointer each show their own item") {
        val shown =
            perception(
                103,
                items = listOf(Item("offhand", -1, false, "minecraft:spyglass", 1), Item("carried", -1, false, "minecraft:stick", 16)),
            )

        offhand("spyglass").shownIn(shown, before) shouldBe true
        offhand("stick").shownIn(shown, before) shouldBe false
        carried("stick").shownIn(shown, before) shouldBe true
        carried("spyglass").shownIn(shown, before) shouldBe false
    }

    test("the camera rose or sank only against its height at the stimulus") {
        camera.rose().shownIn(perception(104, camera = camera(y = 102.4)), before) shouldBe true
        camera.rose().shownIn(perception(104, camera = camera(y = 101.62)), before) shouldBe false
        camera.sank().shownIn(perception(104, camera = camera(y = 101.27)), before) shouldBe true
        camera.sank().shownIn(perception(104, camera = camera(y = 102.4)), before) shouldBe false
    }

    test("a change of the camera cannot be judged without a view at the stimulus or now") {
        val unknown = Stimulus(100, perception(100))

        camera.rose().shownIn(perception(104, camera = camera(y = 102.4)), unknown) shouldBe false
        camera.rose().shownIn(perception(104), before) shouldBe false
    }

    test("the camera is scoped only while the spyglass overlay covers it") {
        camera.scoped().shownIn(perception(104, camera = camera(fov = 7f, scoped = true)), before) shouldBe true
        camera.scoped().shownIn(perception(104, camera = camera(fov = 7f)), before) shouldBe false
    }

    test("the camera is near a point when the eye is within the distance across the ground, whatever its height") {
        camera.near(64.5, 4.5, within = 0.5).shownIn(perception(150, camera = camera(x = 64.6, y = 120.0, z = 4.1)), before) shouldBe true
        camera.near(64.5, 4.5, within = 0.5).shownIn(perception(150, camera = camera(x = 64.5, z = 3.9)), before) shouldBe false
        camera.near(64.5, 4.5, within = 0.5).shownIn(perception(150, camera = camera(x = 65.1, z = 4.5)), before) shouldBe false
    }

    test("a block becomes what it changed to after the stimulus, once the player perceives it so") {
        val leaves = BlockRef(BlockPos(104, 101, 2), "minecraft:oak_leaves")
        val at = WireBlockPos(104, 101, 2)

        block(leaves).gone().shownIn(perception(106, blocks = listOf(Block(at, "minecraft:air", true, 105))), before) shouldBe true
        block(
            leaves,
        ).becomes("oak_leaves").shownIn(perception(106, blocks = listOf(Block(at, "minecraft:oak_leaves", true, 105))), before) shouldBe
            true
        block(
            leaves,
        ).becomes(
            "minecraft:oak_leaves",
        ).shownIn(perception(106, blocks = listOf(Block(at, "minecraft:oak_leaves", true, 105))), before) shouldBe
            true
    }

    test("a block that changed before the stimulus, is not perceived yet, or is another block does not pass") {
        val leaves = BlockRef(BlockPos(104, 101, 2), "minecraft:oak_leaves")
        val at = WireBlockPos(104, 101, 2)

        block(leaves).gone().shownIn(perception(106, blocks = listOf(Block(at, "minecraft:air", true, 100))), before) shouldBe false
        block(leaves).gone().shownIn(perception(106, blocks = listOf(Block(at, "minecraft:air", false, 105))), before) shouldBe false
        block(leaves).gone().shownIn(perception(106, blocks = listOf(Block(at, "minecraft:oak_leaves", true, 105))), before) shouldBe false
        block(
            leaves,
        ).gone().shownIn(perception(106, blocks = listOf(Block(WireBlockPos(104, 101, 3), "minecraft:air", true, 105))), before) shouldBe
            false
    }

    test("an entity is hurt or named only while the frame draws it so") {
        val pig = EntityRef(UUID(0, 7), "minecraft:pig")

        entity(pig).hurt().shownIn(perception(104, entities = listOf(Entity(UUID(0, 7), true, null))), before) shouldBe true
        entity(pig).hurt().shownIn(perception(104, entities = listOf(Entity(UUID(0, 7), false, null))), before) shouldBe false
        entity(pig).named("Oink").shownIn(perception(104, entities = listOf(Entity(UUID(0, 7), false, "Oink"))), before) shouldBe true
        entity(pig).named("Oink").shownIn(perception(104, entities = listOf(Entity(UUID(0, 7), false, "Pig"))), before) shouldBe false
    }

    test("an entity the frame does not draw shows nothing") {
        val pig = EntityRef(UUID(0, 7), "minecraft:pig")
        val other = perception(104, entities = listOf(Entity(UUID(0, 8), true, "Oink")))

        entity(pig).hurt().shownIn(other, before) shouldBe false
        entity(pig).named("Oink").shownIn(other, before) shouldBe false
    }
}
