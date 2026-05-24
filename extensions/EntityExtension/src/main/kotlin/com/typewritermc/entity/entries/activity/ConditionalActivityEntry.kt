package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entity.EntityActivity
import com.typewritermc.engine.paper.entry.entity.IndividualActivityContext
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entity.SingleChildActivity
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.IndividualEntityActivityEntry
import com.typewritermc.engine.paper.entry.matches

@Entry(
    "conditional_activity",
    "Select activity based on criteria",
    Colors.BLUE_VIOLET,
    "fluent:arrow-branch-24-filled"
)
/**
 * The `Conditional Activity` is an activity that selects a child activity based on criteria.
 * It will go through the conditions in order and use the first activity whose criteria match.
 *
 * This can only be used on an individual entity instance.
 *
 * ## How could this be used?
 * This could be used to make an NPC react differently based on facts or game state.
 */
class ConditionalActivityEntry(
    override val id: String = "",
    override val name: String = "",
    val conditions: List<ConditionalActivityPair> = emptyList(),
    @Help("The activity that will be used when no criteria match.")
    val defaultActivity: Ref<out EntityActivityEntry> = emptyRef(),
) : IndividualEntityActivityEntry {
    override fun create(
        context: IndividualActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<IndividualActivityContext> {
        return ConditionalActivity(conditions, defaultActivity, currentLocation)
    }
}

class ConditionalActivityPair(
    val criteria: List<Criteria> = emptyList(),
    val activity: Ref<out IndividualEntityActivityEntry> = emptyRef(),
)

class ConditionalActivity(
    private val conditions: List<ConditionalActivityPair>,
    private val defaultActivity: Ref<out EntityActivityEntry>,
    startLocation: PositionProperty,
) : SingleChildActivity<IndividualActivityContext>(startLocation) {
    override fun currentChild(context: IndividualActivityContext): Ref<out EntityActivityEntry> {
        val player = context.viewer
        return conditions.firstOrNull { it.criteria.matches(player) }?.activity ?: defaultActivity
    }
}
