package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.TickedAsync
import com.typewritermc.engine.paper.utils.toBukkitLocation
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.future.await

@Entry("teleport", "Teleport a player", Colors.RED, "teenyicons:google-streetview-solid")
/**
 * The `Teleport Action` entry is used to teleport a player to a location.
 *
 * ## How could this be used?
 * This could be used to teleport a player to a location when they click a button.
 * Or it could be used for a fast travel system where players talk to an NPC and are teleported to a location.
 */
class TeleportActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @WithRotation
    val location: Var<Position> = ConstVar(Position.ORIGIN),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        disableAutomaticTriggering()
        Dispatchers.TickedAsync.launch {
            player.teleportAsync(location.get(player, context).toBukkitLocation()).await()
            applyModifiers()
            triggerManually()
        }
    }
}