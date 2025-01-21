package com.typewritermc.basic.entries.audience

import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTimeUpdate
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.interceptPackets
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "freeze_time_audience",
    "Freezes the game time for a player to a specific time",
    Colors.GREEN,
    "mingcute:sandglass-fill"
)
/**
 * The `FreezeTimeAudienceEntry` is an audience that freezes the game time for a player to a specific time.
 *
 * The total time of a Minecraft day is `24000` ticks.
 * Some examples of times are:
 * ------------------------------
 * | Time of day | Ticks        |
 * |-------------|--------------|
 * | Dawn        | 0            |
 * | Noon        | 6000         |
 * | Dusk        | 12000        |
 * | Midnight    | 18000        |
 * ------------------------------
 *
 * ## How could this be used?
 * This could be used to keep the time to morning for a player, so that it is always sunrise.
 */
class FreezeTimeAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    val time: Var<Long> = ConstVar(0),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = FreezeTimeAudienceDisplay(time)
}

class FreezeTimeAudienceDisplay(
    private val time: Var<Long>,
) : AudienceDisplay(), TickableDisplay {
    private val interceptors = ConcurrentHashMap<UUID, InterceptionBundle>()

    override fun onPlayerAdd(player: Player) {
        interceptors[player.uniqueId] = player.interceptPackets {
            PacketType.Play.Server.TIME_UPDATE { event ->
                val packet = WrapperPlayServerTimeUpdate(event)
                packet.timeOfDay = time.get(player)
                packet.isTickTime = false
            }
        }
        player.setPlayerTime(time.get(player), false)
    }

    override fun tick() {
        players.forEach { player ->
            player.setPlayerTime(time.get(player), false)
            WrapperPlayServerTimeUpdate(player.world.gameTime, time.get(player), false).sendPacketTo(player)
        }
    }

    override fun onPlayerRemove(player: Player) {
        interceptors.remove(player.uniqueId)?.cancel()
        player.resetPlayerTime()
        WrapperPlayServerTimeUpdate(player.world.gameTime, player.playerTime, false).sendPacketTo(player)
    }

}