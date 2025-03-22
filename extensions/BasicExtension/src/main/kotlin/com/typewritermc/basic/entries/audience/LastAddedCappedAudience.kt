package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "last_added_capped_audience",
    "Caps audience to most recent X players",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:account-clock"
)
/**
 * The `Last Added Capped Audience` entry limits the audience to the most recent X players who joined.
 * When a new player joins, the oldest player is removed if the audience is at capacity.
 *
 * ## How could this be used?
 * This could be used for rotating rewards or effects among players.
 */
class LastAddedCappedAudience(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    val capacity: Var<Int> = ConstVar(10),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = LastAddedCappedAudienceFilter(ref(), capacity)
}

class LastAddedCappedAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    capacity: Var<Int>
) : CappedAudienceFilter(ref, capacity) {
    private val joinTimes = ConcurrentHashMap<UUID, Instant>()

    override fun onPlayerAdd(player: Player) {
        joinTimes[player.uniqueId] = Instant.now()
        super.onPlayerAdd(player)
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        joinTimes.remove(player.uniqueId)
    }

    override fun updateCandidates() {
        val players = consideredPlayers
        val cap = capacity.get(players.firstOrNull() ?: return).coerceAtLeast(0)
        candidates = consideredPlayers
            .map { it.uniqueId }
            .sortedByDescending { joinTimes.getOrPut(it) { Instant.now() } }
            .take(cap)
    }
}