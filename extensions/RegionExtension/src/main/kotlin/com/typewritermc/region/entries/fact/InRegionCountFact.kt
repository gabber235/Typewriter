package com.typewritermc.region.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent

@Entry("region_player_count_fact", "Number of players currently inside a region", Colors.PURPLE, "mdi:account-group")
/**
 * The value is the number of online players currently inside the configured region. A
 * player counts as inside as soon as any part of their body overlaps the region.
 *
 * The count is taken from the perspective of the reading player. For viewer independent
 * regions every reader sees the same value. For viewer anchored regions the value is the
 * number of players inside the reader's own region.
 *
 * The value is counted in the world for the asking player, so a `Group` does not change it.
 * A group shares one stored value between its members, and this fact has nothing stored to
 * share: summing it over a group would count everyone inside once per member.
 *
 * ## How could this be used?
 *
 * Open the boss door when at least 3 players are in the pre boss room, with the criteria
 * `InRegionCountFact >= 3` on the door's open action.
 */
class InRegionCountFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("The region whose population to count.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
) : ReadableFactEntry {
    override fun readForPlayersGroup(player: Player): FactData = readSinglePlayer(player)

    override fun readSinglePlayer(player: Player): FactData {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        val tracker = engine.query(region, player) ?: return FactData(0)
        // The engine's own list, not the server's: this runs wherever a fact is read, which is
        // not always the main thread, and the server's is a live view over a list it mutates.
        return FactData(tracker.countInside(engine.onlinePlayers()))
    }
}
