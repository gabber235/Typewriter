package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.world.Location
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetPassengers
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.toPacketLocation
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityPacketHook
import com.typewritermc.visibility.packet.TeamContribution
import com.typewritermc.visibility.packet.TeamContributionKind
import com.typewritermc.visibility.packet.VisibilityPacketBridge
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.packet.WrapperPlayServerSpawnInfo
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import me.tofaa.entitylib.meta.display.TextDisplayMeta
import me.tofaa.entitylib.wrapper.WrapperEntity
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.concurrent.locks.ReentrantLock
import kotlin.concurrent.withLock

/**
 * How the target's nametag is changed for the viewer.
 */
sealed interface NametagModification

/**
 * Where the extra nametag line sits relative to the target's real name.
 */
enum class NametagLinePosition { ABOVE, BELOW }

/**
 * Completely hides the target's nametag.
 */
@AlgebraicTypeInfo("hidden", Colors.RED, "mdi:tag-off")
class HiddenNametag : NametagModification {
    override fun equals(other: Any?): Boolean = other is HiddenNametag
    override fun hashCode(): Int = javaClass.hashCode()
}

/**
 * Hides the real nametag and shows a custom text in its place.
 */
@AlgebraicTypeInfo("replaced", Colors.BLUE, "mdi:tag-edit")
data class ReplacedNametag(
    @Colored
    @Placeholder
    val text: Var<String> = ConstVar(""),
) : NametagModification

/**
 * Keeps the real nametag and shows an extra line of text above or below it.
 */
@AlgebraicTypeInfo("text_above", Colors.GREEN, "mdi:tag-plus")
data class ExtraLineNametag(
    @Colored
    @Placeholder
    val text: Var<String> = ConstVar(""),
    @Help("Whether the extra line sits above or below the real name.")
    val position: NametagLinePosition = NametagLinePosition.ABOVE,
    @Help("Extra vertical offset added to the line, in blocks.")
    val offset: Var<Double> = ConstVar(0.0),
) : NametagModification

@Entry(
    "nametag_visibility_effect",
    "Changes the target's nametag for the viewer",
    Colors.PINK,
    "mdi:tag-text"
)
/**
 * The `Nametag Visibility Effect` changes how the viewer sees the target's nametag. It can hide
 * the tag, replace it with custom text, or add an extra line of text above or below the real name.
 *
 * Custom text supports placeholders and rich formatting, and is resolved for the viewer when the
 * effect activates.
 *
 * ## How could this be used?
 * Hide the names of players in a mystery minigame, give an undercover player a fake name, or
 * show a title like a shop owner's profession above their name.
 */
class NametagVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("How the target's nametag is changed for the viewer.")
    val modification: NametagModification = HiddenNametag(),
) : VisibilityEffectEntry {
    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        NametagVisibilityEffector(rule, modification)
}

private class NametagVisibilityEffector(
    private val rule: VisibilityRule,
    private val modification: NametagModification,
) : VisibilityEffector, EntityPacketHook, KoinComponent {
    private val bridge: VisibilityPacketBridge by inject()
    private val teamManager: VisibilityTeamManager by inject()

    /**
     * Guards the text display against the packet hooks, which run on netty threads while the lifecycle
     * runs on the server thread. Without it a queued respawn could recreate the display after disposal
     * removed it, leaving an entity nothing owns.
     */
    private val displayLock = ReentrantLock()
    private var disposed = false

    @Volatile
    private var targetEntityId = -1

    @Volatile
    private var hooked = false

    @Volatile
    private var textDisplay: WrapperEntity? = null

    @Volatile
    private var realPassengers: IntArray = IntArray(0)

    override suspend fun initialize() {
        Dispatchers.Sync.switchContext {
            if (rule.isSelf) return@switchContext
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            targetEntityId = target.entityId

            if (modification.hidesRealNametag) {
                teamManager.contribute(
                    viewer,
                    target,
                    TeamContribution(kind = TeamContributionKind.NAMETAG_HIDDEN, hidesNametag = true),
                )
            }

            // Only the extra line needs packets rewritten. Hiding the real tag is entirely a team.
            val text = modification.customText ?: return@switchContext

            bridge.addEntityHook(viewer.uniqueId, target.entityId, this@NametagVisibilityEffector)
            hooked = true

            realPassengers = target.realPassengerIds()
            val display = createTextDisplay(viewer, text)
            display.addViewer(viewer.uniqueId)
            displayLock.withLock {
                if (disposed) return@withLock
                // The field is set before the spawn: a spawn that throws partway has already placed
                // entities on the client, and only dispose can remove those.
                textDisplay = display
                display.spawn(target.location.toPacketLocation())
            }
            sendMountPacket(viewer, target.entityId, realPassengers)
        }
    }

    override fun onPassengers(packet: WrapperPlayServerSetPassengers) {
        val display = textDisplay ?: return
        val passengers = packet.passengers
        if (passengers.contains(display.entityId)) return
        realPassengers = passengers
        packet.passengers = passengers + display.entityId
    }

    override fun onSpawn(event: PacketSendEvent, packet: WrapperPlayServerSpawnInfo) {
        if (textDisplay == null) return
        val location = Location(packet.x, packet.y, packet.z, packet.yaw, packet.pitch)
        event.tasksAfterSend.add {
            // Spawning the display renders its metadata, and rendering reads the viewer's locale from
            // the server. This runs on a netty thread, where the Bukkit api is off limits, so the
            // respawn is scheduled rather than run here.
            bridge.onServerThread { respawnDisplay(location) }
        }
    }

    private fun respawnDisplay(location: Location) {
        displayLock.withLock {
            if (disposed) return@withLock
            val display = textDisplay ?: return@withLock
            val viewer = rule.viewerPlayer ?: return@withLock
            val entityId = targetEntityId
            if (entityId == -1) return@withLock

            // A client can drop entities without a destroy packet, as it does on a dimension change.
            // The display would still count as spawned and the spawn below would send nothing.
            display.despawn()
            display.spawn(location)
            // Read here rather than when the spawn packet passed, because the passenger packet
            // belonging to the same re add only reaches the hook afterwards.
            sendMountPacket(viewer, entityId, realPassengers)
        }
    }

    override fun onDestroy(event: PacketSendEvent) {
        if (textDisplay == null) return
        event.tasksAfterSend.add {
            // The despawn is scheduled, not run here, even though it is only a destroy packet and would
            // be safe on this thread. The respawn has to run on the server thread, and the two only
            // keep the order the client needs while they run on the same one: a spawn followed by a
            // destroy would otherwise despawn first and then recreate the display.
            bridge.onServerThread { despawnDisplay() }
        }
    }

    private fun despawnDisplay() {
        displayLock.withLock {
            if (disposed) return@withLock
            textDisplay?.despawn()
        }
    }

    override suspend fun dispose() {
        Dispatchers.Sync.switchContext {
            val entityId = targetEntityId
            if (entityId != -1) {
                if (hooked) bridge.removeEntityHook(rule.viewer, entityId, this@NametagVisibilityEffector)
                if (modification.hidesRealNametag) {
                    teamManager.withdraw(rule.viewer, entityId, TeamContributionKind.NAMETAG_HIDDEN)
                }
            }

            displayLock.withLock {
                disposed = true
                textDisplay?.let { display ->
                    display.despawn()
                    display.remove()
                }
                textDisplay = null
            }
        }
    }

    private fun createTextDisplay(viewer: Player, text: Var<String>): WrapperEntity {
        val display = WrapperEntity(EntityTypes.TEXT_DISPLAY)
        val component = text.get(viewer).parsePlaceholders(viewer).asMini()
        display.meta<TextDisplayMeta> {
            this.text = component
            billboardConstraints = AbstractDisplayMeta.BillboardConstraints.CENTER
            translation = Vector3f(0f, lineOffset(viewer), 0f)
        }
        return display
    }

    private fun lineOffset(viewer: Player): Float {
        val extraLine = modification as? ExtraLineNametag ?: return NAME_ANCHOR_OFFSET
        val base = when (extraLine.position) {
            NametagLinePosition.ABOVE -> ABOVE_OFFSET
            NametagLinePosition.BELOW -> BELOW_OFFSET
        }
        return base + extraLine.offset.get(viewer).toFloat()
    }

    private fun Player.realPassengerIds(): IntArray = passengers.map { it.entityId }.toIntArray()

    private fun sendMountPacket(viewer: Player, targetEntityId: Int, realPassengers: IntArray) {
        val display = textDisplay ?: return
        WrapperPlayServerSetPassengers(
            targetEntityId,
            realPassengers + display.entityId,
        ) sendPacketTo viewer
    }

    private companion object {
        const val NAME_ANCHOR_OFFSET = 0.3f
        const val ABOVE_OFFSET = 0.6f
        const val BELOW_OFFSET = 0.0f
    }
}

private val NametagModification.hidesRealNametag: Boolean
    get() = this is HiddenNametag || this is ReplacedNametag

private val NametagModification.customText: Var<String>?
    get() = when (this) {
        is HiddenNametag -> null
        is ReplacedNametag -> text
        is ExtraLineNametag -> text
    }
