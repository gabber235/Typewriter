package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.quest.entries.ObjectiveEntry

interface LocatableObjectivePathStreams : ObjectiveEntry, LocatableObjective {
    val targetLocation: Var<Position>
    val completedCriteria: List<Criteria> get() = emptyList()
}