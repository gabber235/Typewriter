package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("tooltip_style", Colors.CYAN, "fa6-solid:palette")
class ItemTooltipStyleComponent(
    @Default("\"minecraft\"")
    val namespace: Var<String> = ConstVar("minecraft"),
    @Default("\"default\"")
    val key: Var<String> = ConstVar("default"),
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val namespaceValue = namespace.get(player, interactionContext) ?: return@editMeta
            val keyValue = key.get(player, interactionContext) ?: return@editMeta
            val namespacedKey = NamespacedKey(namespaceValue, keyValue)
            if (meta.tooltipStyle == namespacedKey) return@editMeta
            meta.tooltipStyle = namespacedKey
        }
    }


    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedNamespace = namespace.get(player, interactionContext) ?: return false
        val expectedKey = key.get(player, interactionContext) ?: return false
        val actualStyle = item.itemMeta?.tooltipStyle
        val expectedNamespacedKey = NamespacedKey(expectedNamespace, expectedKey)
        return actualStyle == expectedNamespacedKey
    }
}