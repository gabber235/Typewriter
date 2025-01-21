package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Regex
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerChangedWorldEvent

@Entry("world_audience", "Filters an audience based on the world", Colors.MEDIUM_SEA_GREEN, "bi:globe-europe-africa")
/**
 * The `World Audience` entry filters an audience based on the world.
 *
 * ## How could this be used?
 * This could be used to show a boss bar or sidebar based on the world.
 */
class WorldAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Regex
    val world: Var<String> = ConstVar(""),
) : AudienceFilterEntry {
    override suspend fun display(): AudienceFilter = WorldAudienceFilter(ref(), world)
}

class WorldAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    val world: Var<String>,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean = world.get(player).toRegex().matches(player.world.name)

    @EventHandler
    fun onWorldChange(event: PlayerChangedWorldEvent) {
        event.player.refresh()
    }
}