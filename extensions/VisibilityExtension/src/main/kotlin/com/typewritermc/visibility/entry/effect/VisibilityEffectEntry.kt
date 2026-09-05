package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.ManifestEntry
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player

/**
 * A stateless blueprint for a visibility effect.
 *
 * Effect entries only hold configuration. When a rule referencing this effect wins the priority
 * contest for a pair, the engine calls [createEffector] to instantiate the stateful effector that
 * performs the actual modification.
 */
@Tags("visibility_effect")
interface VisibilityEffectEntry : ManifestEntry {
    /**
     * Creates a fresh effector for the given rule.
     * Implementations must not share mutable state between effector instances.
     */
    fun createEffector(rule: VisibilityRule): VisibilityEffector

    /** Whether this effect exposes a self toggle at all. Static, evaluated without a player. */
    val supportsSelf: Boolean get() = false

    /**
     * Whether the effect currently applies to the target's own view of themselves.
     *
     * Self views follow the target selection alone. A selected target sees the effect on themselves
     * even when the rule's viewer selector matches nobody. A viewer dependent target selector is the
     * exception, since without a viewer it selects nobody: there the self views follow the combined
     * targets of all viewers.
     */
    fun appliesToSelf(viewer: Player): Boolean = false

    /**
     * The answer [appliesToSelf] gives every viewer, or null when it depends on the viewer.
     *
     * A ruler asks [appliesToSelf] once per candidate per tick, so an answer that cannot change is
     * settled once for all of them instead.
     */
    fun constantSelf(): Boolean? = if (supportsSelf) null else false

    /**
     * Which parts of this effect apply to the target's own view, as a number that changes exactly
     * when that set does, and zero when none apply. A ruler recreates a self pair whose variant
     * changed, so a bundle whose sub effects toggle one at a time is applied again with the right
     * ones.
     */
    fun selfVariant(viewer: Player): Int = if (appliesToSelf(viewer)) 1 else 0
}
