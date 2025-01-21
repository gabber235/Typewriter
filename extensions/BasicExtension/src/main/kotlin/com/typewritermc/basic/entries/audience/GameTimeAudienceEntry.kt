package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerChangedWorldEvent

@Entry(
    "game_time_audience",
    "Filters an audience based on the game time",
    Colors.MEDIUM_SEA_GREEN,
    "bi:clock-fill"
)
/**
 * The `GameTimeAudienceEntry` filters an audience based on the game time.
 *
 * The total time of a Minecraft day is `24000` ticks.
 * Some examples of times are:
 * ------------------------------
 * | Time of day | Ticks        |
 * |-------------|--------------|
 * | Dawn        | 0            |
 * | Noon        | 6000         |
 * | Dusk        | 12000        |
 * | Midnight    | 18000        |
 * ------------------------------
 *
 * ## How could this be used?
 * This can be used to only allow passage to a certain area at night.
 * For example, a vampire castle that only opens its doors at night.
 * Or a market that only opens during the day.
 */
class GameTimeAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    val activeTimes: List<GameTimeRange> = emptyList(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = GameTimeAudienceFilter(ref(), activeTimes)
}

class GameTimeAudienceFilter(
    val ref: Ref<out AudienceFilterEntry>,
    private val activeTimes: List<GameTimeRange>,
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
        val worldTime = player.playerTime % 24000
        return activeTimes.any { worldTime in it }
    }

    @EventHandler
    private fun onWorldChange(event: PlayerChangedWorldEvent) {
        event.player.refresh()
    }

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }
}

class GameTimeRange(
    val start: Long = 0,
    val end: Long = 0,
) {
    operator fun contains(time: Long): Boolean {
        return time in start until end
    }
}