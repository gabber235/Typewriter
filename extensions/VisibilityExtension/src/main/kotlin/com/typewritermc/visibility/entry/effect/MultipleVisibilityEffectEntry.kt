package com.typewritermc.visibility.entry.effect

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.visibility.effector.MultipleVisibilityEffector
import com.typewritermc.visibility.effector.VisibilityConfigurationException
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.rule.VisibilityRule

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
    /**
     * Settled for every player only when every sub effect is: one toggle that depends on the player
     * makes the whole bundle depend on the player.
     */
    override val selfView: SelfView
        get() {
            val views = leafEffects().mapNotNull { it.get()?.selfView }.filter { it != SelfView.Never }
            if (views.isEmpty()) return SelfView.Never
            val constant = views.filterIsInstance<SelfView.Always>()
            if (constant.size == views.size) return SelfView.Always(constant.flatMapTo(HashSet()) { it.parts })
            return SelfView.PerPlayer { player -> views.flatMapTo(HashSet()) { it.partsFor(player) } }
        }

    override fun createEffector(rule: VisibilityRule): VisibilityEffector {
        validateAcyclic()
        return MultipleVisibilityEffector(rule, leafEffects())
    }

    /**
     * The effects in this bundle's whole tree that are not bundles themselves, in order, each once.
     *
     * The effector works on this flat list rather than on nested effectors, so a disguise inside a
     * nested bundle still goes first and every sibling follows the entity it shows. A ref that
     * resolves to nothing is kept so that creating it reports the entry as missing rather than
     * silently dropping it. Entries already seen are skipped, so a bundle referencing itself cannot
     * recurse indefinitely.
     */
    internal fun leafEffects(): List<Ref<VisibilityEffectEntry>> {
        val leaves = mutableListOf<Ref<VisibilityEffectEntry>>()
        collectLeafEffects(mutableSetOf(id), leaves)
        return leaves
    }

    private fun collectLeafEffects(visited: MutableSet<String>, leaves: MutableList<Ref<VisibilityEffectEntry>>) {
        effects.forEach { ref ->
            val entry = ref.get()
            if (entry == null) {
                leaves.add(ref)
                return@forEach
            }
            if (!visited.add(entry.id)) return@forEach
            if (entry is MultipleVisibilityEffectEntry) entry.collectLeafEffects(visited, leaves)
            else leaves.add(ref)
        }
    }

    /**
     * @throws VisibilityConfigurationException when this bundle contains itself, directly or through another
     * bundle. Creating effectors for such a graph would recurse until the stack overflows.
     */
    private fun validateAcyclic(path: MutableList<String> = mutableListOf(id)) {
        effects.forEach { ref ->
            val entry = ref.get() as? MultipleVisibilityEffectEntry ?: return@forEach
            if (entry.id in path) {
                throw VisibilityConfigurationException(
                    "Multiple visibility effect '$id' contains itself: ${(path + entry.id).joinToString(" -> ")}"
                )
            }
            path.add(entry.id)
            entry.validateAcyclic(path)
            path.removeAt(path.lastIndex)
        }
    }
}
