package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.ManifestEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
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

    /**
     * How this effect applies to the target's own view of themselves.
     *
     * Self views follow the target selection alone. A selected target sees the effect on themselves
     * even when the rule's viewer selector matches nobody. A viewer dependent target selector is the
     * exception, since without a viewer it selects nobody: there the self views follow the combined
     * targets of all viewers.
     */
    val selfView: SelfView get() = SelfView.Never
}

/**
 * Which parts of an effect apply to a player's own view of themselves.
 *
 * A part is the id of an effect entry that is not a bundle. A ruler recreates a self pair whose parts
 * changed, so a bundle whose sub effects toggle one at a time is applied again with the right ones.
 */
sealed interface SelfView {
    /** The parts that apply to [player]'s own view, empty when none do. */
    fun partsFor(player: Player): Set<String>

    /** Applies to nobody's own view. */
    data object Never : SelfView {
        override fun partsFor(player: Player): Set<String> = emptySet()
    }

    /** The same parts apply to every player's own view, so a ruler settles them once for all players. */
    data class Always(val parts: Set<String>) : SelfView {
        override fun partsFor(player: Player): Set<String> = parts
    }

    /**
     * The parts depend on the player. A ruler asks once per candidate per tick on the server thread,
     * so [parts] has to stay cheap.
     */
    class PerPlayer(private val parts: (Player) -> Set<String>) : SelfView {
        override fun partsFor(player: Player): Set<String> = parts(player)
    }
}

/**
 * The self view of an effect entry [entryId] that a [toggle] turns on or off. A constant toggle is
 * settled without asking any player.
 */
internal fun selfToggle(entryId: String, toggle: Var<Boolean>): SelfView {
    val parts = setOf(entryId)
    return when ((toggle as? ConstVar)?.value) {
        true -> SelfView.Always(parts)
        false -> SelfView.Never
        null -> SelfView.PerPlayer { player -> if (toggle.get(player)) parts else emptySet() }
    }
}
