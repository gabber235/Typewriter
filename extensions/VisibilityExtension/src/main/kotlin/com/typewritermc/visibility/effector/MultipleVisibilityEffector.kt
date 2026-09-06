package com.typewritermc.visibility.effector

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.logging.Logger

/**
 * Composes multiple sub effectors into a single effect for a pair.
 *
 * Sub effectors are initialized in order and disposed in reverse order. When one fails to
 * initialize, every sub effector that was reached is disposed, including the one that threw, and the
 * failure is rethrown so the engine retracts the whole effect. Ticks are forwarded to the sub
 * effectors that are themselves [TickableVisibilityEffector]s.
 */
class MultipleVisibilityEffector(
    private val rule: VisibilityRule,
    private val effectRefs: List<Ref<VisibilityEffectEntry>>,
) : TickableVisibilityEffector, KoinComponent {

    private val logger: Logger by inject()
    private val effectors = mutableListOf<VisibilityEffector>()

    @Volatile
    private var tickables: List<TickableVisibilityEffector> = emptyList()

    @Volatile
    private var rerenderNeeded = false

    // The flag is latched here instead of read from the sub effectors on demand, since disposing the
    // bundle releases them and the engine reads this again afterwards.
    override val needsPairRerender: Boolean get() = rerenderNeeded

    override suspend fun initialize() {
        require(effectRefs.isNotEmpty()) {
            "Multiple visibility effect for entry '${rule.entryId}' has no sub effects"
        }

        val created = createAllEffectors(if (rule.isSelf) selfApplicable() else effectRefs)
        try {
            created.forEach { effector ->
                // The sub effector is recorded before it is initialized. One that throws partway
                // still holds whatever it registered, and only its own dispose can release that.
                effectors.add(effector)
                try {
                    effector.initialize()
                } finally {
                    // The flag is read even when it threw. A sub effector that registered a profile hook before
                    // failing has still changed what the client has to receive again.
                    if (effector.needsPairRerender) rerenderNeeded = true
                }
            }
        } catch (e: Throwable) {
            // Cancellations included. A cancelled coroutine cannot suspend, so a rollback running
            // inside one would stop at the first sub effector and leave the rest still holding
            // everything they registered.
            withContext(NonCancellable) { dispose() }
            throw e
        }
        tickables = created.filterIsInstance<TickableVisibilityEffector>()
    }

    private suspend fun selfApplicable(): List<Ref<VisibilityEffectEntry>> =
        Dispatchers.Sync.switchContext {
            val viewer = rule.viewerPlayer ?: return@switchContext emptyList()
            selfApplicableRefs(effectRefs, viewer)
        }

    /**
     * Disposes every sub effector that was reached, in reverse order.
     * Safe to call twice: the second call finds nothing left, which the engine's compensating dispose
     * after a failed initialize relies on.
     */
    override suspend fun dispose() {
        tickables = emptyList()
        effectors.asReversed().forEach { effector ->
            try {
                effector.dispose()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                logger.severe(
                    "Failed to dispose sub effector for pair (${rule.viewer}, ${rule.target}): ${e.message}"
                )
                e.printStackTrace()
            }
        }
        effectors.clear()
    }

    override suspend fun tick() {
        tickables.forEach { it.tick() }
    }

    private fun createAllEffectors(refs: List<Ref<VisibilityEffectEntry>>): List<VisibilityEffector> = refs.map { ref ->
        val entry = ref.get() ?: throw IllegalStateException(
            "Could not find sub effect entry '${ref.id}' of multiple visibility effect for entry '${rule.entryId}'"
        )
        entry.createEffector(rule)
    }
}

/**
 * The sub effects of a bundle that asked to apply to a viewer looking at themselves.
 *
 * A bundle reports that it supports self when any of its sub effects does, which is what makes the
 * ruler offer it the self pair. That answer says nothing about the sub effects that declined, so
 * without checking each of them again a bundle would apply an effect to a viewer who disabled it for
 * themselves. A ref that resolves to nothing is kept so that creating it reports the entry as
 * missing rather than silently dropping it.
 */
internal fun selfApplicableRefs(
    refs: List<Ref<VisibilityEffectEntry>>,
    viewer: Player,
): List<Ref<VisibilityEffectEntry>> = refs.filter { ref ->
    val entry = ref.get() ?: return@filter true
    entry.appliesToSelf(viewer)
}
