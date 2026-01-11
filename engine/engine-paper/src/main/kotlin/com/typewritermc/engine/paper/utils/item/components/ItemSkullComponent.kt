package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.applySkinUrl
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.inventory.meta.SkullMeta

@AlgebraicTypeInfo("textured_skull", Colors.YELLOW, "fa6-solid:skull")
class ItemSkullComponent(
    @Help("The texture value or url of the skull")
    @Placeholder
    val texture: Var<String> = ConstVar("")
) : ItemComponent {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        val url = texture.get(player) ?: return
        if (url.isEmpty()) return

        if (item.type != Material.PLAYER_HEAD) return

        val meta = item.itemMeta as? SkullMeta ?: return
        meta.applySkinUrl(url)
        item.itemMeta = meta
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        if (texture.get(player).isNullOrEmpty()) return true
        return item.type == Material.PLAYER_HEAD
    }
}
