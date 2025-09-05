package com.typewritermc.engine.paper.utils.item.components.customModelDataTypes

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.serverVersion
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("float_array", Colors.GREEN, "fa6-solid:shapes")
data class FloatsCustomModelData(
    val value: List<Float> = emptyList()
) : CustomModelDataType {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return
        }
        item.editMeta { meta ->
            val component = meta.customModelDataComponent
            if (component.floats == value) return@editMeta
            component.floats = value
            meta.setCustomModelDataComponent(component)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return false
        }
        val meta = item.itemMeta ?: return false
        return meta.customModelDataComponent.floats == value
    }
}