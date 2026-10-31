package com.typewritermc.entity.entries.data.minecraft.living.armadillo

import com.github.retrooper.packetevents.protocol.entity.armadillo.ArmadilloState
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.mobs.passive.ArmadilloMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("armadillo_state_data", "The shell state of an armadillo", Colors.RED, "game-icons:armadillo")
@Tags("armadillo_state_data", "armadillo_data")
/**
 * The `ArmadilloStateData` class is an entry that rolls an armadillo up into its shell or lets it walk around.
 *
 * ## How could this be used?
 * This could be used for a shy armadillo that curls up into a ball when the player startles it,
 * and only uncurls again once the player has calmed it down with a spider eye.
 */
class ArmadilloStateData(
    override val id: String = "",
    override val name: String = "",
    @Help("SCARED keeps it curled up in its shell. ROLLING and UNROLLING play the curl and uncurl animation.")
    @Default("\"SCARED\"")
    val state: ArmadilloState = ArmadilloState.SCARED,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<ArmadilloStateProperty> {
    override fun type(): KClass<ArmadilloStateProperty> = ArmadilloStateProperty::class

    override fun build(player: Player): ArmadilloStateProperty = ArmadilloStateProperty(state)
}

data class ArmadilloStateProperty(val state: ArmadilloState) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<ArmadilloStateProperty>(
        ArmadilloStateProperty::class,
        ArmadilloStateProperty(ArmadilloState.IDLE)
    )
}

fun applyArmadilloStateData(entity: WrapperEntity, property: ArmadilloStateProperty) {
    entity.metas {
        meta<ArmadilloMeta> { state = property.state }
        error("Could not apply ArmadilloStateData to ${entity.entityType} entity.")
    }
}
