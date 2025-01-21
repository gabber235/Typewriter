package com.typewritermc.example.entries.manifest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.entity.EntityRegainHealthEvent

//<code-block:audience_filter_entry>
@Entry("example_audience_filter", "An example audience filter.", Colors.MYRTLE_GREEN, "material-symbols:filter-alt")
class ExampleAudienceFilterEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
) : AudienceFilterEntry {
    override suspend fun display(): AudienceFilter = ExampleAudienceFilter(ref())
}
//</code-block:audience_filter_entry>

//<code-block:audience_filter>
class ExampleAudienceFilter(
    ref: Ref<out AudienceFilterEntry>
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean {
        return player.name.startsWith("g")
    }
}
//</code-block:audience_filter>

//<code-block:audience_filter_dynamic>
class HealthAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
// highlight-next-line
    private val healthRange: ClosedFloatingPointRange<Float> = 0f..20f
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
// highlight-next-line
        return player.health in healthRange
    }

    // highlight-start
    // You can refresh the filters on events
    @EventHandler
    fun healthRegent(event: EntityRegainHealthEvent) {
        val player = event.entity as? Player ?: return
        // Reruns the filter
        player.refresh()

        // Or if you know the player should be filtered, you can update the filter directly
        player.updateFilter(isFiltered = event.amount in healthRange)
    }
    // highlight-end

    // highlight-start
    // It is also possible to run the filter every tick
    override fun tick() {
        // Refresh the filter for all considered players
        consideredPlayers.forEach { it.refresh() }
    }
    // highlight-end
}
//</code-block:audience_filter_dynamic>

//<code-block:audience_filter_invertable>
@Entry("inverted_example_audience_filter", "An example audience filter.", Colors.MYRTLE_GREEN, "material-symbols:filter-alt")
class InvertedExampleAudienceFilterEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    // highlight-green
    override val inverted: Boolean = true,
    // highlight-next-line
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = ExampleAudienceFilter(ref())
}
//</code-block:audience_filter_invertable>