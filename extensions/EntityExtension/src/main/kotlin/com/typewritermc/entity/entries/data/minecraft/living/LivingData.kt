package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.engine.paper.entry.entries.EntityProperty
import me.tofaa.entitylib.wrapper.WrapperEntity
import me.tofaa.entitylib.wrapper.WrapperLivingEntity

fun applyLivingEntityData(entity: WrapperEntity, property: EntityProperty): Boolean {
    if (entity !is WrapperLivingEntity) return false
    when (property) {
        is EquipmentProperty -> applyEquipmentData(entity, property)
        is ScaleProperty -> applyScaleData(entity, property)
        is DamagedProperty -> applyDamagedData(entity, property)
        is UseItemProperty -> applyUseItemData(entity, property)
        else -> return false
    }

    return true
}
