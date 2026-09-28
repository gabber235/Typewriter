package com.typewritermc.visibility.selector

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.findDisplay
import com.typewritermc.engine.paper.utils.server
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import java.util.UUID

/**
 * Selects the players that experience a visibility rule, the ones whose view of other players changes.
 *
 * Selectors are resolved every tick by the ruler, so implementations must be cheap and allocation light.
 */
sealed interface ViewerSelector {
    fun resolve(): Set<UUID>
}

/**
 * Selects all players that are currently in the referenced audience.
 */
@AlgebraicTypeInfo("audience", Colors.GREEN, "fa6-solid:users")
data class AudienceViewerSelector(
    val audience: Ref<out AudienceEntry> = emptyRef(),
) : ViewerSelector {
    override fun resolve(): Set<UUID> = audience.audiencePlayerIds()
}

/**
 * Selects every player that is currently online.
 */
@AlgebraicTypeInfo("everyone", Colors.BLUE, "fa6-solid:globe")
class EveryoneViewerSelector : ViewerSelector {
    override fun resolve(): Set<UUID> = onlinePlayerIds()

    override fun equals(other: Any?): Boolean = other is EveryoneViewerSelector
    override fun hashCode(): Int = javaClass.hashCode()
}

internal fun Ref<out AudienceEntry>.audiencePlayerIds(): Set<UUID> {
    val display = findDisplay<AudienceDisplay>() ?: return emptySet()
    return ObjectOpenHashSet(display.playerIds)
}

internal fun onlinePlayerIds(): Set<UUID> =
    server.onlinePlayers.mapTo(ObjectOpenHashSet()) { it.uniqueId }
