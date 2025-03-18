package com.typewritermc.engine.paper.utils.item

import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.interaction.interactionContext
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

sealed interface Item {
    fun build(player: Player?, context: InteractionContext? = player?.interactionContext): ItemStack
    fun isSameAs(player: Player?, item: ItemStack?, context: InteractionContext? = player?.interactionContext): Boolean
    fun exactMatch(player: Player?, item: ItemStack?, context: InteractionContext? = player?.interactionContext): Boolean

    companion object {
        val Empty = CustomItem()
    }
}
