package com.typewritermc.entity.entries.data.minecraft.living

import com.github.retrooper.packetevents.protocol.item.ItemStack
import com.github.retrooper.packetevents.protocol.player.EquipmentSlot
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.toPacketItem
import com.typewritermc.engine.paper.utils.item.Item
import me.tofaa.entitylib.wrapper.WrapperLivingEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("equipment_data", "Equipment data", Colors.RED, "game-icons:chest-armor")
@Tags("equipment_data")
class EquipmentData(
    override val id: String = "",
    override val name: String = "",
    val equipment: Map<EquipmentSlot, Var<Item>> = emptyMap(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LivingEntityData<EquipmentProperty> {
    override fun type(): KClass<EquipmentProperty> = EquipmentProperty::class

    override fun build(player: Player): EquipmentProperty =
        EquipmentProperty(equipment.mapValues { (_, item) -> item.get(player).build(player).toPacketItem() })
}

@Entry("viewer_equipment_data", "The equipment of the viewer", Colors.RED, "mdi:account-multiple-outline")
class ViewerEquipmentData(
    override val id: String = "",
    override val name: String = "",
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LivingEntityData<EquipmentProperty> {
    override fun type(): KClass<EquipmentProperty> = EquipmentProperty::class

    // The kotlin compiler thinks that equipment can be null, but it is not.
    // So we wait until they fix it.
    // The current date is 2025-02-08
    override fun build(player: Player): EquipmentProperty =
        player.equipmentProperty()
}

data class EquipmentProperty(val data: Map<EquipmentSlot, ItemStack>) : EntityProperty {
    constructor(equipmentSlot: EquipmentSlot, item: ItemStack) : this(mapOf(equipmentSlot to item))

    companion object : PropertyCollectorSupplier<EquipmentProperty> {
        override val type: KClass<EquipmentProperty> = EquipmentProperty::class

        override fun collector(suppliers: List<PropertySupplier<out EquipmentProperty>>): PropertyCollector<EquipmentProperty> {
            return EquipmentCollector(suppliers.filterIsInstance<PropertySupplier<EquipmentProperty>>())
        }
    }
}

fun Player.equipmentProperty(): EquipmentProperty {
    val equipment = equipment ?: return EquipmentProperty(emptyMap())
    return EquipmentProperty(org.bukkit.inventory.EquipmentSlot.entries.mapNotNull { slot ->
        if (!canUseEquipmentSlot(slot)) return@mapNotNull null
        val item = equipment.getItem(slot)
        if (item.isEmpty) return@mapNotNull null
        slot.toPacketEquipmentSlot() to item.toPacketItem()
    }.toMap())
}

fun org.bukkit.inventory.EquipmentSlot.toPacketEquipmentSlot() = when (this) {
    org.bukkit.inventory.EquipmentSlot.HAND -> EquipmentSlot.MAIN_HAND
    org.bukkit.inventory.EquipmentSlot.OFF_HAND -> EquipmentSlot.OFF_HAND
    org.bukkit.inventory.EquipmentSlot.HEAD -> EquipmentSlot.HELMET
    org.bukkit.inventory.EquipmentSlot.CHEST -> EquipmentSlot.CHEST_PLATE
    org.bukkit.inventory.EquipmentSlot.LEGS -> EquipmentSlot.LEGGINGS
    org.bukkit.inventory.EquipmentSlot.FEET -> EquipmentSlot.BOOTS
    else -> EquipmentSlot.CHEST_PLATE
}

private class EquipmentCollector(
    private val suppliers: List<PropertySupplier<EquipmentProperty>>,
) : PropertyCollector<EquipmentProperty> {
    override val type: KClass<EquipmentProperty> = EquipmentProperty::class

    override fun collect(player: Player): EquipmentProperty {
        val properties = suppliers.associateWith {
            it.build(player)
        }
        val applicableProperties = properties.filter { (s, _) -> s.canApply(player) }.map { it.value }
        val data = mutableMapOf<EquipmentSlot, ItemStack>()
        applicableProperties.asSequence()
            .flatMap { it.data.asSequence() }
            .filter { (slot, _) -> !data.containsKey(slot) }
            .forEach { (slot, item) -> data[slot] = item }

        // Reset empty slots
        val slots = properties.values.flatMap { it.data.keys }.toSet()
        slots.filter { !data.containsKey(it) }
            .forEach { data[it] = ItemStack.EMPTY }

        return EquipmentProperty(data)
    }
}

fun applyEquipmentData(entity: WrapperLivingEntity, property: EquipmentProperty) {
    property.data.forEach { (slot, item) ->
        if (item.isEmpty) entity.equipment.setItem(slot, null)
        else entity.equipment.setItem(slot, item)
    }
}