package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.plainText
import com.typewritermc.engine.paper.utils.stripped
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("lore", Colors.ORANGE, "flowbite:file-lines-solid")
class ItemLoreComponent(
    @Placeholder
    @Colored
    @MultiLine
    val lore: Var<String> = ConstVar(""),
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val lore = this@ItemLoreComponent.lore.get(player) ?: return@editMeta
            meta.lore(lore.parsePlaceholders(player).split("\n").map { it.asMini() })
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val lore = lore.get(player) ?: return false
        return item.lore()?.joinToString("\n") { it.plainText() } == lore.parsePlaceholders(player).stripped()
    }
}