package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import kotlin.reflect.cast

@Entry(
    "selected_slot_variable",
    "The slot the player has selected in their hotbar",
    Colors.GREEN,
    "qlementine-icons:empty-slot-16"
)
@GenericConstraint(Int::class)
/**
 * The `Selected Slot Variable` entry is a variable that returns the slot the player has selected in their hotbar.
 *
 * ## How could this be used?
 * This could be use to replace the player's current item with another item.
 */
class SelectedSlotVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        return context.cast(context.player.inventory.heldItemSlot)
    }
}