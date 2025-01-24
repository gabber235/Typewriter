package com.typewritermc.engine.paper.utils.item

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.utils.item.components.ItemComponent
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("custom_item", Colors.BLUE, "mdi:shape")
class CustomItem(
    private val components: List<ItemComponent> = emptyList(),
) : Item {
    override fun build(player: Player?, context: InteractionContext?): ItemStack {
        val itemStack = ItemStack(Material.AIR, 1)
        components.forEach {
            it.apply(player, context, itemStack)
        }
        return itemStack
    }

    override fun isSameAs(player: Player?, item: ItemStack?, context: InteractionContext?): Boolean =
        build(player, context).isSimilar(item)
}