package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("int_array", Colors.PURPLE, "fa6-solid:database")
data class IntArrayPdcData(

    val value: List<Int> = emptyList()

) : PdcDataType {

    private fun toIntArray(): IntArray = value.toIntArray()

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey) {
        item.editMeta { meta ->
            meta.persistentDataContainer.set(key, PersistentDataType.INTEGER_ARRAY, toIntArray())
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val container = item.itemMeta?.persistentDataContainer ?: return false
        val actual = container.get(key, PersistentDataType.INTEGER_ARRAY) ?: return false
        return actual.contentEquals(toIntArray())
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as IntArrayPdcData
        return value == other.value
    }

    override fun hashCode(): Int = value.hashCode()
}
