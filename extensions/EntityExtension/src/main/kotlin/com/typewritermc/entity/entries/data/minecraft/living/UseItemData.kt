package com.typewritermc.entity.entries.data.minecraft.living

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.LivingEntityData
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.types.LivingEntityMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("use_item_data", "If the entity is currently using the main hand item", Colors.RED, "ri:hand-coin-fill")
class UseItemData(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val using: Var<Boolean> = ConstVar(true),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : LivingEntityData<UseItemProperty> {
    override fun type(): KClass<UseItemProperty> = UseItemProperty::class

    override fun build(player: Player): UseItemProperty = UseItemProperty(using.get(player))
}

data class UseItemProperty(val using: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<UseItemProperty>(UseItemProperty::class, UseItemProperty(false))
}

fun applyUseItemData(entity: WrapperEntity, property: UseItemProperty) {
    entity.metas {
        meta<LivingEntityMeta> {
            isHandActive = property.using
        }
        error("Could not apply UseItemData to ${entity.entityType}")
    }
}