package com.typewritermc.entity.entries.data.minecraft

import com.github.retrooper.packetevents.manager.server.ServerVersion
import com.github.retrooper.packetevents.protocol.component.builtin.item.ItemSwingAnimation
import com.github.retrooper.packetevents.protocol.component.builtin.item.ItemSwingAnimation.Type
import com.github.retrooper.packetevents.protocol.player.InteractionHand
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityAnimation
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSwingAnimation
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.ArmSwing
import com.typewritermc.engine.paper.utils.serverVersion
import me.tofaa.entitylib.wrapper.WrapperEntity

data class ArmSwingProperty(val armSwing: ArmSwing) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<ArmSwingProperty>(ArmSwingProperty::class)

    // Since this is a one time use property, we should always let it override the previous property.
    override fun equals(other: Any?): Boolean = false
    override fun hashCode(): Int = javaClass.hashCode()
}

fun ArmSwing.toProperty() = ArmSwingProperty(this)

fun applyArmSwingData(entity: WrapperEntity, property: ArmSwingProperty) {
    if (serverVersion.isNewerThanOrEquals(ServerVersion.V_26_3)) {
        if (property.armSwing.swingLeft) {
            WrapperPlayServerSwingAnimation(
                entity.entityId,
                InteractionHand.OFF_HAND,
                ItemSwingAnimation(Type.WHACK, 6)
            )
        }
        if (property.armSwing.swingRight) {
            WrapperPlayServerSwingAnimation(
                entity.entityId,
                InteractionHand.MAIN_HAND,
                ItemSwingAnimation(Type.WHACK, 6)
            )
        }

        return
    }

    if (property.armSwing.swingLeft) {
        entity.sendPacketsToViewers(
            WrapperPlayServerEntityAnimation(
                entity.entityId,
                WrapperPlayServerEntityAnimation.EntityAnimationType.SWING_OFF_HAND
            )
        )
    }
    if (property.armSwing.swingRight) {
        entity.sendPacketsToViewers(
            WrapperPlayServerEntityAnimation(
                entity.entityId,
                WrapperPlayServerEntityAnimation.EntityAnimationType.SWING_MAIN_ARM
            )
        )
    }
}
