package com.typewritermc.engine.paper.utils.item.components.customModelDataTypes

import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

sealed interface CustomModelDataType {
    fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack)
    fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean
}