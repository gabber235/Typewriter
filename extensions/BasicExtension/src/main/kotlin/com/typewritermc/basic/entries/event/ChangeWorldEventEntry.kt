package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CancelableEventEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.shouldCancel
import com.typewritermc.engine.paper.entry.startDialogueWithOrNextDialogue
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerRespawnEvent
import org.bukkit.event.player.PlayerTeleportEvent
import java.util.*
import kotlin.reflect.KClass

/**
 * The `Change World Event` is fired when a player attempts to move from one world to another.
 * This happens when a player teleports to a different world or respawns in a different world.
 *
 * ## How could this be used?
 *
 * This event can be used to welcome players when they enter specific worlds, trigger cinematics or dialogues on world entry,
 * reset player states when leaving certain worlds, or prevent players from entering restricted worlds.
 */
@Entry("change_world_event", "When the player changes world", Colors.YELLOW, "mdi:earth-transfer")
@ContextKeys(ChangeWorldEventContextKeys::class)
class ChangeWorldEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Regex
    @Help("The world the player must be coming from. If empty, any world matches.")
    val fromWorld: Optional<Var<String>> = Optional.empty(),
    @Regex
    @Help("The world the player must be going to. If empty, any world matches.")
    val toWorld: Optional<Var<String>> = Optional.empty(),
    override val cancel: Var<Boolean> = ConstVar(false),
) : CancelableEventEntry

enum class ChangeWorldEventContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(String::class)
    FROM_WORLD(String::class),

    @KeyType(String::class)
    TO_WORLD(String::class),

    @KeyType(Position::class)
    FROM_POSITION(Position::class),

    @KeyType(Position::class)
    TO_POSITION(Position::class),
}

private fun processWorldChange(
    player: Player,
    fromWorld: String,
    toWorld: String,
    fromLocation: Location,
    toLocation: Location,
    query: Query<ChangeWorldEventEntry>,
    onCancel: () -> Unit,
) {
    if (fromWorld == toWorld) return

    val entries = query.findWhere { entry ->
        val fromMatches = entry.fromWorld.map { it.get(player).toRegex().matches(fromWorld) }.orElse(true)
        val toMatches = entry.toWorld.map { it.get(player).toRegex().matches(toWorld) }.orElse(true)
        fromMatches && toMatches
    }.toList()

    if (entries.isEmpty()) return

    entries.startDialogueWithOrNextDialogue(player) {
        ChangeWorldEventContextKeys.FROM_WORLD += fromWorld
        ChangeWorldEventContextKeys.TO_WORLD += toWorld
        ChangeWorldEventContextKeys.FROM_POSITION += fromLocation.toPosition()
        ChangeWorldEventContextKeys.TO_POSITION += toLocation.toPosition()
    }

    if (entries.shouldCancel(player)) {
        onCancel()
    }
}

@EntryListener(ChangeWorldEventEntry::class)
fun onPlayerTeleportChangeWorld(event: PlayerTeleportEvent, query: Query<ChangeWorldEventEntry>) {
    val player = event.player
    val toWorld = event.to.world?.name ?: return

    processWorldChange(
        player = player,
        fromWorld = player.world.name,
        toWorld = toWorld,
        fromLocation = event.from,
        toLocation = event.to,
        query = query,
        onCancel = { event.isCancelled = true }
    )
}

@EntryListener(ChangeWorldEventEntry::class)
fun onPlayerRespawnChangeWorld(event: PlayerRespawnEvent, query: Query<ChangeWorldEventEntry>) {
    val player = event.player
    val toWorld = event.respawnLocation.world?.name ?: return

    processWorldChange(
        player = player,
        fromWorld = player.world.name,
        toWorld = toWorld,
        fromLocation = player.location,
        toLocation = event.respawnLocation,
        query = query,
        onCancel = { event.respawnLocation = player.location }
    )
}
