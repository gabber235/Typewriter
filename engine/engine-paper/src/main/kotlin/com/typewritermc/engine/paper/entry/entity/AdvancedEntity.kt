package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.logger
import java.util.*

@Tags("shared_entity_instance")
interface SharedAdvancedEntityInstance : EntityInstanceEntry {
    val activity: Ref<out SharedEntityActivityEntry>

    @WithRotation
    val spawnLocation: Position

    val showRange: Optional<Var<Double>>

    override suspend fun display(): AudienceFilter {
        val activityCreator = this.activity.get() ?: IdleActivity
        val (definition, suppliers) = baseInfo() ?: return PassThroughFilter(ref())

        return SharedAudienceEntityDisplay(
            ref(),
            definition,
            activityCreator,
            suppliers,
            spawnLocation,
            showRange.orElse(ConstVar(entityShowRange)),
        )
    }
}

@Tags("group_entity_instance")
interface GroupAdvancedEntityInstance : EntityInstanceEntry {
    val activity: Ref<out SharedEntityActivityEntry>

    @WithRotation
    val spawnLocation: Position

    val showRange: Optional<Var<Double>>

    @Help("The group that this entity instance belongs to.")
    val group: Ref<out GroupEntry>

    override suspend fun display(): AudienceFilter {
        val activityCreator = this.activity.get() ?: IdleActivity

        val group = this.group.get() ?: throw IllegalStateException("No group found for the group entity instance.")
        val (definition, suppliers) = baseInfo() ?: return PassThroughFilter(ref())

        return GroupAudienceEntityDisplay(
            ref(),
            definition,
            activityCreator,
            suppliers,
            spawnLocation,
            showRange.orElse(ConstVar(entityShowRange)),
            group
        )
    }
}

@Tags("individual_entity_instance")
interface IndividualAdvancedEntityInstance : EntityInstanceEntry {
    val activity: Ref<out IndividualEntityActivityEntry>

    @WithRotation
    val spawnLocation: Var<Position>

    val showRange: Optional<Var<Double>>

    override suspend fun display(): AudienceFilter {
        val activityCreator = this.activity.get() ?: IdleActivity

        val (definition, suppliers) = baseInfo() ?: return PassThroughFilter(ref())

        return IndividualAudienceEntityDisplay(ref(), definition, activityCreator, suppliers, spawnLocation, showRange.orElse(ConstVar(entityShowRange)))
    }
}

private fun EntityInstanceEntry.baseInfo(): BaseInfo? {
    val definition = definition.get()
    if (definition == null) {
        logger.warning("You must specify a definition for $name")
        return null
    }

    val baseSuppliers = definition.data.withPriority()

    val maxBaseSupplier = baseSuppliers.maxOfOrNull { it.second } ?: 0
    val overrideSuppliers = children.descendants(EntityData::class)
        .mapNotNull { it.get() }
        .map { it to (it.priority + maxBaseSupplier + 1) }

    val suppliers = (baseSuppliers + overrideSuppliers)

    return BaseInfo(definition, suppliers)
}

private data class BaseInfo(
    val definition: EntityDefinitionEntry,
    val suppliers: List<Pair<EntityData<*>, Int>>,
)