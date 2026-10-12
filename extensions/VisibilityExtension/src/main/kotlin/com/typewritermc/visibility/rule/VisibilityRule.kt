package com.typewritermc.visibility.rule

import com.typewritermc.core.entries.Ref
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import java.util.UUID

/**
 * Identifies the combination of a viewer and the target they are looking at.
 * The visibility system tracks at most one active effect per pair.
 */
data class PlayerPair(
    val viewer: UUID,
    val target: UUID,
)

/**
 * A single visibility rule for a specific viewer and target pair.
 *
 * Rules are lightweight value objects created by a [VisibilityRuler] and passed to the
 * [com.typewritermc.visibility.VisibilityEngine], which lets the highest priority rule decide the
 * active effect for the pair. [entryId] names the entry that configured the rule, for the facts.
 */
data class VisibilityRule(
    val viewer: UUID,
    val target: UUID,
    val priority: Int,
    val effect: Ref<VisibilityEffectEntry>,
    val ruler: VisibilityRuler,
    val entryId: String,
) {
    val pair: PlayerPair get() = PlayerPair(viewer, target)

    /** True when the viewer is looking at themselves (a self pair). */
    val isSelf: Boolean get() = viewer == target
}
