package com.typewritermc.rpgregions.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import net.islandearth.rpgregions.api.RPGRegionsAPI
import net.islandearth.rpgregions.managers.data.region.WorldDiscovery
import java.time.LocalDateTime

@Entry("discover_rpg_region", "Create a discover for an RPGRegions region", Colors.RED, "fa6-solid:address-book")
/**
 * The `Discover Region Action` is used to add a discovery into a user's account.
 *
 * ## How could this be used?
 *
 * This action could be used to reward the player for completing a task/quest. For example, there could exist a quest where an NPC asks for help from the player in exchange for their knowledge of the whereabouts of some important location. This action could be used as the reward when the quest is completed.
 */
class DiscoverRegionActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Make sure that this is the region ID, not the region's display name")
    private val region: String = "",
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val region = RPGRegionsAPI.getAPI().managers.regionsCache.getConfiguredRegion(region)
        if (!region.isPresent) return

        val user = RPGRegionsAPI.getAPI().managers.storageManager.getAccount(player.uniqueId)
        val date: LocalDateTime = LocalDateTime.now()
        val worldDiscovery = WorldDiscovery(date, region.get().id)
        user.get().addDiscovery(worldDiscovery)

        RPGRegionsAPI.getAPI().managers.storageManager.removeCachedAccount(player.uniqueId)
    }
}