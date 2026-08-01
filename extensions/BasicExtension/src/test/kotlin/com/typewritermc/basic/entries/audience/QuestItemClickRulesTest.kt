package com.typewritermc.basic.entries.audience

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import org.bukkit.event.inventory.InventoryAction
import org.bukkit.event.inventory.InventoryAction.*

private fun escapes(
    action: InventoryAction,
    inOwnInventory: Boolean = true,
    ownScreen: Boolean = false,
    slot: Boolean = false,
    cursor: Boolean = false,
    swapIn: Boolean = false,
) = clickEscapesInventory(action, inOwnInventory, ownScreen, slot, cursor, swapIn)

class QuestItemClickRulesTest : FunSpec({
    test("the item moves freely inside the player's own inventory, armor slots and offhand included") {
        escapes(PLACE_ALL, inOwnInventory = true, cursor = true) shouldBe false
        escapes(SWAP_WITH_CURSOR, inOwnInventory = true, cursor = true) shouldBe false
        escapes(PICKUP_ALL, inOwnInventory = true, slot = true) shouldBe false
    }

    test("the item cannot be placed into an open container") {
        escapes(PLACE_ALL, inOwnInventory = false, cursor = true) shouldBe true
        escapes(PLACE_ONE, inOwnInventory = false, cursor = true) shouldBe true
        escapes(SWAP_WITH_CURSOR, inOwnInventory = false, cursor = true) shouldBe true
    }

    test("shift clicking moves within the player's own screen but not into a container") {
        escapes(MOVE_TO_OTHER_INVENTORY, inOwnInventory = true, ownScreen = true, slot = true) shouldBe false
        escapes(MOVE_TO_OTHER_INVENTORY, inOwnInventory = true, ownScreen = false, slot = true) shouldBe true
    }

    test("number key and offhand swaps cannot push it into a container") {
        escapes(HOTBAR_SWAP, inOwnInventory = false, swapIn = true) shouldBe true
        escapes(HOTBAR_SWAP, inOwnInventory = true, swapIn = true) shouldBe false
    }

    test("it cannot be dropped from the slot or the cursor") {
        escapes(DROP_ALL_SLOT, slot = true) shouldBe true
        escapes(DROP_ONE_SLOT, slot = true) shouldBe true
        escapes(DROP_ALL_CURSOR, cursor = true) shouldBe true
        escapes(DROP_ONE_CURSOR, cursor = true) shouldBe true
    }

    test("it cannot be hidden inside a bundle, but may come out of one") {
        escapes(PLACE_ALL_INTO_BUNDLE, cursor = true) shouldBe true
        escapes(PICKUP_ALL_INTO_BUNDLE, slot = true) shouldBe true
        escapes(PLACE_FROM_BUNDLE, slot = true, cursor = true) shouldBe false
        escapes(PICKUP_FROM_BUNDLE, slot = true, cursor = true) shouldBe false
    }

    test("it cannot come out of a bundle straight into a container") {
        escapes(PLACE_FROM_BUNDLE, inOwnInventory = false, cursor = true) shouldBe true
        escapes(PICKUP_FROM_BUNDLE, inOwnInventory = false, slot = true) shouldBe false
    }

    test("a bundle carrying the item is stopped everywhere the item is") {
        escapes(MOVE_TO_OTHER_INVENTORY, inOwnInventory = true, ownScreen = false, slot = true) shouldBe true
        escapes(PLACE_ALL, inOwnInventory = false, cursor = true) shouldBe true
        escapes(DROP_ALL_SLOT, slot = true) shouldBe true
    }

    test("it cannot be cloned in creative") {
        escapes(CLONE_STACK, slot = true) shouldBe true
    }

    test("a leaked copy can be taken back out of a container") {
        escapes(PICKUP_ALL, inOwnInventory = false, slot = true) shouldBe false
        escapes(MOVE_TO_OTHER_INVENTORY, inOwnInventory = false, slot = true) shouldBe false
    }

    test("nothing is blocked when no quest item is involved") {
        InventoryAction.entries.forEach { action ->
            escapes(action, inOwnInventory = false) shouldBe false
            escapes(action, inOwnInventory = true) shouldBe false
        }
    }
})
