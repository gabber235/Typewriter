package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.item.components.customModelDataTypes.CustomModelDataType
import com.typewritermc.engine.paper.utils.item.components.customModelDataTypes.LegacyCustomModelData
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("custom_model_data", Colors.GREEN, "fa6-solid:shapes")
class ItemCustomModelDataComponent(
    val customModelData: Var<CustomModelDataType> = ConstVar(LegacyCustomModelData(0)),
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        customModelData.get(player, interactionContext)?.apply(player, interactionContext, item)
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val modelData = customModelData.get(player, interactionContext) ?: return false
        return modelData.matches(player, interactionContext, item)
    }
}