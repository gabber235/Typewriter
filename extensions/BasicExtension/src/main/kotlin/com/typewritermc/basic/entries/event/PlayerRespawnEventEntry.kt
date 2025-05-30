package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.toCoordinate
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.event.player.PlayerRespawnEvent
import kotlin.reflect.KClass

@Entry("player_respawn_event", "When a player respawns after death", Colors.YELLOW, "material-symbols:refresh-rounded")
/**
 * The `Player Respawn Event` is fired when a player respawns after death.
 *
 * ## How could this be used?
 *
 * You can teleport players to custom spawn locations, give them items on respawn,
 * or apply status effects when they come back to life.
 */
@ContextKeys(RespawnContextKeys::class)
class PlayerRespawnEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val respawnReasons: List<PlayerRespawnEvent.RespawnReason> = emptyList(),
    val respawnLocationTypes: List<RespawnLocationType> = emptyList(),
) : EventEntry

enum class RespawnLocationType {
    BED,
    ANCHOR,
    NONE
}

enum class RespawnContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Position::class)
    RESPAWN_POSITION(Position::class),

    @KeyType(Coordinate::class)
    RESPAWN_COORDINATE(Coordinate::class),
}

@EntryListener(PlayerRespawnEventEntry::class)
fun onRespawn(event: PlayerRespawnEvent, query: Query<PlayerRespawnEventEntry>) {
    val player = event.player

    val entries = query.findWhere { entry ->
        if (event.respawnReason !in entry.respawnReasons) return@findWhere false

        entry.respawnLocationTypes.any {
            when (it) {
                RespawnLocationType.BED -> event.isBedSpawn
                RespawnLocationType.ANCHOR -> event.isAnchorSpawn
                RespawnLocationType.NONE -> !event.isBedSpawn && !event.isAnchorSpawn
            }
        }
    }.toList()

    entries.triggerAllFor(player) {
        RespawnContextKeys.RESPAWN_POSITION withValue event.respawnLocation.toPosition()
        RespawnContextKeys.RESPAWN_COORDINATE withValue event.respawnLocation.toCoordinate()
    }
}