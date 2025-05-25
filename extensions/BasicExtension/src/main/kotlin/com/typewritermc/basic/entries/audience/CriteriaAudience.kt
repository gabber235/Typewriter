package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.utils.server
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry("criteria_audience", "An audience filter based on criteria", Colors.MEDIUM_SEA_GREEN, "fa-solid:filter")
/**
 * The `Criteria Audience` entry filters an audience based on criteria.
 *
 * ## How could this be used?
 * This could be used to show a boss bar or npc when the player is in a certain quest stage.
 */
class CriteriaAudience(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    val criteria: List<Criteria> = emptyList(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = CriteriaAudienceFilter(ref(), criteria)
}

class CriteriaAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    val criteria: List<Criteria>,
) : AudienceFilter(ref) {
    private val factWatcherSubscriptions = ConcurrentHashMap<UUID, FactListenerSubscription>()
    override fun filter(player: Player): Boolean = criteria.matches(player)

    override fun onPlayerAdd(player: Player) {
        factWatcherSubscriptions.compute(player.uniqueId) { _, subscription ->
            subscription?.cancel(player)
            player.listenForFacts(
                criteria.map { it.fact },
                ::onFactChange,
            )
        }

        super.onPlayerAdd(player)
    }

    private fun onFactChange(player: Player, fact: Ref<ReadableFactEntry>) {
        player.refresh()
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        factWatcherSubscriptions.remove(player.uniqueId)?.cancel(player)
    }

    override fun dispose() {
        super.dispose()
        factWatcherSubscriptions.forEach { (playerId, subscription) ->
            val player = server.getPlayer(playerId) ?: return@forEach
            subscription.cancel(player)
        }
    }
}