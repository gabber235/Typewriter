package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.InnerMin
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@Suppress("UnstableApiUsage")
@AlgebraicTypeInfo("custom_model_data", Colors.GREEN, "fa6-solid:shapes")
class ItemCustomModelDataComponent(
    @InnerMin(Min(0))
    @Default("0")

    val customModelData: Var<Int> = ConstVar(0),
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val modelData = customModelData.get(player) ?: return@editMeta
            val modelDataComponent = meta.customModelDataComponent

            if (modelData == 0) {
                modelDataComponent.floats = emptyList()
            } else {
                modelDataComponent.floats = listOf(modelData.toFloat())
            }
            meta.setCustomModelDataComponent(modelDataComponent)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedModelData = customModelData.get(player) ?: return false
        val actualComponent = item.itemMeta?.customModelDataComponent
        val actualFloats = actualComponent?.floats ?: emptyList()

        val expectedFloats = if (expectedModelData == 0) {
            emptyList()
        } else {
            listOf(expectedModelData.toFloat())
        }

        return actualFloats == expectedFloats
    }
}