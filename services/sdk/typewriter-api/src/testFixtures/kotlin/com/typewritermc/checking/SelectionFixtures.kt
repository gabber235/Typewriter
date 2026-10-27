package com.typewritermc.checking

import com.typewritermc.types.ResourceId
import skirout.editor.v1.type_catalog.ValueLocation

/**
 * A selection whose inspection matched [known]; with [undecidedAt], one candidate stays undecided because that input
 * is missing, and with [interrupted] the inspection paused before it completed.
 */
fun partialSelection(
    vararg known: Int,
    undecidedAt: ValueLocation? = null,
    interrupted: Boolean = false,
) = PartialSelection(
    knownMatches = known.toList(),
    undecided = undecidedAt?.let { listOf(UndecidedCandidate(ResourceId("book:pending"), listOf(it))) }.orEmpty(),
    completion = if (interrupted) InspectionCompletion.Interrupted("paused") else InspectionCompletion.Complete,
    failures = emptyList(),
)
