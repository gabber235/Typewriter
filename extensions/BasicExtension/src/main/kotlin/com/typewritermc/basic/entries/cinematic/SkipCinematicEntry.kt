package com.typewritermc.basic.entries.cinematic

import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientEntityAction
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.entry.temporal.TemporalSetFrameTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.isFloodgate
import lirand.api.extensions.events.SimpleListener
import lirand.api.extensions.events.listen
import lirand.api.extensions.events.unregister
import org.bukkit.Bukkit
import org.bukkit.entity.Player
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerEvent
import org.bukkit.event.player.PlayerSwapHandItemsEvent

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
    val confirmationKey: SkipConfirmationKey = SkipConfirmationKey.SNEAK,
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

enum class SkipConfirmationKey(val keybind: String, val bedrockKeybind: String) {
    SNEAK("<key:key.sneak>", "Sneak"),
    SWAP_HANDS("<key:key.swapOffhand>", "Swap Offhand"),
    ;

    fun keybind(player: Player): String {
        return if (player.isFloodgate) bedrockKeybind else keybind
    }
}

class SkipCinematicAction(
    private val player: Player,
    val entry: SkipCinematicEntry,
) : SimpleCinematicAction<SkipSegment>() {
    override val segments: List<SkipSegment> = entry.segments
    private var bundle: InterceptionBundle? = null
    private var listener: Listener? = null

    override suspend fun startSegment(segment: SkipSegment) {
        super.startSegment(segment)

        when (entry.confirmationKey) {
            SkipConfirmationKey.SNEAK -> {
                bundle = player.interceptPackets {
                    Play.Client.ENTITY_ACTION { event ->
                        val packet = WrapperPlayClientEntityAction(event)
                        if (packet.entityId != player.entityId) return@ENTITY_ACTION
                        if (packet.action != WrapperPlayClientEntityAction.Action.START_SNEAKING) return@ENTITY_ACTION
                        TemporalSetFrameTrigger(segment.endFrame).triggerFor(
                            player,
                            player.interactionContext ?: context()
                        )
                    }
                }
            }

            SkipConfirmationKey.SWAP_HANDS -> {
                val listener = SimpleListener()
                this.listener = listener
                plugin.listen<PlayerSwapHandItemsEvent>(listener) {
                    if (it.player.uniqueId != player.uniqueId) return@listen
                    TemporalSetFrameTrigger(segment.endFrame).triggerFor(player, player.interactionContext ?: context())
                    it.isCancelled = true
                }
            }
        }

        CinematicSkippableEvent(player, true, entry.confirmationKey).callEvent()
    }

    override suspend fun stopSegment(segment: SkipSegment) {
        super.stopSegment(segment)
        CinematicSkippableEvent(player, false, entry.confirmationKey).callEvent()
        bundle?.cancel()
        bundle = null
        listener?.unregister()
        listener = null
    }
}

class CinematicSkippableEvent(player: Player, val canSkip: Boolean, val confirmationKey: SkipConfirmationKey) :
    PlayerEvent(player, !Bukkit.isPrimaryThread()) {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()

        @JvmStatic
        fun getHandlerList(): HandlerList = HANDLER_LIST
    }
}
