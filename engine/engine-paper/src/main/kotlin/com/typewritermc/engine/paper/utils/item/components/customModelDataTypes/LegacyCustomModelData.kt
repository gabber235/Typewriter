package com.typewritermc.engine.paper.utils.item.components.customModelDataTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("legacy_int", Colors.GREEN, "fa6-solid:shapes")
data class LegacyCustomModelData(val value: Int) : CustomModelDataType {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta -> meta.setCustomModelData(value) }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val meta = item.itemMeta ?: return false
        return meta.hasCustomModelData() && meta.customModelData == value
    }
}