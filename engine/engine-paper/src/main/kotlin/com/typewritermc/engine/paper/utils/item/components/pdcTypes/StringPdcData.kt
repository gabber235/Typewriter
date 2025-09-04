package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("persistent_data_string", Colors.PURPLE, "fa6-solid:database")
data class StringPdcData(val value: String) : PdcDataType {
    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey) {
        item.editMeta { meta ->
            if (value.isBlank()) {
                meta.persistentDataContainer.remove(key)
            } else {
                meta.persistentDataContainer.set(key, PersistentDataType.STRING, value)
            }
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey): Boolean {
        val actual = item.itemMeta?.persistentDataContainer?.get(key, PersistentDataType.STRING)
        return if (value.isBlank()) {
            actual.isNullOrBlank()
        } else {
            actual == value
        }
    }
}