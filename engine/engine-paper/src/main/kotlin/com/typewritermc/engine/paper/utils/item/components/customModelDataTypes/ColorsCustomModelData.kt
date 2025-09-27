package com.typewritermc.engine.paper.utils.item.components.customModelDataTypes

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.serverVersion
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("color_array", Colors.GREEN, "fa6-solid:shapes")
data class ColorsCustomModelData(
    val value: List<Color> = emptyList()
) : CustomModelDataType {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return
        }
        item.editMeta { meta ->
            val component = meta.customModelDataComponent
            val bukkitColors = value.map { it.toBukkitColor() }

            if (component.colors == bukkitColors) return@editMeta
            component.colors = bukkitColors
            meta.setCustomModelDataComponent(component)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return false
        }
        val meta = item.itemMeta ?: return false
        val bukkitColors = value.map { it.toBukkitColor() }
        return meta.customModelDataComponent.colors == bukkitColors
    }
}
