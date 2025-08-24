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
    @Default("\"\"")
    val value: Var<String> = ConstVar(""),
) : ItemComponent {

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        item.editMeta { meta ->
            val ns = namespace.get(player, interactionContext)?.trim()?.takeIf { it.isNotEmpty() } ?: return@editMeta
            val k = key.get(player, interactionContext)?.trim()?.takeIf { it.isNotEmpty() } ?: return@editMeta
            val v = value.get(player, interactionContext)?.trim() ?: return@editMeta

            val namespacedKey = try {
                NamespacedKey(ns, k)
            } catch (_: IllegalArgumentException) {
                return@editMeta
            }

            if (v.isBlank()) {
                meta.persistentDataContainer.remove(namespacedKey)
            } else {
                meta.persistentDataContainer.set(namespacedKey, PersistentDataType.STRING, v)
            }
        }
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val ns = namespace.get(player, interactionContext)?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        val k = key.get(player, interactionContext)?.trim()?.takeIf { it.isNotEmpty() } ?: return false
        val expected = value.get(player, interactionContext)?.trim() ?: return false

        val namespacedKey = try {
            NamespacedKey(ns, k)
        } catch (_: IllegalArgumentException) {
            return false
        }
        val actualValue = item.itemMeta?.persistentDataContainer?.get(namespacedKey, PersistentDataType.STRING)

        return if (expected.isBlank()) {
            actualValue.isNullOrBlank()
        } else {
            actualValue == expected
        }
    }
}