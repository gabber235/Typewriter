package com.typewritermc.entity.entries.data.minecraft.display.item

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.metas
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.entity.entries.data.minecraft.display.DisplayEntityData
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import me.tofaa.entitylib.meta.display.ItemDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("item_data", "Item of an ItemDisplay.", Colors.RED, "mdi:tools")
@Tags("item_data")
class ItemData(
    override val id: String = "",
    override val name: String = "",
    val item: Var<Item> = ConstVar(Item.Empty),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<ItemProperty> {
    override fun type(): KClass<ItemProperty> = ItemProperty::class

    override fun build(player: Player): ItemProperty = ItemProperty(item.get(player))
}

data class ItemProperty(val item: Item) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<ItemProperty>(ItemProperty::class)
}

fun applyItemData(entity: WrapperEntity, property: ItemProperty, player: Player) {
    entity.metas {
        meta<ItemDisplayMeta> { item = SpigotConversionUtil.fromBukkitItemStack(property.item.build(player)) }
        error("Could not apply ItemData to ${entity.entityType} entity.")
    }
}