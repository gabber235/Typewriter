package com.typewritermc.engine.paper.utils.item.components.pdcTypes

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Max
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.interaction.InteractionContext
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("long", Colors.PURPLE, "fa6-solid:database")
data class LongPdcData(

    @Min(Int.MIN_VALUE)
    @Max(Int.MAX_VALUE)
    val value: Int = 0

) : PdcDataType {

    private fun asLong(): Long = value.toLong()

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack, key: NamespacedKey) {
        item.editMeta { meta ->
            meta.persistentDataContainer.set(key, PersistentDataType.LONG, asLong())
        }
    }

    override fun matches(
        player: Player?,
        interactionContext: InteractionContext?,
        item: ItemStack,
        key: NamespacedKey
    ): Boolean {
        val container = item.itemMeta?.persistentDataContainer ?: return false
        return container.get(key, PersistentDataType.LONG) == asLong()
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as LongPdcData
        return value == other.value
    }

    override fun hashCode(): Int = value
}
