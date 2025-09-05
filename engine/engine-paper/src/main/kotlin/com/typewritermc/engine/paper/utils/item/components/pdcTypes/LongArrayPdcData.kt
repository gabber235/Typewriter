package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
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
            val container = meta.persistentDataContainer
            if (value.isEmpty()) {
                container.remove(key)
            } else {
                container.set(key, PersistentDataType.LONG_ARRAY, toLongArray())
            }
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val expected = toLongArray()
        val container = item.itemMeta?.persistentDataContainer
            ?: return expected.isEmpty()
        val actual = container.get(key, PersistentDataType.LONG_ARRAY)
        return when {
            actual == null -> expected.isEmpty()
            else -> actual.contentEquals(expected)
        }
    }
}
