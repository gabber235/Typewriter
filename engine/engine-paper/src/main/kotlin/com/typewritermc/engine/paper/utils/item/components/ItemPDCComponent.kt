package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import org.bukkit.persistence.PersistentDataType

@AlgebraicTypeInfo("persistent_data_container", Colors.PURPLE, "fa6-solid:database")
class ItemPDCComponent(
    @Default("\"typewriter\"")
    val namespace: Var<String> = ConstVar("typewriter"),
    @Default("\"custom_data\"")
    val key: Var<String> = ConstVar("custom_data"),
    val value: Var<String> = ConstVar(""),
) : ItemComponent {

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val namespaceValue = namespace.get(player, interactionContext) ?: return@editMeta
            val keyValue = key.get(player, interactionContext) ?: return@editMeta
            val valueValue = value.get(player, interactionContext) ?: return@editMeta

            val namespacedKey = NamespacedKey(namespaceValue, keyValue)

            if (valueValue.isBlank()) {
                meta.persistentDataContainer.remove(namespacedKey)
            } else {
                meta.persistentDataContainer.set(namespacedKey, PersistentDataType.STRING, valueValue)
            }
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val expectedNamespace = namespace.get(player, interactionContext) ?: return false
        val expectedKey = key.get(player, interactionContext) ?: return false
        val expectedValue = value.get(player, interactionContext) ?: return false

        val namespacedKey = NamespacedKey(expectedNamespace, expectedKey)
        val actualValue = item.itemMeta?.persistentDataContainer?.get(namespacedKey, PersistentDataType.STRING)

        return if (expectedValue.isBlank()) {
            actualValue == null
        } else {
            actualValue == expectedValue
        }
    }
}