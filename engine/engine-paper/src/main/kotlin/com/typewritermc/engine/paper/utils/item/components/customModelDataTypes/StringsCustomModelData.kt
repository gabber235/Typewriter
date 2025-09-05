package com.typewritermc.engine.paper.utils.item.components.customModelDataTypes

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.serverVersion
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("string_array", Colors.GREEN, "fa6-solid:shapes")
data class StringsCustomModelData(

    val value: List<String> = emptyList()

) : CustomModelDataType {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return
        }
        item.editMeta { meta ->
            val component = meta.customModelDataComponent
            if (component.strings == value) return@editMeta
            component.strings = value
            meta.setCustomModelDataComponent(component)
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        if (!serverVersion.isNewerThanOrEquals(ServerVersion.V_1_21_4)) {
            logger.warning("${this::class.simpleName} is only supported in versions 1.21.4 and above")
            return false
        }
        val meta = item.itemMeta ?: return false
        return meta.customModelDataComponent.strings == value
    }
}