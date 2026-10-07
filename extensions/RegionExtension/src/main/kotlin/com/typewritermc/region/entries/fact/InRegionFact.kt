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

@Entry("region_inside_fact", "Whether the player is inside a region", Colors.PURPLE, "mdi:map-marker-check")
/**
 * The value is `1` when the player is inside the configured region and `0` otherwise.
 * A player counts as inside as soon as any part of their body overlaps the region, the
 * same rule the enter and leave events use. Region membership is a fact rather than a
 * custom criteria type because Typewriter's
 * [com.typewritermc.engine.paper.entry.Criteria] compares a fact against an Int.
 *
 * The value is read from the world for the asking player, so a `Group` does not change it.
 * A group shares one stored value between its members; there is nothing stored here to share,
 * and summing this fact over a group would answer how many of them are inside rather than
 * whether this one is.
 *
 * ## How could this be used?
 *
 * Gate a `GiveItemAction` with the criteria `InRegionFact == 1` to only give the item
 * when the player is inside the merchant zone.
 */
class InRegionFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("The region whose membership produces the fact's value.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
) : ReadableFactEntry {
    override fun readForPlayersGroup(player: Player): FactData = readSinglePlayer(player)

    override fun readSinglePlayer(player: Player): FactData {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        val tracker = engine.query(region, player) ?: return FactData(0)
        val value = if (tracker.isInside(player)) 1 else 0
        return FactData(value)
    }
}
