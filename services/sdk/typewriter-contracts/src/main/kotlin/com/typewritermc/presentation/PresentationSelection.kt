package com.typewritermc.presentation

import com.typewritermc.types.PresentationRole
import com.typewritermc.types.catalog.CheckedType

fun PresentationRegistry.selectWithinRole(
    role: PresentationRole,
    actual: CheckedType,
): PresentationSelection {
    val matching = compatibleCandidates(role, actual)
    val maximal =
        matching.filterNot { candidate ->
            matching.any { other -> isMoreSpecific(other.target, candidate.target, actual) }
        }
    val incomparable =
        maximal.filter { candidate ->
            maximal.any { other -> !isEquivalent(candidate.target, other.target, actual) }
        }
    if (incomparable.isNotEmpty()) {
        return PresentationSelection.Conflict(maximal.map { it.id })
    }
    val priority = maximal.maxOfOrNull { it.priority } ?: return PresentationSelection.Missing(role)
    val winners = maximal.filter { it.priority == priority }
    return if (winners.size == 1) {
        PresentationSelection.Selected(winners.single())
    } else {
        PresentationSelection.Conflict(winners.map { it.id })
    }
}
