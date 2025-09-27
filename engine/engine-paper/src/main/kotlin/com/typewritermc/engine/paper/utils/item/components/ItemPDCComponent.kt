package com.typewritermc.engine.paper.utils.item.components

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.item.components.pdcTypes.PdcDataType
import com.typewritermc.engine.paper.utils.item.components.pdcTypes.StringPdcData
import org.bukkit.NamespacedKey
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack

@AlgebraicTypeInfo("persistent_data_container", Colors.PURPLE, "fa6-solid:database")
class ItemPDCComponent(
    val dataKey: Var<String> = ConstVar("typewriter:custom_data"),
    val data: Var<PdcDataType> = ConstVar(StringPdcData("")),
) : ItemComponent {

    override fun apply(player: Player?, interactionContext: InteractionContext?, item: ItemStack) {
        val raw = dataKey.get(player, interactionContext)?.trim().orEmpty()
        if (raw.isEmpty()) return

        val namespacedKey = NamespacedKey.fromString(raw) ?: return
        data.get(player, interactionContext)?.apply(player, interactionContext, item, namespacedKey)
    }

    override fun matches(player: Player?, interactionContext: InteractionContext?, item: ItemStack): Boolean {
        val raw = dataKey.get(player, interactionContext)?.trim().orEmpty()
        if (raw.isEmpty()) return false

        val namespacedKey = NamespacedKey.fromString(raw) ?: return false
        val pdcData = data.get(player, interactionContext) ?: return false
        return pdcData.matches(player, interactionContext, item, namespacedKey)
    }
}
