package com.typewritermc.visibility.selector

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.server
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import org.bukkit.entity.Player
import java.util.UUID

/**
 * Selects the players a visibility rule applies to, the ones whose appearance changes for the viewer.
 *
 * A selector is either static, resolving to the same set of players for every viewer, or viewer
 * dependent, resolving relative to a specific viewer. Rulers use [viewerDependent] to pick the
 * resolution strategy: a static selector is resolved once per tick, a viewer dependent one once per
 * viewer per tick.
 *
 * Selectors read live server state, so rulers resolve them on the server thread.
 */
sealed interface TargetSelector {
    val viewerDependent: Boolean get() = false

    fun resolve(): Set<UUID>

    /**
     * @param previous the targets this selector returned for the viewer on the previous tick, so a
     * selector can keep a player selected until they clearly left the selection
     */
    fun resolveFor(viewer: Player, previous: Set<UUID>): Set<UUID> = resolve()
}

/**
 * Selects all players that are currently in the referenced audience.
 */
@AlgebraicTypeInfo("audience", Colors.GREEN, "fa6-solid:users")
data class AudienceTargetSelector(
    val audience: Ref<out AudienceEntry> = emptyRef(),
) : TargetSelector {
    override fun resolve(): Set<UUID> = audience.audiencePlayerIds()
}

/**
 * Selects every player that is currently online.
 */
@AlgebraicTypeInfo("everyone", Colors.BLUE, "fa6-solid:globe")
class EveryoneTargetSelector : TargetSelector {
    override fun resolve(): Set<UUID> = onlinePlayerIds()

    override fun equals(other: Any?): Boolean = other is EveryoneTargetSelector
    override fun hashCode(): Int = javaClass.hashCode()
}

/**
 * Selects a single specific player by exact name or uuid.
 * Useful for effects that always revolve around one known player.
 */
@AlgebraicTypeInfo("specific_player", Colors.CYAN, "fa6-solid:user")
data class SpecificPlayerTargetSelector(
    @Help("The exact name or uuid of the player.")
    val player: String = "",
) : TargetSelector {
    override fun resolve(): Set<UUID> {
        if (player.isBlank()) return emptySet()
        val found = runCatching { UUID.fromString(player) }.getOrNull()
            ?.let { server.getPlayer(it) }
            ?: server.getPlayerExact(player)
            ?: return emptySet()
        return setOf(found.uniqueId)
    }
}

/**
 * Selects all players within a radius around the viewer.
 * As players move in and out of the radius, rules are created and removed for them.
 *
 * A player has to move [EXIT_MARGIN] blocks past the radius before they are dropped again, so a
 * player standing exactly on the edge does not have the effect applied and removed every tick.
 */
@AlgebraicTypeInfo("radius", Colors.ORANGE, "fa6-solid:circle-dot")
data class RadiusTargetSelector(
    @Default("16.0")
    val radius: Var<Double> = ConstVar(16.0),
) : TargetSelector {
    override val viewerDependent: Boolean get() = true

    override fun resolve(): Set<UUID> = emptySet()

    override fun resolveFor(viewer: Player, previous: Set<UUID>): Set<UUID> {
        val range = radius.get(viewer)
        if (range <= 0.0) return emptySet()

        val enterSquared = range * range
        val exitSquared = (range + EXIT_MARGIN) * (range + EXIT_MARGIN)
        val viewerLocation = viewer.location
        val nearby = ObjectOpenHashSet<UUID>()
        // Asked of the world's entity lookup, which touches only the chunks in reach. Walking every
        // player in the world costs players squared per tick once every player is a viewer.
        for (player in viewer.world.getNearbyPlayers(viewerLocation, range + EXIT_MARGIN)) {
            // The viewer is one of their own targets, at a distance of zero. The ruler excludes a
            // pair of a player with themselves from the normal rules, but it needs that pair here for
            // an effect that defines a self variant.
            val limit = if (player.uniqueId in previous) exitSquared else enterSquared
            if (player.location.distanceSquared(viewerLocation) > limit) continue
            nearby.add(player.uniqueId)
        }
        return nearby
    }

    companion object {
        const val EXIT_MARGIN = 1.0
    }
}
