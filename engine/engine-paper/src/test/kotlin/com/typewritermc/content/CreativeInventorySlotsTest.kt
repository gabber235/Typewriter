package com.typewritermc.content

import com.typewritermc.engine.paper.content.creativeSlotToInventorySlot
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe

class CreativeInventorySlotsTest : FunSpec({
    test("hotbar sits at the end of the creative layout and at the start of the inventory") {
        creativeSlotToInventorySlot(36) shouldBe 0
        creativeSlotToInventorySlot(44) shouldBe 8
    }

    test("main inventory slots line up one to one") {
        (9..35).forEach { creativeSlotToInventorySlot(it) shouldBe it }
    }

    test("armor is ordered helmet first in creative and boots first in the inventory") {
        creativeSlotToInventorySlot(5) shouldBe 39
        creativeSlotToInventorySlot(6) shouldBe 38
        creativeSlotToInventorySlot(7) shouldBe 37
        creativeSlotToInventorySlot(8) shouldBe 36
    }

    test("offhand") {
        creativeSlotToInventorySlot(45) shouldBe 40
    }

    test("slots without an inventory equivalent") {
        (0..4).forEach { creativeSlotToInventorySlot(it) shouldBe null }
        creativeSlotToInventorySlot(-1) shouldBe null
        creativeSlotToInventorySlot(46) shouldBe null
    }

    test("every inventory slot is reachable exactly once") {
        val mapped = (-1..45).mapNotNull { creativeSlotToInventorySlot(it) }
        mapped.distinct().size shouldBe mapped.size
        mapped.toSet() shouldBe ((0..40).toSet())
    }
})
