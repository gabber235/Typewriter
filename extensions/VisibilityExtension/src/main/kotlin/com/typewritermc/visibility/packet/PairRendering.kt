package com.typewritermc.visibility.packet

import com.destroystokyo.paper.ClientOption
import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.netty.channel.ChannelHelper
import com.github.retrooper.packetevents.protocol.entity.EntityPositionData
import com.github.retrooper.packetevents.protocol.player.TextureProperty
import com.github.retrooper.packetevents.protocol.player.User
import com.github.retrooper.packetevents.protocol.player.UserProfile
import com.github.retrooper.packetevents.protocol.teleport.RelativeFlag
import com.github.retrooper.packetevents.protocol.world.Difficulty
import com.github.retrooper.packetevents.protocol.world.WorldBlockPosition
import com.github.retrooper.packetevents.resources.ResourceLocation
import com.github.retrooper.packetevents.util.Vector3d
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerCamera
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerChangeGameState
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityEffect
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityStatus
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerHeldItemChange
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerAbilities
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoRemove
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerPositionAndLook
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerRespawn
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetExperience
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetPassengers
import com.google.common.hash.Hashing
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.VisibilityHideRegistry
import com.typewritermc.visibility.rule.PlayerPair
import com.typewritermc.visibility.rule.VisibilityRule
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.text.Component
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.entity.Entity
import org.bukkit.entity.Player
import org.bukkit.event.inventory.InventoryType
import org.bukkit.potion.PotionEffect
import org.koin.java.KoinJavaComponent
import java.util.EnumSet
import java.util.logging.Logger

val VisibilityRule.viewerPlayer: Player? get() = server.getPlayer(viewer)
val VisibilityRule.targetPlayer: Player? get() = server.getPlayer(target)

private val hideRegistry: VisibilityHideRegistry
    get() = KoinJavaComponent.get(VisibilityHideRegistry::class.java)

private val bridge: VisibilityPacketBridge
    get() = KoinJavaComponent.get(VisibilityPacketBridge::class.java)

private val logger: Logger
    get() = KoinJavaComponent.get(Logger::class.java)

/**
 * Forces the server to re send every tracking packet of the target to the viewer by untracking and
 * re tracking the pair. The re sent packets pass through the [VisibilityPacketBridge], so hooks
 * registered before this runs apply to the fresh state.
 *
 * Driven by the engine once per lifecycle transition, for the effectors that report
 * [com.typewritermc.visibility.effector.VisibilityEffector.needsPairRerender]. Used for effects that
 * only apply on spawn, such as skins and names. Metadata style effects send synthetic packets
 * instead, which avoids the respawn flicker entirely.
 *
 * A disguised pair only gets its tab list entry back: hiding the target removes it along with the
 * world entity, and cycling the entity here would reveal the real target beside the fake. The
 * entry passes the profile hooks like a tracked re add does, so a bundled name effect still
 * renames it.
 *
 * A player cannot untrack themselves, so a self pair makes their own client respawn in place
 * instead, see [refreshOwnProfile].
 */
suspend fun PlayerPair.refreshRendering() {
    Dispatchers.Sync.switchContext {
        // Bukkit refuses to hide anyone once the plugin is disabled, and by then every client is
        // being dropped anyway.
        if (!plugin.isEnabled) return@switchContext
        val viewerPlayer = server.getPlayer(viewer) ?: return@switchContext
        if (viewer == target) {
            viewerPlayer.refreshOwnProfile()
            return@switchContext
        }
        val targetPlayer = server.getPlayer(target) ?: return@switchContext
        if (hideRegistry.replacementFor(viewer, target) != null) {
            resendTabEntry(viewerPlayer, targetPlayer)
            return@switchContext
        }
        if (!viewerPlayer.canSee(targetPlayer)) return@switchContext
        viewerPlayer.hidePlayer(plugin, targetPlayer)
        viewerPlayer.showPlayer(plugin, targetPlayer)
    }
}

/**
 * Removes the target's tab list entry for the viewer and adds it again from live server state.
 *
 * Only the entry travels, never the world entity, which stays hidden while a disguise is active.
 * The add passes the profile hooks, so hiding this behind the hook registration in the lifecycle
 * is what renames and reskins the entry.
 */
private fun resendTabEntry(viewer: Player, target: Player) {
    val viewerUser = PacketEvents.getAPI().playerManager.getUser(viewer) ?: return
    val targetUser = PacketEvents.getAPI().playerManager.getUser(target)
    val records = bridge
    val profile = UserProfile(
        target.uniqueId,
        target.name,
        target.playerProfile.properties.map { TextureProperty(it.name, it.value, it.signature) },
    )
    val listed = viewer.isListed(target)
    val latency = target.ping
    val gameMode = SpigotConversionUtil.fromBukkitGameMode(target.gameMode)
    // The api answers the plain name when no list name is set, where the server sends none. A display
    // name replaces the team formatting in the tab list, so the plain name is not sent as one.
    val displayName = target.playerListName().takeUnless { it == Component.text(target.name) }
    val listOrder = target.playerListOrder
    val showHat = target.getClientOption(ClientOption.SKIN_PARTS).hasHatsEnabled()

    // A client rejects the signed chat of a player whose entry carries no chat session. The session
    // is read on the viewer's event loop: for the viewer's own entry, a session the server announced
    // just before this call is recorded by the time the read runs.
    ChannelHelper.runInEventLoop(viewerUser.channel) {
        val chatSession = targetUser?.let { records.ownChatSession(it) }?.orElse(null)
        val entry = WrapperPlayServerPlayerInfoUpdate.PlayerInfo(
            profile,
            listed,
            latency,
            gameMode,
            displayName,
            chatSession,
            listOrder,
            showHat,
        )
        viewerUser.sendPacket(WrapperPlayServerPlayerInfoRemove(target.uniqueId))
        // Every action set, the way the server initializes an entry it tracks. Each action carries
        // its own slice of the entry, so sending only the add would drop the listed flag, the latency
        // and the game mode on the client.
        viewerUser.sendPacket(WrapperPlayServerPlayerInfoUpdate(TAB_INIT_ACTIONS, entry))
    }
}

/**
 * Makes the player's own client read their tab list entry again, so a skin that a profile hook
 * rewrote shows on their own model and not only in the tab list.
 *
 * A client only replaces a tab list entry that was removed first, and its local player looks its
 * entry up once and keeps it. The entry is therefore removed and added again, and a respawn into the
 * level the player is already in makes the client build a new local player that looks the new entry
 * up. Paper's `Player.setPlayerProfile` runs the same sequence for the player themselves, but also
 * re adds them for everyone else who sees them.
 */
private fun Player.refreshOwnProfile() {
    val user = PacketEvents.getAPI().playerManager.getUser(this) ?: return
    if (bridge.ownChatSession(user) == null || bridge.ownPermissionLevel(user) == null) {
        logger.warning(
            "$name was already connected when the visibility extension started, so the skin they see on " +
                    "themselves only changes once they reconnect."
        )
        return
    }

    resendTabEntry(this, this)
    // A respawn closes the death screen. Respawning from it builds a new local player too, which
    // reads the entry sent above.
    if (isDead) return
    respawnInPlace(user)
}

/**
 * Respawns the client into the level it is already in and sends again what the client resets on its
 * new local player. The level, the entity data and the attributes survive the respawn on the client.
 */
private fun Player.respawnInPlace(user: User) {
    // The client closes an open container by itself when it respawns, but the inventory sent below
    // would still be addressed to that container, which leaves the client showing an empty inventory.
    if (openInventory.type !in OWN_INVENTORY_VIEW_TYPES) closeInventory()

    val currentWorld = world
    WrapperPlayServerRespawn(
        user.dimensionType,
        currentWorld.key.asString(),
        Difficulty.valueOf(currentWorld.difficulty.name),
        Hashing.sha256().hashLong(currentWorld.seed).asLong(),
        SpigotConversionUtil.fromBukkitGameMode(gameMode),
        previousGameMode?.let(SpigotConversionUtil::fromBukkitGameMode),
        // Debug and flat are only read when the dimension changes, which a respawn into the current
        // level never does.
        false,
        false,
        WrapperPlayServerRespawn.KEEP_ALL_DATA,
        lastDeathLocation?.toWorldBlockPosition(),
        portalCooldown,
        currentWorld.seaLevel,
    ) sendPacketTo this

    // The new local player starts at the origin. Its rotation and motion were carried over, so both
    // stay relative.
    val position = location
    WrapperPlayServerPlayerPositionAndLook(
        OWN_REFRESH_TELEPORT_ID,
        EntityPositionData(Vector3d(position.x, position.y, position.z), Vector3d.zero(), 0f, 0f),
        KEEP_CLIENT_ROTATION_AND_MOTION,
    ) sendPacketTo this
    // The respawn opens the loading screen, which only starts waiting for the player's chunk once the
    // server says chunks are coming. Without this game event the screen never closes.
    WrapperPlayServerChangeGameState(WrapperPlayServerChangeGameState.Reason.START_LOADING_CHUNKS, 0f) sendPacketTo this

    // The server derives invulnerability and instant building from the game mode, and the api reports
    // both speeds doubled.
    val currentGameMode = gameMode
    WrapperPlayServerPlayerAbilities(
        currentGameMode == GameMode.CREATIVE || currentGameMode == GameMode.SPECTATOR,
        isFlying,
        allowFlight,
        currentGameMode == GameMode.CREATIVE,
        flySpeed / 2,
        walkSpeed / 2,
    ) sendPacketTo this

    WrapperPlayServerHeldItemChange(inventory.heldItemSlot) sendPacketTo this
    updateInventory()
    WrapperPlayServerSetExperience(exp, level, totalExperience) sendPacketTo this
    sendHealthUpdate()
    for (effect in activePotionEffects) {
        val type = SpigotConversionUtil.fromBukkitPotionEffectType(effect.type) ?: continue
        val flags = effect.packetFlags()
        WrapperPlayServerEntityEffect(entityId, type, effect.amplifier, effect.duration, flags) sendPacketTo this
    }
    resendPermissionLevel(user)

    spectatorTarget?.let { WrapperPlayServerCamera(it.entityId) sendPacketTo this }
    vehicle?.let { resendPassengers(it) }
    if (passengers.isNotEmpty()) resendPassengers(this)
}

/**
 * Sends the recorded permission level again, reading it on the connection's event loop. A level
 * change the server queued before this call is encoded, and therefore recorded, by the time the read
 * runs.
 */
private fun Player.resendPermissionLevel(user: User) {
    val ownEntityId = entityId
    val records = bridge
    ChannelHelper.runInEventLoop(user.channel) {
        val level = records.ownPermissionLevel(user) ?: return@runInEventLoop
        user.sendPacket(WrapperPlayServerEntityStatus(ownEntityId, PERMISSION_LEVEL_EVENT_IDS.first + level))
    }
}

private fun Player.resendPassengers(vehicle: Entity) {
    val passengerIds = vehicle.passengers.map { it.entityId }.toIntArray()
    WrapperPlayServerSetPassengers(vehicle.entityId, passengerIds) sendPacketTo this
}

private fun Location.toWorldBlockPosition(): WorldBlockPosition? {
    if (!isWorldLoaded) return null
    return WorldBlockPosition(ResourceLocation(world.key.asString()), blockX, blockY, blockZ)
}

private fun PotionEffect.packetFlags(): Byte {
    var flags = 0
    if (isAmbient) flags = flags or EFFECT_FLAG_AMBIENT
    if (hasParticles()) flags = flags or EFFECT_FLAG_VISIBLE
    if (hasIcon()) flags = flags or EFFECT_FLAG_SHOW_ICON
    return flags.toByte()
}

private val TAB_INIT_ACTIONS: EnumSet<WrapperPlayServerPlayerInfoUpdate.Action> = EnumSet.of(
    WrapperPlayServerPlayerInfoUpdate.Action.ADD_PLAYER,
    WrapperPlayServerPlayerInfoUpdate.Action.INITIALIZE_CHAT,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_GAME_MODE,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_LISTED,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_LATENCY,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_DISPLAY_NAME,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_LIST_ORDER,
    WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_HAT,
)

private val OWN_INVENTORY_VIEW_TYPES = setOf(InventoryType.CRAFTING, InventoryType.CREATIVE)

/**
 * The server counts its own teleport ids up from zero and never waits for a negative one, so it
 * ignores the client confirming this teleport. Confirming an id the server does wait for while it has
 * no teleport pending disconnects the player.
 */
private const val OWN_REFRESH_TELEPORT_ID = -1

private val KEEP_CLIENT_ROTATION_AND_MOTION: RelativeFlag = RelativeFlag.YAW
    .or(RelativeFlag.PITCH)
    .or(RelativeFlag.DELTA_X)
    .or(RelativeFlag.DELTA_Y)
    .or(RelativeFlag.DELTA_Z)

private const val EFFECT_FLAG_AMBIENT = 0x01
private const val EFFECT_FLAG_VISIBLE = 0x02
private const val EFFECT_FLAG_SHOW_ICON = 0x04
