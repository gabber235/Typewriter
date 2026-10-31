// Skeleton for data/minecraft/living/{{entity}}/{{Entity}}{{Field}}Data.kt, modelled on BatHangingData.kt.
// Replace {{entity}} (folder, no separators), {{entity_snake}}, {{Entity}}, {{Field}}, {{field}}, {{field_snake}},
// {{Meta}} (EntityLib meta class), {{metaPackage}} (its package), {{icon}}, the value type and the KDoc text.
// Delete these // lines: the extension's style has no inline comments.
// @Default is JSON and KSP ignores Kotlin defaults: @Default("true") for a flag, @Default("\"SCARED\"") for an enum.
// Use `Var<T> = ConstVar(...)` and `.get(player)` in build() when the value may differ per player.
// The companion default is the RESET value: what the entity shows when no data applies any more.
package com.typewritermc.entity.entries.data.minecraft.living.{{entity}}

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.entity.SinglePropertyCollectorSupplier
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.extensions.packetevents.metas
import me.tofaa.entitylib.meta.{{metaPackage}}.{{Meta}}
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import java.util.*
import kotlin.reflect.KClass

@Entry("{{entity_snake}}_{{field_snake}}_data", "<what it changes, one short phrase>", Colors.RED, "{{icon}}")
@Tags("{{entity_snake}}_{{field_snake}}_data", "{{entity_snake}}_data")
/**
 * The `{{Entity}}{{Field}}Data` class is an entry that <what it does to the entity>.
 *
 * ## How could this be used?
 * This could be used for <a concrete story use>.
 */
class {{Entity}}{{Field}}Data(
    override val id: String = "",
    override val name: String = "",
    @Default("true")
    val {{field}}: Boolean = true,
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : EntityData<{{Entity}}{{Field}}Property> {
    override fun type(): KClass<{{Entity}}{{Field}}Property> = {{Entity}}{{Field}}Property::class

    override fun build(player: Player): {{Entity}}{{Field}}Property = {{Entity}}{{Field}}Property({{field}})
}

data class {{Entity}}{{Field}}Property(val {{field}}: Boolean) : EntityProperty {
    companion object : SinglePropertyCollectorSupplier<{{Entity}}{{Field}}Property>(
        {{Entity}}{{Field}}Property::class,
        {{Entity}}{{Field}}Property(false),
    )
}

fun apply{{Entity}}{{Field}}Data(entity: WrapperEntity, property: {{Entity}}{{Field}}Property) {
    entity.metas {
        meta<{{Meta}}> { is{{Field}} = property.{{field}} }
        error("Could not apply {{Entity}}{{Field}}Data to ${entity.entityType} entity.")
    }
}
