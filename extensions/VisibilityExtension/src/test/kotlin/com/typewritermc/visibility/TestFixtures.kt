package com.typewritermc.visibility

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.delay
import com.typewritermc.visibility.rule.VisibilityRuler
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Effect entry that records the lifecycle of its effectors into a shared event list.
 */
class RecordingEffectEntry(
    override val id: String,
    val events: CopyOnWriteArrayList<String> = CopyOnWriteArrayList(),
    private val failOnInitialize: Boolean = false,
    override val name: String = id,
    private val self: Boolean = false,
    @Volatile var selfActive: Boolean = self,
    /** Lets a test tell a disposal that finished from one that was only ever started. */
    private val disposeDelayMs: Long = 0,
    /** Stands in for an effect that only reaches the client on a fresh add, like a skin. */
    private val rerender: Boolean = false,
) : VisibilityEffectEntry {
    override val supportsSelf: Boolean get() = self

    override fun appliesToSelf(viewer: Player): Boolean = selfActive

    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        RecordingEffector(id, events, failOnInitialize, disposeDelayMs, rerender)
}

class RecordingEffector(
    private val label: String,
    private val events: MutableList<String>,
    private val failOnInitialize: Boolean,
    private val disposeDelayMs: Long = 0,
    private val rerender: Boolean = false,
) : VisibilityEffector {
    @Volatile
    private var rerendered = false

    override val needsPairRerender: Boolean get() = rerendered

    override suspend fun initialize() {
        // Claimed before the failure below, the way a real effector registers its hook and only then
        // fails.
        rerendered = rerender
        if (failOnInitialize) {
            events.add("$label:initialize-failed")
            throw IllegalStateException("Effector '$label' failed to initialize")
        }
        events.add("$label:initialize")
    }

    override suspend fun dispose() {
        if (disposeDelayMs > 0) delay(disposeDelayMs)
        events.add("$label:dispose")
    }
}

/**
 * Ruler that applies and retracts rules on demand instead of resolving selectors.
 */
class TestRuler(
    override val priority: Int,
    override val entryId: String = "test_ruler_$priority",
) : VisibilityRuler() {
    suspend fun apply(viewer: UUID, target: UUID, effect: VisibilityEffectEntry, priority: Int = this.priority) {
        addRule(rule(viewer, target, effect, priority))
    }

    suspend fun applyBrokenEffect(viewer: UUID, target: UUID, effect: Ref<VisibilityEffectEntry>) {
        addRule(VisibilityRule(viewer, target, priority, effect, this, entryId))
    }

    suspend fun retract(viewer: UUID, target: UUID) {
        removeRuleAt(viewer, target)
    }

    private fun rule(viewer: UUID, target: UUID, effect: VisibilityEffectEntry, priority: Int) =
        VisibilityRule(viewer, target, priority, effect.ref(), this, entryId)
}
