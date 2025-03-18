package com.typewritermc.engine.paper.utils.item

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.utils.item.components.ItemAmountComponent
import com.typewritermc.engine.paper.utils.item.components.ItemComponent
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("custom_item", Colors.BLUE, "mdi:shape")
class CustomItem(
    val components: List<ItemComponent> = emptyList(),
) : Item {
    inline fun <reified C : ItemComponent> components(): List<C> = components.filterIsInstance<C>()
    inline fun <reified C : ItemComponent> firstComponent(): C? = components.firstOrNull { it is C } as C?

    override fun build(player: Player?, context: InteractionContext?): ItemStack {
        val itemStack = ItemStack(Material.AIR, 1)
        components.forEach {
            it.apply(player, context, itemStack)
        }
        return itemStack
    }

    override fun isSameAs(player: Player?, item: ItemStack?, context: InteractionContext?): Boolean {
        if (item == null) return components.isEmpty()

        // When we match for components, we ignore the amount as it is not actually a component.
        // Otherwise, things like the remove item break because they are searching for an exact match.
        return components.filter { it !is ItemAmountComponent }.all { it.matches(player, context, item) }
    }

    override fun exactMatch(player: Player?, item: ItemStack?, context: InteractionContext?): Boolean {
        if (item == null) return components.isEmpty()

        return components.all { it.matches(player, context, item) }
    }
}