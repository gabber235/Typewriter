package com.typewritermc.quest.entries.audience.objectives.concrete

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.quest.entries.ObjectiveAudienceFilter
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.entries.interfaces.CachableFactObjective
import com.typewritermc.quest.entries.interfaces.CacheableFactObjectiveProgressTracking
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.inventory.InventoryClickEvent
import org.bukkit.event.inventory.InventoryType
import java.util.*

@Entry("smelt_objective", "A smelt objective definition", Colors.BLUE_VIOLET, "game-icons:furnace")
/**
 * Represents a task where the player completes an objective by smelting a specific material.
 *
 * ## Example Usage
 * Use this for quests that require players to smelt a specific number of items,
 * like "Smelt 10 Iron Ingots" or "Cook 5 Fish".
 */
class SmeltObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The item that is the end result of the smelt (e.g. IRON_INGOT)! If not set, any block type will count.")
    val result: Optional<Var<Item>> = Optional.empty(),
    @Help("Track the progress of the SmeltObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<TriggerableEntry> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(ref(), criteria).listenToEvent(InventoryClickEvent::class) { event ->
            val player = event.whoClicked as? Player ?: return@listenToEvent

            val invType = event.clickedInventory?.type ?: return@listenToEvent
            val item = event.currentItem ?: return@listenToEvent

            val validFurnace = invType in listOf(
                InventoryType.FURNACE,
                InventoryType.BLAST_FURNACE,
                InventoryType.SMOKER
            )
            if (!validFurnace || event.rawSlot != 2 || item.type == Material.AIR) return@listenToEvent

            val expectedItem = result.takeIf { it.isPresent }?.get()?.get(player)
            if (expectedItem != null && expectedItem.isSameAs(player, item)) return@listenToEvent

            incrementFact(player, item.amount)
        }
    }
}