package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("long", Colors.PURPLE, "fa6-solid:database")
data class LongPdcData(
    val value: Long = 0L
) : PdcDataType {


    override fun apply(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ) {
        item.editMeta { meta ->
            val pdc = meta.persistentDataContainer
            if (pdc.get(key, PersistentDataType.LONG) != value) {
                pdc.set(key, PersistentDataType.LONG, value)
            }
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val container = item.itemMeta?.persistentDataContainer ?: return false
        return container.get(key, PersistentDataType.LONG) == value
    }
}
