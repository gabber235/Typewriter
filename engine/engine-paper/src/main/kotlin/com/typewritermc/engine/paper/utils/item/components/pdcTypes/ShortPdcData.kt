package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo

import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("short", Colors.PURPLE, "fa6-solid:database")
data class ShortPdcData(
    val value: Short = 0
) : PdcDataType {

    override fun apply(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ) {
        item.editMeta { meta ->
            meta.persistentDataContainer.set(key, PersistentDataType.SHORT, value)
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val container = item.itemMeta?.persistentDataContainer ?: return false
        return container.get(key, PersistentDataType.SHORT) == value
    }




}
