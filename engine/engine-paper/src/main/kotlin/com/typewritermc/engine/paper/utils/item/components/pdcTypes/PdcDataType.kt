package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

sealed interface PdcDataType {
    fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey)
    fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey): Boolean
}