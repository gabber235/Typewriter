package com.typewritermc.entity.entries.instance

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.GroupAdvancedEntityInstance
import com.typewritermc.engine.paper.entry.entity.IndividualAdvancedEntityInstance
import com.typewritermc.engine.paper.entry.entity.SharedAdvancedEntityInstance
import com.typewritermc.engine.paper.entry.entity.entityShowRange
import com.typewritermc.engine.paper.entry.entries.*
import java.util.Optional

@Entry(
    "shared_advanced_entity_instance",
    "An advanced instance of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Shared Advanced Entity Instance` entry is an entity instance
 * that has the activity shared between all players viewing the instance.
 *
 * ## How could this be used?
 * Simple npc's where everyone needs to see the same npc.
 */
class SharedAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SharedAdvancedEntityInstance

@Entry(
    "group_advanced_entity_instance",
    "An advanced instance of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Group Advanced Entity Instance` entry is an entity instance
 * that has the activity shared between a group of players viewing the instance.
 *
 * ## How could this be used?
 * For example, having a party sees the npc in the same place.
 */
class GroupAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
    override val group: Ref<out GroupEntry> = emptyRef(),
) : GroupAdvancedEntityInstance

@Entry(
    "individual_advanced_entity_instance",
    "An advanced instance of an entity",
    Colors.YELLOW,
    "material-symbols:settings-account-box"
)
/**
 * The `Individual Advanced Entity Instance` entry is an entity instance
 * that has the activity unique to each player viewing the instance.
 *
 * It means that two players can see the same instance in different places.
 *
 * ## How could this be used?
 * For escort quests where the player needs to follow the npc such as a guide.
 */
class IndividualAdvancedEntityInstanceEntry(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    override val spawnLocation: Var<Position> = ConstVar(Position.ORIGIN),
    override val showRange: Optional<Var<Double>> = Optional.empty(),
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val activity: Ref<out IndividualEntityActivityEntry> = emptyRef(),
) : IndividualAdvancedEntityInstance