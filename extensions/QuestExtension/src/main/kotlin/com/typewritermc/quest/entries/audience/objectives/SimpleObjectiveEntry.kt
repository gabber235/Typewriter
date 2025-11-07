package com.typewritermc.quest.entries.audience.objectives

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.quest.entries.ObjectiveEntry
import com.typewritermc.quest.entries.QuestEntry
import java.util.Optional

@Entry("objective", "An objective definition", Colors.BLUE_VIOLET, "streamline:target-solid")
/**
 * The `Objective` entry is a tasks that the player can complete.
 * It is mainly for displaying the progress to a player.
 *
 * It is **not** necessary to use this entry for objectives.
 * It is just a visual novelty.
 *
 * The entry filters the audience based on if the objective is active.
 * It will show the objective to the player if the criteria are met.
 *
 * ## How could this be used?
 * This could be used to show the players what they need to do.
 */
class SimpleObjectiveEntry(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    override val display: Var<String> = ConstVar(""),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : ObjectiveEntry