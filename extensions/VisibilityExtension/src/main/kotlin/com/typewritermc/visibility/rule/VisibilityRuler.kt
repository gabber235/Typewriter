package com.typewritermc.visibility.rule

import com.typewritermc.visibility.VisibilityEngine
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Base class for the stateful managers that decide which visibility rules exist.
 *
 * A ruler owns the rules it created. It tracks them so the engine can fall back to a shadowed rule
 * when a higher priority rule for the same pair is removed. Subclasses call [addRule] and
 * [removeRuleAt] when a rule should become active or inactive, usually from [tick].
 *
 * [tick] and [dispose] are invoked from the engine's single tick coroutine and [captureServerState]
 * from the server thread, so subclasses need no synchronization for their own state. The applied
 * rules are the exception: the engine reads them from effector lifecycle chains, which run on their
 * own threads.
 */
abstract class VisibilityRuler : KoinComponent {
    /** Priority of the rules created by this ruler. Higher values win the contest for a pair. */
    abstract val priority: Int

    /** Id of the entry that configured this ruler, used by facts to filter rule counts. */
    abstract val entryId: String

    private val appliedRules = ConcurrentHashMap<PlayerPair, VisibilityRule>()
    private val engine: VisibilityEngine by inject()

    /**
     * The rule this ruler currently applies to the pair, whether it won the contest or not.
     * The engine uses this to find a replacement when the active rule of a pair is removed.
     */
    fun visibilityRuleFor(viewer: UUID, target: UUID): VisibilityRule? =
        appliedRules[PlayerPair(viewer, target)]

    protected fun hasRule(viewer: UUID, target: UUID): Boolean =
        appliedRules.containsKey(PlayerPair(viewer, target))

    protected suspend fun addRule(rule: VisibilityRule) {
        appliedRules[rule.pair] = rule
        engine.addRule(rule)
    }

    /**
     * Removes the rule this ruler applies to the pair, if it has one.
     * Callers know which pairs left their selection, so removal never has to scan the rules.
     */
    protected suspend fun removeRuleAt(viewer: UUID, target: UUID) {
        val rule = appliedRules.remove(PlayerPair(viewer, target)) ?: return
        engine.removeRule(rule)
    }

    protected suspend fun removeAllRules() {
        val rules = appliedRules.values.toList()
        appliedRules.clear()
        rules.forEach { engine.removeRule(it) }
    }

    /**
     * Called every server tick on the server thread, right before [tick].
     *
     * Selectors read live Bukkit collections, which is only safe here. Subclasses capture what they
     * need into their own state and diff it in [tick]. The engine batches this for all rulers into a
     * single hop, so keep it short.
     */
    open fun captureServerState() {}

    /**
     * Called every server tick from an async context, after [captureServerState].
     * Subclasses re evaluate their selection here and create or remove rules on changes.
     */
    open suspend fun tick() {}

    /**
     * Called when the visibility system shuts down or reloads.
     */
    open suspend fun dispose() {
        removeAllRules()
    }
}
