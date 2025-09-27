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

@AlgebraicTypeInfo("item_model", Colors.BLUE, "fa6-solid:layer-group")
class ItemModelComponent(
    val modelKey: Var<String> = ConstVar("")
) : ItemComponent {

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val raw = modelKey.get(player, interactionContext)?.trim().orEmpty()
            if (raw.isEmpty()) {
                meta.itemModel = null
                return@editMeta
            }

            val key = NamespacedKey.fromString(raw)
            if (key == null) {
                meta.itemModel = null
                return@editMeta
            }

            meta.itemModel = key
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedRaw = modelKey.get(player, interactionContext)?.trim().orEmpty()
        val actual = item.itemMeta?.itemModel

        if (expectedRaw.isEmpty()) {
            return actual == null
        }

        val expected = NamespacedKey.fromString(expectedRaw) ?: return actual == null
        return actual == expected
    }
}
