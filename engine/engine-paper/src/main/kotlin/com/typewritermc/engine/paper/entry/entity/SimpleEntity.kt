package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.utils.logErrorIfNull

interface SimpleEntityDefinition : EntityDefinitionEntry

@Tags("shared_entity_instance")
interface SimpleEntityInstance : EntityInstanceEntry {
    override val definition: Ref<out SimpleEntityDefinition>
    val data: List<Ref<EntityData<*>>>
    @Help("What the entity will do.")
    @OnlyTags("shared_entity_activity")
    val activity: Ref<out EntityActivityEntry>

    @WithRotation
    val spawnLocation: Position

    override val children: List<Ref<out AudienceEntry>>
        get() = data

    override suspend fun display(): AudienceFilter {
        val definition = definition.get().logErrorIfNull("You must specify a definition for $name")
            ?: return PassThroughFilter(ref())

        val activity = this.activity.get() ?: IdleActivity

        val definitionData = definition.data.withPriority()

        val maxDefinitionData = definitionData.maxOfOrNull { it.second } ?: 0

        val instanceData = data.mapNotNull {
            val data = it.get() ?: return@mapNotNull null
            data to (data.priority + maxDefinitionData + 1)
        }

        return SharedActivityEntityDisplay(
            ref(),
            definition,
            activity,
            (definitionData + instanceData),
            spawnLocation,
        )
    }
}

fun List<Ref<EntityData<*>>>.withPriority(): List<Pair<EntityData<*>, Int>> = mapNotNull {
    val data = it.get() ?: return@mapNotNull null
    data to data.priority
}
