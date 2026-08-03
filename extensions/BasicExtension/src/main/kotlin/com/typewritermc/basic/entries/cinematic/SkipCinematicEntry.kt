package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.entry.temporal.TemporalSetFrameTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.ConfirmationKey
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.interaction.interactionContext
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import org.bukkit.event.HandlerList
import org.bukkit.event.player.PlayerEvent
import java.util.concurrent.atomic.AtomicBoolean

@Entry("skip_cinematic", "Allows players to manually skip the cinematic", Colors.RED, "mdi:skip-next")
/**
 * The `Skip Cinematic` entry is used to allow players to manually skip the cinematic.
 *
 * While a segment is active, if the player dismounts,
 * or presses the confirmation key, the cinematic will be skipped to the end of the segment.
 * This allows you to skip only parts of the cinematic.
 * While other parts are not possible to skip.
 *
 * ## How could this be used?
 * On long cinematics, players may want to skip (parts of) the cinematic.
 */
class SkipCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Help("Which key skips, for as long as the player's input can carry it.")
    val confirmationKey: ConfirmationKey = ConfirmationKey.SNEAK,
    @Segments(icon = "mdi:skip-next", color = Colors.RED)
    val segments: List<SkipSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction {
        return SkipCinematicAction(player, this)
    }
}

data class SkipSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
) : Segment

class SkipCinematicAction(
    private val player: Player,
    val entry: SkipCinematicEntry,
) : SimpleCinematicAction<SkipSegment>() {
    override val segments: List<SkipSegment> = entry.segments
    private var confirmation: Confirmation? = null
    private var announcedKey: ConfirmationKey? = null
    private val skipped = AtomicBoolean(false)

    override suspend fun startSegment(segment: SkipSegment) {
        super.startSegment(segment)
        skipped.set(false)

        val confirmation = player.awaitConfirmation(entry.confirmationKey) {
            // A second press would land before the segment is torn down and pull the cinematic back.
            if (!skipped.compareAndSet(false, true)) return@awaitConfirmation
            TemporalSetFrameTrigger(segment.endFrame).triggerFor(player, player.interactionContext ?: context())
        }
        this.confirmation = confirmation

        announce(confirmation.key)
    }

    override suspend fun tickSegment(segment: SkipSegment, frame: Int) {
        super.tickSegment(segment, frame)
        // A camera starting later takes the announced key away with it.
        val key = confirmation?.key ?: return
        if (key == announcedKey) return
        announce(key)
    }

    override suspend fun stopSegment(segment: SkipSegment) {
        super.stopSegment(segment)
        CinematicSkippableEvent(player, false, confirmation?.key ?: entry.confirmationKey).callEvent()
        confirmation?.dispose()
        confirmation = null
        announcedKey = null
    }

    private fun announce(key: ConfirmationKey) {
        announcedKey = key
        CinematicSkippableEvent(player, true, key).callEvent()
    }
}

class CinematicSkippableEvent(player: Player, val canSkip: Boolean, val confirmationKey: ConfirmationKey) :
    PlayerEvent(player, !Bukkit.isPrimaryThread()) {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()

        @JvmStatic
        fun getHandlerList(): HandlerList = HANDLER_LIST
    }
}
