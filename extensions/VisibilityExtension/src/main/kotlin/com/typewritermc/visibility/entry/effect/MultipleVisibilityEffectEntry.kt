package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.visibility.effector.MultipleVisibilityEffector
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.rule.VisibilityRule
import org.bukkit.entity.Player

@Entry(
    "multiple_visibility_effect",
    "Applies multiple visibility effects together",
    Colors.PURPLE,
    "mdi:vector-combine"
)
/**
 * The `Multiple Visibility Effect` bundles several visibility effects into one.
 *
 * A viewer and target pair only ever has one active effect. To apply several modifications at the
 * same time, reference them here and use this entry as the rule's effect. All sub effects must
 * initialize successfully, otherwise the whole bundle is rolled back.
 *
 * ## How could this be used?
 * Make a ghost player both semi transparent and glowing by combining the ghost and glow effects
 * in a single rule.
 */
class MultipleVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The effects that are applied together when this effect becomes active.")
    val effects: List<Ref<VisibilityEffectEntry>> = emptyList(),
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean
        get() = subEffectAnswers(mutableSetOf(id)) { it.supportsSelf }.any { it.second }

    override fun appliesToSelf(viewer: Player): Boolean =
        subEffectAnswers(mutableSetOf(id)) { it.appliesToSelf(viewer) }.any { it.second }

    /** Settled only when every sub effect is: one variable toggle makes the whole bundle variable. */
    override fun constantSelf(): Boolean? {
        val answers = subEffectAnswers(mutableSetOf(id)) { it.constantSelf() }.map { it.second }
        if (answers.any { it == null }) return null
        return answers.any { it == true }
    }

    override fun selfVariant(viewer: Player): Int {
        val applying = subEffectAnswers(mutableSetOf(id)) { it.selfVariant(viewer) }.filter { it.second != 0 }
        if (applying.isEmpty()) return 0
        return applying.hashCode() or 1
    }

    override fun createEffector(rule: VisibilityRule): VisibilityEffector {
        validateAcyclic()
        return MultipleVisibilityEffector(rule, effects)
    }

    /**
     * [answer] for every effect in the tree that is not itself a bundle, keyed by entry id. Entries
     * already seen are skipped, so a bundle referencing itself cannot recurse indefinitely.
     */
    private fun <T> subEffectAnswers(
        visited: MutableSet<String>,
        answer: (VisibilityEffectEntry) -> T,
    ): List<Pair<String, T>> = effects.flatMap { ref ->
        val entry = ref.get() ?: return@flatMap emptyList()
        if (!visited.add(entry.id)) return@flatMap emptyList()
        if (entry is MultipleVisibilityEffectEntry) entry.subEffectAnswers(visited, answer)
        else listOf(entry.id to answer(entry))
    }

    /**
     * @throws IllegalStateException when this bundle contains itself, directly or through another
     * bundle. Creating effectors for such a graph would recurse until the stack overflows.
     */
    private fun validateAcyclic(path: MutableList<String> = mutableListOf(id)) {
        effects.forEach { ref ->
            val entry = ref.get() as? MultipleVisibilityEffectEntry ?: return@forEach
            check(entry.id !in path) {
                "Multiple visibility effect '$id' contains itself: ${(path + entry.id).joinToString(" -> ")}"
            }
            path.add(entry.id)
            entry.validateAcyclic(path)
            path.removeAt(path.lastIndex)
        }
    }
}
