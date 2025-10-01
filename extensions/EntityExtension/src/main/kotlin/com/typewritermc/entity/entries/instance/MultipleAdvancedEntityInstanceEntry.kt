package com.typewritermc.entity.entries.instance

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.logger
import java.util.*

@Entry(
    "multiple_shared_advanced_entity_instance",
    "Multiple shared instances of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Multiple Shared Advanced Entity Instance` entry creates multiple shared entity instances
 * that are synchronized across all players viewing them.
 *
 * ## How could this be used?
 * Create a group of NPCs that all players see in the same positions, such as a squad of guards
 * or a group of merchants in a marketplace.
 */
class MultipleSharedAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @Help("Max distance at which entities spawn/render for the player")
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
    @Help("Number of entities to spawn")
    @Min(1)
    @Default("1")
    val count: Int = 1,
) : SharedAdvancedEntityInstance {

    override suspend fun display(): AudienceFilter {
        val activityCreator = activity.get() ?: IdleActivity
        val (definition, suppliers) = createBaseInfo() ?: return PassThroughFilter(ref())

        return MultipleSharedAudienceEntityDisplay(
            ref(),
            definition,
            activityCreator,
            suppliers,
            spawnLocation,
            showRange.orElse(ConstVar(entityShowRange)),
            count.coerceAtLeast(1),
        )
    }

    private fun createBaseInfo(): BaseInfo? =
        getBaseInfo(definition, children)
}

@Entry(
    "multiple_individual_advanced_entity_instance",
    "Multiple individual instances of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Multiple Individual Advanced Entity Instance` entry creates multiple entity instances
 * that are unique to each player viewing them.
 *
 * ## How could this be used?
 * Create a squad of followers that each player has independently, such as summoned creatures
 * or personal bodyguards. Each player can see their own set of entities in different positions.
 */
class MultipleIndividualAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Var<Position> = ConstVar(Position.ORIGIN),
    @Help("Max distance at which entities spawn/render for the player")
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out IndividualEntityActivityEntry> = emptyRef(),
    @Help("Number of entities to spawn per player")
    @Min(1)
    @Default("1")
    val count: Var<Int> = ConstVar(1),
) : IndividualAdvancedEntityInstance {

    override suspend fun display(): AudienceFilter {
        val activityCreator = activity.get() ?: IdleActivity
        val (definition, suppliers) = createBaseInfo() ?: return PassThroughFilter(ref())

        return MultipleIndividualAudienceEntityDisplay(
            ref(),
            definition,
            activityCreator,
            suppliers,
            spawnLocation,
            showRange.orElse(ConstVar(entityShowRange)),
            count,
        )
    }

    private fun createBaseInfo(): BaseInfo? =
        getBaseInfo(definition, children)
}

@Entry(
    "multiple_group_advanced_entity_instance",
    "Multiple group instances of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Multiple Group Advanced Entity Instance` entry creates multiple entity instances
 * that are synchronized for each group of players viewing them.
 *
 * ## How could this be used?
 * Create a group of NPCs that are synchronized within each party, such as a squad of quest
 * NPCs that each party sees together, but different parties may see them in different states.
 */
class MultipleGroupAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @Help("Max distance at which entities spawn/render for the player")
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
    override val group: Ref<out GroupEntry> = emptyRef(),
    @Help("Number of entities to spawn per group")
    @Min(1)
    @Default("1")
    val count: Int = 1,
) : GroupAdvancedEntityInstance {

    override suspend fun display(): AudienceFilter {
        val activityCreator = activity.get() ?: IdleActivity
        val groupEntry = group.get() ?: return PassThroughFilter(ref())
        val (definition, suppliers) = createBaseInfo() ?: return PassThroughFilter(ref())

        return MultipleGroupAudienceEntityDisplay(
            ref(),
            definition,
            activityCreator,
            suppliers,
            spawnLocation,
            showRange.orElse(ConstVar(entityShowRange)),
            groupEntry,
            count.coerceAtLeast(1),
        )
    }

    private fun createBaseInfo(): BaseInfo? =
        getBaseInfo(definition, children)
}

private data class BaseInfo(
    val definition: EntityDefinitionEntry,
    val suppliers: List<Pair<PropertySupplier<*>, Int>>,
)

private fun getBaseInfo(
    definitionRef: Ref<out EntityDefinitionEntry>,
    children: List<Ref<out AudienceEntry>>
): BaseInfo? {
    val definition = definitionRef.get() ?: run {
        logger.warning("Entity definition not found for reference: $definitionRef")
        return null
    }

    val baseSuppliers = definition.data.withPriority()
    val maxBasePriority = baseSuppliers.maxOfOrNull { it.second } ?: 0

    val overrideSuppliers = children
        .descendants(EntityData::class)
        .mapNotNull { it.get() }
        .map { data -> data to (data.priority + maxBasePriority + 1) }

    return BaseInfo(definition, baseSuppliers + overrideSuppliers)
}