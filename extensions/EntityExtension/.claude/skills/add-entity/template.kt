// Skeleton for entity/minecraft/{{Name}}Entity.kt, modelled on BatEntity.kt.
// Replace {{Name}} (PascalCase), {{snake}} (snake_case), {{TYPE}} (EntityTypes constant), {{icon}} (Iconify id),
// {{article}} ("a"/"an") and the KDoc text. Delete these // lines: the extension's style has no inline comments.
// Tags: copy the @OnlyTags line entity-info.sh suggests, identical on the definition and the instance.
// Routing: one `when` branch per entity-specific property, then the routers entity-info.sh lists, in its order.
package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.SimpleEntityDefinition
import com.typewritermc.engine.paper.entry.entity.SimpleEntityInstance
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.entity.WrapperFakeEntity
import org.bukkit.entity.Player

@Entry("{{snake}}_definition", "{{article}} {{snake}} entity", Colors.ORANGE, "{{icon}}")
@Tags("{{snake}}_definition")
/**
 * The `{{Name}}Definition` class is an entry that represents {{article}} {{snake}} entity.
 *
 * ## How could this be used?
 * This could be used to create {{article}} {{snake}} that <a concrete story use>.
 */
class {{Name}}Definition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = {{Name}}Entity(player)
}

@Entry("{{snake}}_instance", "An instance of {{article}} {{snake}} entity", Colors.YELLOW, "{{icon}}")
/**
 * The `{{Name}}Instance` class is an entry that represents an instance of {{article}} {{snake}} entity.
 *
 * ## How could this be used?
 * This could be used to place {{article}} {{snake}} in the world, for example <a concrete placement>.
 */
class {{Name}}Instance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<{{Name}}Definition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "mob_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

private class {{Name}}Entity(player: Player) : WrapperFakeEntity(
    EntityTypes.{{TYPE}},
    player,
) {
    override fun applyProperty(property: EntityProperty) {
        when (property) {
            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }
}
