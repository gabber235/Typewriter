package com.typewritermc.basic.entries.cinematic

import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientChatCommand
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientChatCommandUnsigned
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Regex
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.CinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player

@Entry("block_command_cinematic", "Block commands during the cinematic", Colors.RED, "mdi:console")
/**
 * The `Block Command Cinematic` entry is used to block commands during the cinematic.
 *
 * The `/typewriter` command is always allowed.
 *
 * ## How could this be used?
 *
 * This could be used to block commands during a cinematic.
 */
class BlockCommandCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(Colors.RED, "mdi:console")
    val segments: List<BlockCommandSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction = BlockCommandCinematicAction(player, this)
}

data class BlockCommandSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @Regex
    @Help("No need to include the slash. For example, use `say` instead of `/say`")
    val allowedCommands: List<String> = emptyList(),
) : Segment

class BlockCommandCinematicAction(
    private val player: Player,
    entry: BlockCommandCinematicEntry,
) : SimpleCinematicAction<BlockCommandSegment>() {
    override val segments: List<BlockCommandSegment> = entry.segments

    private var bundle: InterceptionBundle? = null
    private val ranCommands = mutableListOf<String>()

    override suspend fun startSegment(segment: BlockCommandSegment) {
        super.startSegment(segment)
        bundle = player.interceptPackets {
            PacketType.Play.Client.CHAT_COMMAND { event ->
                val packet = WrapperPlayClientChatCommand(event)
                if (isAllowedCommand(segment, packet.command)) {
                    return@CHAT_COMMAND
                }
                ranCommands.add(packet.command)
                event.isCancelled = true
            }

            PacketType.Play.Client.CHAT_COMMAND_UNSIGNED { event ->
                val packet = WrapperPlayClientChatCommandUnsigned(event)
                if (isAllowedCommand(segment, packet.command)) {
                    return@CHAT_COMMAND_UNSIGNED
                }
                ranCommands.add(packet.command)
                event.isCancelled = true
            }
        }
    }

    override suspend fun stopSegment(segment: BlockCommandSegment) {
        super.stopSegment(segment)
        bundle?.cancel()
        bundle = null
        if (ranCommands.isNotEmpty()) {
            Dispatchers.Sync.switchContext {
                ranCommands.forEach {
                    player.performCommand(it)
                }
            }
        }
        ranCommands.clear()
    }

    private fun isAllowedCommand(segment: BlockCommandSegment, command: String): Boolean {
        if (command.startsWith("tw")) return true
        if (command.startsWith("typewriter")) return true
        return segment.allowedCommands.any { allowedCommand ->
            Regex(allowedCommand).matches(command)
        }
    }
}