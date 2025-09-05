package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("long_array", Colors.PURPLE, "fa6-solid:database")
data class LongArrayPdcData(

    val value: List<Long> = emptyList()

) : PdcDataType {

    private fun toLongArray(): LongArray =
        value.toLongArray()

    override fun apply(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ) {
        item.editMeta { meta ->
            meta.persistentDataContainer.set(key, PersistentDataType.LONG_ARRAY, toLongArray())
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val container = item.itemMeta?.persistentDataContainer ?: return false
        val actual = container.get(key, PersistentDataType.LONG_ARRAY) ?: return false
        return actual.contentEquals(toLongArray())
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as LongArrayPdcData
        return value == other.value
    }

    override fun hashCode(): Int = value.hashCode()
}
