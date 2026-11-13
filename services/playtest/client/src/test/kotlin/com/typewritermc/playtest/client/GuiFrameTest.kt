package com.typewritermc.playtest.client

import com.typewritermc.playtest.client.GuiFrame.Kind.FILL
import com.typewritermc.playtest.client.GuiFrame.Kind.IMAGE
import com.typewritermc.playtest.wire.Message.Item
import com.typewritermc.playtest.wire.Message.Text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val GuiFrameTest by testSuite {
    val opaqueWhite = 0xFFFFFFFF.toInt()

    test("opaque text fully on screen is legible and named by the element that drew it") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "Hello", 2, 200, 40, 209, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("chat", "Hello"))
    }

    test("text drawn outside every named element is named other") {
        val frame = GuiFrame(427, 240)
        frame.text(null, "Survival", 2, 2, 50, 11, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("other", "Survival"))
    }

    test("text needs an alpha of at least 8 to be legible") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "faded", 2, 200, 40, 209, 0x07FFFFFF)
        frame.text("chat", "faint", 2, 210, 40, 219, 0x08FFFFFF)

        frame.legibleTexts() shouldBe listOf(Text("chat", "faint"))
    }

    test("text needs more than half of its area on screen to be legible") {
        val frame = GuiFrame(100, 100)
        frame.text("chat", "half off", 50, 10, 150, 20, opaqueWhite)
        frame.text("chat", "mostly on", 40, 30, 140, 40, opaqueWhite)
        frame.text("chat", "above", 10, -9, 50, 1, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("chat", "mostly on"))
    }

    test("text drawn before a blur is behind it and not legible") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "behind", 2, 200, 40, 209, opaqueWhite)
        frame.blur()
        frame.text(null, "Options", 180, 20, 240, 29, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("other", "Options"))
    }

    test("an opaque fill painted later over at least 90 percent of the text hides it") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "covered", 0, 0, 100, 10, opaqueWhite)
        frame.text("chat", "mostly covered", 0, 20, 100, 30, opaqueWhite)
        frame.text("chat", "under glass", 0, 40, 100, 50, opaqueWhite)
        frame.element(FILL, 0, 0, 90, 10, 0xFF000000.toInt())
        frame.element(FILL, 0, 20, 89, 30, 0xFF000000.toInt())
        frame.element(FILL, 0, 40, 100, 50, 0xEF000000.toInt())

        frame.legibleTexts() shouldBe listOf(Text("chat", "mostly covered"), Text("chat", "under glass"))
    }

    test("an image painted later over the text hides it, while one painted earlier is its background") {
        val frame = GuiFrame(427, 240)
        frame.element(IMAGE, 0, 0, 100, 10, opaqueWhite)
        frame.text("chat", "on a panel", 0, 0, 100, 10, opaqueWhite)
        frame.text("chat", "under a panel", 0, 20, 100, 30, opaqueWhite)
        frame.element(IMAGE, 0, 20, 100, 30, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("chat", "on a panel"))
    }

    test("blank text is not a legible run") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "  ", 2, 200, 40, 209, opaqueWhite)

        frame.legibleTexts() shouldBe listOf()
    }

    test("an item on screen is seen with its element, slot and count") {
        val frame = GuiFrame(427, 240)
        frame.item("offhand", -1, "minecraft:spyglass", 1, 110, 221, 126, 237)

        frame.visibleItems() shouldBe listOf(Item("offhand", -1, false, "minecraft:spyglass", 1))
    }

    test("the hotbar item inside the selection frame is the selected one") {
        val frame = GuiFrame(427, 240)
        frame.selection(141, 217, 165, 240)
        frame.item("hotbar", 0, "minecraft:spyglass", 1, 145, 221, 161, 237)
        frame.item("hotbar", 1, "minecraft:stick", 1, 165, 221, 181, 237)

        frame.visibleItems() shouldBe
            listOf(Item("hotbar", 0, true, "minecraft:spyglass", 1), Item("hotbar", 1, false, "minecraft:stick", 1))
    }

    test("only a hotbar item can be selected, and none without a selection frame") {
        val frame = GuiFrame(427, 240)
        frame.item("hotbar", 0, "minecraft:spyglass", 1, 145, 221, 161, 237)
        frame.selection(141, 17, 165, 40)
        frame.item("screen", 9, "minecraft:stick", 16, 145, 21, 161, 37)

        frame.visibleItems() shouldBe
            listOf(Item("hotbar", 0, false, "minecraft:spyglass", 1), Item("screen", 9, false, "minecraft:stick", 16))
    }

    test("an item behind a blur, mostly off screen, or covered by a later image is not seen") {
        val frame = GuiFrame(427, 240)
        frame.item("hotbar", 0, "minecraft:spyglass", 1, 145, 221, 161, 237)
        frame.blur()
        frame.item("screen", 9, "minecraft:stick", 16, 420, 21, 436, 37)
        frame.item("screen", 10, "minecraft:compass", 1, 100, 21, 116, 37)
        frame.element(IMAGE, 100, 21, 116, 37, opaqueWhite)
        frame.item("carried", -1, "minecraft:stick", 16, 200, 100, 216, 116)

        frame.visibleItems() shouldBe listOf(Item("carried", -1, false, "minecraft:stick", 16))
    }

    test("an item does not hide text, and text does not hide an item") {
        val frame = GuiFrame(427, 240)
        frame.text("chat", "Hello", 145, 221, 161, 230, opaqueWhite)
        frame.item("hotbar", 0, "minecraft:spyglass", 1, 145, 221, 161, 237)
        frame.text(null, "64", 150, 230, 161, 237, opaqueWhite)

        frame.legibleTexts() shouldBe listOf(Text("chat", "Hello"), Text("other", "64"))
        frame.visibleItems() shouldBe listOf(Item("hotbar", 0, false, "minecraft:spyglass", 1))
    }
}
