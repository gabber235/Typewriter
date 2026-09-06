package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.attribute.Attributes
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerUpdateAttributes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityOverlay
import com.typewritermc.visibility.packet.EntityPacketHook
import com.typewritermc.visibility.packet.WrapperPlayServerSpawnInfo
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.attribute.Attribute
import org.bukkit.entity.Player

@Entry(
    "scale_visibility_effect",
    "Changes the size the viewer sees the target at",
    Colors.ORANGE,
    "fa6-solid:up-right-and-down-left-from-center"
)
/**
 * The `Scale Visibility Effect` changes the scale attribute of the target, but only for the
 * viewer. Everyone else keeps seeing the target at their real size.
 *
 * The scale is resolved for the viewer when the effect activates and stays fixed after that.
 *
 * ## How could this be used?
 * Shrink other players while a player is under a growth potion story effect, or make a boss
 * player appear towering to the players fighting them.
 */
class ScaleVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The scale the viewer sees the target at, 1.0 is the normal size.")
    @Default("0.5")
    val scale: Var<Double> = ConstVar(0.5),
    @Help("Also apply this effect to the target's own view of themselves.")
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = true

    override fun appliesToSelf(viewer: Player): Boolean = self.get(viewer)

    override fun constantSelf(): Boolean? = (self as? ConstVar)?.value

    override fun createEffector(rule: VisibilityRule): VisibilityEffector = ScaleVisibilityEffector(rule, scale)
}

private class ScaleVisibilityEffector(
    rule: VisibilityRule,
    private val scale: Var<Double>,
) : VisibilityEffector, EntityPacketHook {
    private val overlay = EntityOverlay(rule)

    @Volatile
    private var scaleValue = 1.0

    override suspend fun initialize() = overlay.attach(this) { viewer, target ->
        scaleValue = scale.get(viewer)
        scalePacket(target.entityId, scaleValue) sendPacketTo viewer
    }

    override fun onAttributes(packet: WrapperPlayServerUpdateAttributes) {
        val existing = packet.properties.firstOrNull { it.attribute == Attributes.SCALE }
        if (existing == null) {
            packet.properties = packet.properties + scaleProperty(scaleValue)
            return
        }
        existing.value = scaleValue
        existing.modifiers = emptyList()
        existing.setDirty()
    }

    /**
     * A spawn only carries an attributes packet when the target has client syncable attributes to
     * report, so there is not always a packet to add the scale to. Sending it again after the spawn is
     * what preserves the effect across a re add.
     */
    override fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) =
        overlay.resendAfterSpawn(event) { entityId -> scalePacket(entityId, scaleValue) }

    override suspend fun dispose() = overlay.detach(this) { viewer, target, entityId ->
        scalePacket(entityId, target.serverSideScale()) sendPacketTo viewer
    }

    private fun Player.serverSideScale(): Double = getAttribute(Attribute.SCALE)?.value ?: 1.0

    private fun scalePacket(entityId: Int, value: Double) =
        WrapperPlayServerUpdateAttributes(entityId, listOf(scaleProperty(value)))

    private fun scaleProperty(value: Double) =
        WrapperPlayServerUpdateAttributes.Property(Attributes.SCALE, value, emptyList())
}
