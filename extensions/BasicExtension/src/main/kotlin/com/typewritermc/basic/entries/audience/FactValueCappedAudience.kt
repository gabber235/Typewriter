package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.utils.server
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "fact_value_capped_audience",
    "Caps audience based on fact values",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:sort-numeric"
)
/**
 * The `Fact Value Capped Audience` entry limits the audience to X players with highest/lowest fact values.
 *
 * ## How could this be used?
 * This could be used for leaderboards, top player rewards, or competitions based on stats.
 */
class FactValueCappedAudience(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    val capacity: Var<Int> = ConstVar(0),
    val fact: Ref<ReadableFactEntry> = emptyRef(),
    val ordering: Ordering = Ordering.SMALLEST,
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = FactValueCappedAudienceFilter(ref(), capacity, fact, ordering)
}

enum class Ordering {
    SMALLEST,
    LARGEST
}

class FactValueCappedAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    capacity: Var<Int>,
    private val fact: Ref<ReadableFactEntry>,
    private val ordering: Ordering,
) : CappedAudienceFilter(ref, capacity) {
    private val factValues = ConcurrentHashMap<UUID, Int>()
    private val factListeners = ConcurrentHashMap<UUID, FactListenerSubscription>()

    override fun onPlayerAdd(player: Player) {
        updateFactValue(player)
        factListeners[player.uniqueId] = player.listenForFacts(
            listOf(fact)
        ) { p, _ ->
            updateFactValue(p)
            refreshCandidates()
        }
        super.onPlayerAdd(player)
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        factListeners.remove(player.uniqueId)?.cancel(player)
        factValues.remove(player.uniqueId)
    }

    private fun updateFactValue(player: Player) {
        val factEntry = fact.get()
        factValues[player.uniqueId] = factEntry?.readForPlayersGroup(player)?.value ?: 0
    }

    override fun updateCandidates() {
        val players = consideredPlayers
        val cap = capacity.get(players.firstOrNull() ?: return).coerceAtLeast(0)

        // Update all fact values for considered players
        consideredPlayers.forEach { updateFactValue(it) }

        candidates = consideredPlayers
            .map { it.uniqueId }
            .let { uuids ->
                when (ordering) {
                    Ordering.SMALLEST -> uuids.sortedBy { factValues.getOrPut(it) { 0 } }
                    Ordering.LARGEST -> uuids.sortedByDescending { factValues.getOrPut(it) { 0 } }
                }
            }
            .take(cap)
    }

    override fun dispose() {
        super.dispose()
        factListeners.forEach { (uuid, subscription) ->
            server.getPlayer(uuid)?.let { subscription.cancel(it) }
        }
        factListeners.clear()
        factValues.clear()
    }
}