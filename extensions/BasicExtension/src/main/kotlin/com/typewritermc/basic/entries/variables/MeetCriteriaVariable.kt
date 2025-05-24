package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.matches
import kotlin.reflect.full.cast

@Entry(
    "meet_criteria_variable",
    "A boolean variable that is true if the player meets the criteria",
    Colors.GREEN,
    "fa-solid:filter"
)
@GenericConstraint(Boolean::class)
@VariableData(MeetCriteriaVariableData::class)
/**
 * The `MeetCriteriaVariable` entry is a boolean variable that is true if the player meets the criteria.
 *
 * It returns true if both the entry and data criteria are met.
 *
 * ## How could this be used?
 * This could be used to conditionally block an event, like blocking a player from running a command if they don't meet a certain criteria.
 */
class MeetCriteriaVariable(
    override val id: String = "",
    override val name: String = "",
    val criteria: List<Criteria> = emptyList(),
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<MeetCriteriaVariableData>()
            ?: return context.cast(false)

        val criteria = this.criteria + data.criteria
        return context.cast(criteria.matches(context.player, context.interactionContext ?: context()))
    }
}

data class MeetCriteriaVariableData(
    val criteria: List<Criteria> = emptyList(),
)