package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("amount", Colors.BLUE, "fa6-solid:hashtag")
class ItemAmountComponent(
    @InnerMin(Min(0))
    @Default("1")
    val amount: Var<Int> = ConstVar(1),
): ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.amount = amount.get(player, interactionContext) ?: 1
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val amount = amount.get(player, interactionContext) ?: 0
        return item.amount == amount
    }
}