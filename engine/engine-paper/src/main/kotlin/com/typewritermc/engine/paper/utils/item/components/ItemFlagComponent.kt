package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemFlag
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("flag", Colors.BLUE, "material-symbols:flag")
class ItemFlagComponent(
    val flag: ItemFlag,
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) = item.addItemFlags(flag)
    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean = item.hasItemFlag(flag)
}