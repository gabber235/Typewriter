package com.typewritermc.entity.entries.data.minecraft.living.panda

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.PandaMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.Optional
import kotlin.reflect.KClass

/**
 * High-level pose abstraction for pandas. Some poses are represented by bit flags (sitting, rolling, on back),
 * others by timers (sneezing in progress, eating) or a combination.
 * We expose a unified enum so designers can easily pick one desired state.
 */
@Entry("panda_pose_data", "Select the panda's pose / activity state", Colors.RED, "mdi:gesture-double-tap")
@Tags("panda_pose_data", "panda_data")
class PandaPoseData(
    override val id: String = "",
    override val name: String = "",
    /** Which pose to apply */
    @Default("STANDING")
    val pose: PandaPose = PandaPose.STANDING,
    /** Timers (in ticks) used when a pose requires an active timer */
    val sneezeTicks: Int = 20,
    val eatTicks: Int = 40,
    /** Optional explicit override priority */
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<PandaPoseProperty> {
    override fun type(): KClass<PandaPoseProperty> = PandaPoseProperty::class
    override fun build(player: Player): PandaPoseProperty = PandaPoseProperty(pose, sneezeTicks, eatTicks)
}

enum class PandaPose {
    STANDING,          // Neutral state (clear all flags & timers)
    SITTING,           // Sitting bit
    LYING_ON_BACK,     // On back bit
    ROLLING,           // Rolling bit
    SNEEZING,          // Sets sneeze timer (>0) briefly
    EATING,            // Sets eat timer (>0)
    SITTING_EATING     // Sitting bit + eat timer simultaneously
}

data class PandaPoseProperty(
    val pose: PandaPose,
    val sneezeTicks: Int,
    val eatTicks: Int,
) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<PandaPoseProperty>(PandaPoseProperty::class, PandaPoseProperty(PandaPose.STANDING, 0, 0))
}

fun applyPandaPoseData(entity: WrapperEntity, property: PandaPoseProperty) {
    entity.metas {
        meta<PandaMeta> {
            // reset common flags first
            setRolling(false)
            setSitting(false)
            setOnBack(false)
            setSneezeTimer(0)
            setEatTimer(0)

            when (property.pose) {
                PandaPose.STANDING -> { /* neutral */ }
                PandaPose.SITTING -> setSitting(true)
                PandaPose.LYING_ON_BACK -> setOnBack(true)
                PandaPose.ROLLING -> setRolling(true)
                PandaPose.SNEEZING -> setSneezeTimer(property.sneezeTicks.coerceAtLeast(1))
                PandaPose.EATING -> setEatTimer(property.eatTicks.coerceAtLeast(1))
                PandaPose.SITTING_EATING -> {
                    setSitting(true)
                    setEatTimer(property.eatTicks.coerceAtLeast(1))
                }
            }
        }
        error("Could not apply PandaPoseData to ${entity.entityType} entity.")
    }
}
