package com.typewritermc.entity.entries.data.minecraft.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta.BillboardConstraints
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("billboard_constraint_data", "Constraints for a billboard", Colors.RED, "material-symbols:aspect-ratio")
@Tags("billboard_constraint_data")
class BillboardConstraintData(
    override val id: String = "",
    override val name: String = "",
    @Default("\"CENTER\"")
    val constraint: BillboardConstraints = BillboardConstraints.CENTER,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : DisplayEntityData<BillboardConstraintProperty> {
    override fun type(): KClass<BillboardConstraintProperty> = BillboardConstraintProperty::class

    override fun build(player: Player): BillboardConstraintProperty =
        BillboardConstraintProperty(constraint)
}

data class BillboardConstraintProperty(val constraint: BillboardConstraints) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<BillboardConstraintProperty>(
        BillboardConstraintProperty::class,
        BillboardConstraintProperty(BillboardConstraints.CENTER)
    )
}

fun applyBillboardConstraintData(entity: WrapperEntity, property: BillboardConstraintProperty) {
    entity.metas {
        meta<AbstractDisplayMeta> { billboardConstraints = property.constraint }
        error("Could not apply BillboardConstraintData to ${entity.entityType} entity.")
    }
}

