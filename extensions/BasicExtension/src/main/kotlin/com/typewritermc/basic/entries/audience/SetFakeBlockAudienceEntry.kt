package com.typewritermc.basic.entries.audience

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerBlockChange
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toPacketVector3i
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import org.bukkit.Material
import org.bukkit.entity.Player
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

@Entry("set_fake_block_audience", "Set a fake block for an audience", Colors.GREEN, "mingcute:cube-3d-fill")
/**
 * The `SetFakeBlockAudienceEntry` is an audience entry that would set a fake block.
 *
 * ## How could this be used?
 * This could be used to create illusions or special effects for players.
 */
class SetFakeBlockAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The location where the fake block will be set")
    val location: Var<Position> = ConstVar(Position.ORIGIN),
    @Help("The fake block material to set.")
    val block: Var<Material> = ConstVar(Material.AIR),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        return SetFakeBlockDisplay(location, block)
    }
}

private data class PlayerBlockState(
    val position: Position,
    val material: Material
)

class SetFakeBlockDisplay(
    private val position: Var<Position>,
    private val block: Var<Material>,
) : AudienceDisplay(), TickableDisplay {
    private val blocks = ConcurrentHashMap<UUID, PlayerBlockState>()

    override fun tick() {
        for ((playerId, state) in blocks) {
            val player = server.getPlayer(playerId) ?: continue
            val context = player.interactionContext

            val currentPosition = position.get(player, context)
            val currentMaterial = block.get(player, context)

            if (currentPosition != state.position || currentMaterial != state.material) {
                sendBlockChange(player, currentPosition, currentMaterial)
                blocks[playerId] = PlayerBlockState(currentPosition, currentMaterial)
            }
        }
    }

    override fun onPlayerAdd(player: Player) {
        val context = player.interactionContext
        val position = position.get(player, context)
        val material = block.get(player, context)

        blocks[player.uniqueId] = PlayerBlockState(position, material)
        sendBlockChange(player, position, material)
    }

    override fun onPlayerRemove(player: Player) {
        val state = blocks.remove(player.uniqueId) ?: return
        val originalBlock = state.position.toBukkitLocation().block
        sendBlockChange(player, state.position, originalBlock.type)
    }

    private fun sendBlockChange(player: Player, position: Position, material: Material) {
        val packet = WrapperPlayServerBlockChange(
            position.toPacketVector3i(),
            SpigotConversionUtil.fromBukkitBlockData(material.createBlockData())
        )
        packet.sendPacketTo(player)
    }
}