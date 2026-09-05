package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.player.Equipment
import com.github.retrooper.packetevents.protocol.player.EquipmentSlot
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityEquipment
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.extensions.packetevents.toPacketItem
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityOverlay
import com.typewritermc.visibility.packet.EntityPacketHook
import com.typewritermc.visibility.packet.WrapperPlayServerSpawnInfo
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player
import com.github.retrooper.packetevents.protocol.item.ItemStack as PacketItemStack

/**
 * How the target's armor is changed for the viewer.
 */
sealed interface ArmorModification

/**
 * Removes all armor from the target's rendering.
 */
@AlgebraicTypeInfo("hidden", Colors.RED, "mdi:shield-off")
class HiddenArmor : ArmorModification {
    override fun equals(other: Any?): Boolean = other is HiddenArmor
    override fun hashCode(): Int = javaClass.hashCode()
}

/**
 * Replaces the target's armor with the configured items.
 * Slots left empty render as no armor.
 */
@AlgebraicTypeInfo("replaced", Colors.BLUE, "mdi:shield-sync")
data class ReplacedArmor(
    val helmet: Var<Item> = ConstVar(Item.Empty),
    val chestplate: Var<Item> = ConstVar(Item.Empty),
    val leggings: Var<Item> = ConstVar(Item.Empty),
    val boots: Var<Item> = ConstVar(Item.Empty),
) : ArmorModification

@Entry(
    "armor_visibility_effect",
    "Changes the armor the viewer sees on the target",
    Colors.MYRTLE_GREEN,
    "mdi:shield-account"
)
/**
 * The `Armor Visibility Effect` hides or replaces the armor the viewer sees on the target.
 * The target's real inventory is never touched.
 *
 * Replacement items are resolved for the viewer when the effect activates and stay fixed after that.
 *
 * ## How could this be used?
 * Strip the armor of players in a story cutscene, or dress the members of an enemy faction in
 * the same uniform when a player looks at them.
 */
class ArmorVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("How the target's armor is changed for the viewer.")
    val modification: ArmorModification = HiddenArmor(),
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        ArmorVisibilityEffector(rule, modification)
}

private class ArmorVisibilityEffector(
    private val rule: VisibilityRule,
    private val modification: ArmorModification,
) : VisibilityEffector, EntityPacketHook {
    private val overlay = EntityOverlay(rule)

    @Volatile
    private var overrides: Map<EquipmentSlot, PacketItemStack> = emptyMap()

    override suspend fun initialize() {
        if (rule.isSelf) return
        overlay.attach(this) { viewer, target ->
            overrides = buildOverrides(viewer)
            WrapperPlayServerEntityEquipment(
                target.entityId,
                overrides.map { (slot, item) -> Equipment(slot, item) },
            ) sendPacketTo viewer
        }
    }

    override fun onEquipment(packet: WrapperPlayServerEntityEquipment) {
        packet.equipment = packet.equipment.map { equipment ->
            val replacement = overrides[equipment.slot] ?: return@map equipment
            Equipment(equipment.slot, replacement)
        }
    }

    /**
     * The equipment packet accompanying a spawn lists only the slots the target actually has filled,
     * and is omitted entirely when they have none. Rewriting it can therefore never introduce a
     * replacement for an empty slot, so the whole override is sent again after a spawn.
     */
    override fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) =
        overlay.resendAfterSpawn(event) { entityId ->
            val equipment = overrides.map { (slot, item) -> Equipment(slot, item) }
            if (equipment.isEmpty()) null else WrapperPlayServerEntityEquipment(entityId, equipment)
        }

    override suspend fun dispose() = overlay.detach(this) { viewer, target, entityId ->
        WrapperPlayServerEntityEquipment(entityId, target.serverSideArmor()) sendPacketTo viewer
    }

    private fun buildOverrides(viewer: Player): Map<EquipmentSlot, PacketItemStack> = when (modification) {
        is HiddenArmor -> ARMOR_SLOTS.associateWith { PacketItemStack.EMPTY }
        is ReplacedArmor -> mapOf(
            EquipmentSlot.HELMET to modification.helmet.toPacketItem(viewer),
            EquipmentSlot.CHEST_PLATE to modification.chestplate.toPacketItem(viewer),
            EquipmentSlot.LEGGINGS to modification.leggings.toPacketItem(viewer),
            EquipmentSlot.BOOTS to modification.boots.toPacketItem(viewer),
        )
    }

    private fun Var<Item>.toPacketItem(viewer: Player): PacketItemStack =
        get(viewer).build(viewer).toPacketItem()

    private fun Player.serverSideArmor(): List<Equipment> = listOf(
        Equipment(EquipmentSlot.HELMET, inventory.helmet?.toPacketItem() ?: PacketItemStack.EMPTY),
        Equipment(EquipmentSlot.CHEST_PLATE, inventory.chestplate?.toPacketItem() ?: PacketItemStack.EMPTY),
        Equipment(EquipmentSlot.LEGGINGS, inventory.leggings?.toPacketItem() ?: PacketItemStack.EMPTY),
        Equipment(EquipmentSlot.BOOTS, inventory.boots?.toPacketItem() ?: PacketItemStack.EMPTY),
    )

    private companion object {
        val ARMOR_SLOTS = listOf(
            EquipmentSlot.HELMET,
            EquipmentSlot.CHEST_PLATE,
            EquipmentSlot.LEGGINGS,
            EquipmentSlot.BOOTS,
        )
    }
}
