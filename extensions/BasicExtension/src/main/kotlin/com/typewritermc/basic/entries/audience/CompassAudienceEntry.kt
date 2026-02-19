package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "compass_audience",
    "Points the player compass to a target location",
    Colors.GREEN,
    "fa6-solid:compass",
)
/**
 * The `Compass Audience` entry points the player compass to a target position while the player is in this audience.
 *
 * ## How could this be used?
 * This can be used to guide players to objectives or important locations.
 */
class CompassAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val target: Var<Position> = ConstVar(Position.ORIGIN),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = CompassAudienceDisplay(target)
}

class CompassAudienceDisplay(
    private val target: Var<Position>,
) : AudienceDisplay(), TickableDisplay {

    private val originalTargets: MutableMap<UUID, Position> = ConcurrentHashMap()
    private val appliedTargets: MutableMap<UUID, Position> = ConcurrentHashMap()

    override fun onPlayerAdd(player: Player) {
        originalTargets[player.uniqueId] = player.compassTarget.toPosition()
        applyTarget(player)
    }

    override fun tick() {
        players.forEach(::applyTarget)
    }

    override fun onPlayerRemove(player: Player) {
        val playerId = player.uniqueId
        val original = originalTargets.remove(playerId)
        appliedTargets.remove(playerId)
        if (original == null) return

        runCatching {
            player.compassTarget = original.toBukkitLocation()
        }
    }

    private fun applyTarget(player: Player) {
        val playerId = player.uniqueId
        val position = target.get(player)
        if (appliedTargets[playerId] == position) return

        val bukkitLocation = runCatching { position.toBukkitLocation() }.getOrNull() ?: return
        appliedTargets[playerId] = position
        player.compassTarget = bukkitLocation
    }
}
