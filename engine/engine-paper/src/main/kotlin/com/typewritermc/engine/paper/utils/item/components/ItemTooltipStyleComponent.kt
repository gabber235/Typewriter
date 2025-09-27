package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("tooltip_style", Colors.CYAN, "fa6-solid:palette")
class ItemTooltipStyleComponent(
    val styleKey: Var<String> = ConstVar("minecraft:diamond"),
) : ItemComponent {

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val raw = styleKey.get(player, interactionContext)?.trim().orEmpty()
            if (raw.isEmpty()) {
                meta.tooltipStyle = null
                return@editMeta
            }

            val key = NamespacedKey.fromString(raw)
            if (key == null) {
                meta.tooltipStyle = null
                return@editMeta
            }

            if (meta.tooltipStyle != key) {
                meta.tooltipStyle = key
            }
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val raw = styleKey.get(player, interactionContext)?.trim().orEmpty()
        val actual = item.itemMeta?.tooltipStyle

        if (raw.isEmpty()) {
            return actual == null
        }

        val expected = NamespacedKey.fromString(raw) ?: return actual == null
        return actual == expected
    }
}
