package com.typewritermc.basic.entries.audience

import com.github.retrooper.packetevents.protocol.world.waypoint.EmptyWaypointInfo
import com.github.retrooper.packetevents.protocol.world.waypoint.TrackedWaypoint
import com.github.retrooper.packetevents.protocol.world.waypoint.Vec3iWaypointInfo
import com.github.retrooper.packetevents.protocol.world.waypoint.WaypointIcon
import com.github.retrooper.packetevents.util.Either
import com.github.retrooper.packetevents.util.Vector3i
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerWaypoint
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.core.utils.point.toBlockPosition
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.position
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "locator_bar_audience",
    "Shows a target location on the player's locator bar",
    Colors.GREEN,
    "material-symbols:location-on",
)
/**
 * The `Locator Bar Audience` entry shows a target position on the player's locator bar while they are in this
 * audience.
 *
 * The waypoint is hidden while the player and target are in different worlds.
 *
 * ## How could this be used?
 * This can be used to guide players to objectives or important locations without displaying a path stream.
 */
class LocatorBarAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The position shown on the locator bar")
    val target: Var<Position> = ConstVar(Position.ORIGIN),
    @Help("The color of the locator bar marker")
    val color: Color = Color.WHITE,
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = LocatorBarAudienceDisplay(target, color)
}

internal class LocatorBarAudienceDisplay(
    private val target: Var<Position>,
    private val color: Color,
    private val packetSender: LocatorBarPacketSender = PacketEventsLocatorBarPacketSender,
) : AudienceDisplay(), TickableDisplay {
    private val locators: MutableMap<UUID, LocatorBar> = ConcurrentHashMap()

    override fun onPlayerAdd(player: Player) {
        applyTarget(player)
    }

    override fun tick() {
        players.forEach(::applyTarget)
    }

    override fun onPlayerRemove(player: Player) {
        locators.computeIfPresent(player.uniqueId) { _, locator ->
            packetSender.untrack(player, locator.identifier)
            null
        }
    }

    private fun applyTarget(player: Player) {
        val playerId = player.uniqueId
        val playerWorld = player.position.world
        val targetPosition = target.get(player)

        locators.compute(playerId) { _, current ->
            if (player !in this) return@compute current
            when (val change = nextLocatorBarChange(current, playerWorld, targetPosition)) {
                is LocatorBarChange.Track -> {
                    packetSender.track(player, change.locator, color)
                    change.locator
                }

                is LocatorBarChange.Update -> {
                    packetSender.update(player, change.locator, color)
                    change.locator
                }

                is LocatorBarChange.Untrack -> {
                    packetSender.untrack(player, change.identifier)
                    null
                }

                null -> current
            }
        }
    }
}

internal data class LocatorBar(
    val identifier: UUID,
    val position: Position,
)

internal sealed interface LocatorBarChange {
    data class Track(val locator: LocatorBar) : LocatorBarChange
    data class Update(val locator: LocatorBar) : LocatorBarChange
    data class Untrack(val identifier: UUID) : LocatorBarChange
}

internal fun nextLocatorBarChange(
    current: LocatorBar?,
    playerWorld: World,
    target: Position,
    createIdentifier: () -> UUID = UUID::randomUUID,
): LocatorBarChange? {
    val position = target.toBlockPosition()
    if (position.world != playerWorld) {
        return current?.let { LocatorBarChange.Untrack(it.identifier) }
    }
    if (current == null) {
        return LocatorBarChange.Track(LocatorBar(createIdentifier(), position))
    }
    if (current.position == position) return null
    return LocatorBarChange.Update(current.copy(position = position))
}

internal interface LocatorBarPacketSender {
    fun track(player: Player, locator: LocatorBar, color: Color)
    fun update(player: Player, locator: LocatorBar, color: Color)
    fun untrack(player: Player, identifier: UUID)
}

internal object PacketEventsLocatorBarPacketSender : LocatorBarPacketSender {
    override fun track(player: Player, locator: LocatorBar, color: Color) {
        send(player, WrapperPlayServerWaypoint.Operation.TRACK, locator.toTrackedWaypoint(color))
    }

    override fun update(player: Player, locator: LocatorBar, color: Color) {
        send(player, WrapperPlayServerWaypoint.Operation.UPDATE, locator.toTrackedWaypoint(color))
    }

    override fun untrack(player: Player, identifier: UUID) {
        send(player, WrapperPlayServerWaypoint.Operation.UNTRACK, identifier.toUntrackedWaypoint())
    }

    private fun send(
        player: Player,
        operation: WrapperPlayServerWaypoint.Operation,
        waypoint: TrackedWaypoint,
    ) {
        WrapperPlayServerWaypoint(operation, waypoint).sendPacketTo(player)
    }

}

internal fun LocatorBar.toTrackedWaypoint(color: Color) = TrackedWaypoint(
    Either.createLeft(identifier),
    WaypointIcon(WaypointIcon.ICON_STYLE_DEFAULT, color.toPacketColor()),
    Vec3iWaypointInfo(Vector3i(position.blockX, position.blockY, position.blockZ)),
)

internal fun UUID.toUntrackedWaypoint() = TrackedWaypoint(
    Either.createLeft(this),
    WaypointIcon(WaypointIcon.ICON_STYLE_DEFAULT, null),
    EmptyWaypointInfo.EMPTY,
)
