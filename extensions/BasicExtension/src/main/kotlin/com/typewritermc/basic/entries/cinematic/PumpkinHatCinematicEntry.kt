package com.typewritermc.basic.entries.cinematic

import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.protocol.player.Equipment
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityEquipment
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetSlot
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.PrimaryCinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.extensions.packetevents.toPacketItem
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.name
import com.typewritermc.engine.paper.utils.unClickable
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.inventory.ItemStack
import java.util.*

@Entry("pumpkin_hat_cinematic", "Show a pumpkin hat during a cinematic", Colors.CYAN, "mingcute:hat-fill")
/**
 * The `Pumpkin Hat Cinematic` is a cinematic that shows a pumpkin hat on the player's head.
 *
 * ## How could this be used?
 * When you have a resource pack, you can re-texture the pumpkin overlay to make it look like cinematic black bars.
 */
class PumpkinHatCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val customItem: Optional<Var<Item>> = Optional.empty(),
    @Segments(icon = "mingcute:hat-fill")
    val segments: List<PumpkinHatSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction {
        return PumpkinHatCinematicAction(
            player,
            this,
        )
    }

    override fun createSimulating(player: Player): CinematicAction? = null
}

data class PumpkinHatSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
) : Segment

class PumpkinHatCinematicAction(
    private val player: Player,
    private val entry: PumpkinHatCinematicEntry,
) : SimpleCinematicAction<PumpkinHatSegment>() {
    override val segments: List<PumpkinHatSegment> = entry.segments

    private var interceptor: InterceptionBundle? = null

    override suspend fun startSegment(segment: PumpkinHatSegment) {
        super.startSegment(segment)
        val item = entry.customItem.map {
            it.get(player).build(player).apply {
                editMeta { meta ->
                    meta.unClickable()
                }
            }
        }.orElseGet {
            ItemStack(Material.CARVED_PUMPKIN)
                .apply {
                    editMeta { meta ->
                        meta.name = " "
                        meta.unClickable()
                    }
                }
        }
            .toPacketItem()
        interceptor = player.interceptPackets {
            PacketType.Play.Server.SET_SLOT { event ->
                val packet = WrapperPlayServerSetSlot(event)
                if (packet.slot != 39) return@SET_SLOT
                packet.item = item
            }
        }

        WrapperPlayServerEntityEquipment(
            player.entityId,
            listOf(Equipment(com.github.retrooper.packetevents.protocol.player.EquipmentSlot.HELMET, item))
        ) sendPacketTo player

    }

    override suspend fun stopSegment(segment: PumpkinHatSegment) {
        super.stopSegment(segment)
        interceptor?.cancel()
        interceptor = null
        WrapperPlayServerEntityEquipment(
            player.entityId,
            listOf(
                Equipment(
                    com.github.retrooper.packetevents.protocol.player.EquipmentSlot.HELMET,
                    player.inventory.helmet?.toPacketItem()
                        ?: com.github.retrooper.packetevents.protocol.item.ItemStack.EMPTY
                )
            )
        ) sendPacketTo player
    }
}