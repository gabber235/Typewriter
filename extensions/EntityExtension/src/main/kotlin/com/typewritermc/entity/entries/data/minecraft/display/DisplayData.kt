package com.typewritermc.entity.entries.data.minecraft.display

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import me.tofaa.entitylib.wrapper.WrapperEntity

@Tags("display_data")
interface DisplayEntityData<P : EntityProperty> : EntityData<P>

fun applyDisplayEntityData(entity: WrapperEntity, property: EntityProperty): Boolean {
    when (property) {
        is TranslationProperty -> applyTranslationData(entity, property)
        is BillboardConstraintProperty -> applyBillboardConstraintData(entity, property)
        is Scale3DProperty -> applyScale3DData(entity, property)
        is PreRotationProperty -> applyPreRotationData(entity, property)
        is PostRotationProperty -> applyPostRotationData(entity, property)
        is InterpolationDurationProperty -> applyInterpolationDurationData(entity, property)
        is BrightnessProperty -> applyBrightnessData(entity, property)
        else -> return false
    }
    return true
}