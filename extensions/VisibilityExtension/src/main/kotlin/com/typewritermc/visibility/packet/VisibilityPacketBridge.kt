package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.event.PacketListenerAbstract
import com.github.retrooper.packetevents.event.PacketListenerPriority
import com.github.retrooper.packetevents.event.PacketSendEvent
import com.github.retrooper.packetevents.netty.buffer.ByteBufHelper
import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerDestroyEntities
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityEquipment
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerEntityMetadata
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSetPassengers
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerSpawnEntity
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerUpdateAttributes
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Routes the packets a viewer receives to the hooks that visibility effectors registered.
 *
 * A single packet listener serves all effectors. Dispatch is a constant time lookup by viewer and
 * then by entity id or profile id, so servers without active visibility effects pay a single map
 * lookup per packet, and viewers with effects pay only for the entities they have hooks on. Destroy
 * and player info packets are the exception: their ids are only reachable by parsing, so a viewer
 * with a hook of the matching kind pays for those in full. Team packets are read off the buffer by
 * hand, since a wrapper cannot round trip them.
 */
@Singleton
class VisibilityPacketBridge : PacketListenerAbstract(PacketListenerPriority.NORMAL), Initializable,
    KoinComponent {
    private val teamManager: VisibilityTeamManager by inject()
    private val entityHooks =
        ConcurrentHashMap<UUID, ConcurrentHashMap<Int, CopyOnWriteArrayList<EntityPacketHook>>>()
    private val profileHooks =
        ConcurrentHashMap<UUID, ConcurrentHashMap<UUID, CopyOnWriteArrayList<ProfilePacketHook>>>()

    // The scope is built on first use. Resolving the server thread dispatcher requires the running
    // plugin, which a bridge that never schedules anything should not depend on.
    private val serverThreadScope = lazy { CoroutineScope(SupervisorJob() + Dispatchers.Sync) }

    override suspend fun initialize() {
        PacketEvents.getAPI().eventManager.registerListener(this)
    }

    override suspend fun shutdown() {
        PacketEvents.getAPI().eventManager.unregisterListener(this)
        if (serverThreadScope.isInitialized()) serverThreadScope.value.cancel()
        entityHooks.clear()
        profileHooks.clear()
    }

    fun addEntityHook(viewer: UUID, entityId: Int, hook: EntityPacketHook) {
        entityHooks.compute(viewer) { _, existing ->
            val byEntity = existing ?: ConcurrentHashMap()
            byEntity.computeIfAbsent(entityId) { CopyOnWriteArrayList() }.add(hook)
            byEntity
        }
    }

    fun removeEntityHook(viewer: UUID, entityId: Int, hook: EntityPacketHook) {
        entityHooks.computeIfPresent(viewer) { _, byEntity ->
            byEntity.computeIfPresent(entityId) { _, hooks ->
                hooks.remove(hook)
                if (hooks.isEmpty()) null else hooks
            }
            if (byEntity.isEmpty()) null else byEntity
        }
    }

    fun addProfileHook(viewer: UUID, profileId: UUID, hook: ProfilePacketHook) {
        profileHooks.compute(viewer) { _, existing ->
            val byProfile = existing ?: ConcurrentHashMap()
            byProfile.computeIfAbsent(profileId) { CopyOnWriteArrayList() }.add(hook)
            byProfile
        }
    }

    fun removeProfileHook(viewer: UUID, profileId: UUID, hook: ProfilePacketHook) {
        profileHooks.computeIfPresent(viewer) { _, byProfile ->
            byProfile.computeIfPresent(profileId) { _, hooks ->
                hooks.remove(hook)
                if (hooks.isEmpty()) null else hooks
            }
            if (byProfile.isEmpty()) null else byProfile
        }
    }

    /**
     * Drops every hook registered for a viewer.
     * Called when the viewer disconnects, so hooks of an effector that could no longer clean up after
     * itself do not survive into the next session of the same player.
     */
    fun forget(viewer: UUID) {
        entityHooks.remove(viewer)
        profileHooks.remove(viewer)
    }

    internal fun entityHookCount(viewer: UUID, entityId: Int): Int =
        entityHooks[viewer]?.get(entityId)?.size ?: 0

    internal fun profileHookCount(viewer: UUID, profileId: UUID): Int =
        profileHooks[viewer]?.get(profileId)?.size ?: 0

    internal fun hasHooksFor(viewer: UUID): Boolean =
        entityHooks.containsKey(viewer) || profileHooks.containsKey(viewer)

    override fun onPacketSend(event: PacketSendEvent?) {
        if (event == null) return
        val viewerId = event.user.uuid ?: return

        when (event.packetType) {
            PacketType.Play.Server.ENTITY_METADATA -> handleMetadata(viewerId, event)
            PacketType.Play.Server.ENTITY_EQUIPMENT -> handleEquipment(viewerId, event)
            PacketType.Play.Server.UPDATE_ATTRIBUTES -> handleAttributes(viewerId, event)
            PacketType.Play.Server.SET_PASSENGERS -> handlePassengers(viewerId, event)
            PacketType.Play.Server.SPAWN_ENTITY -> handleSpawn(viewerId, event)
            PacketType.Play.Server.DESTROY_ENTITIES -> handleDestroy(viewerId, event)
            PacketType.Play.Server.PLAYER_INFO_UPDATE -> handlePlayerInfo(viewerId, event)
            PacketType.Play.Server.TEAMS -> handleTeams(viewerId, event)
        }
    }

    /**
     * The hooks of the viewer for the entity this packet is about, without parsing the packet.
     *
     * Building a wrapper registers it with packetevents as the event's last used wrapper, which
     * re encodes the packet whether anything changed or not. Reading only the leading entity id
     * confines that cost to entities that have a hook. Valid only for packets that start with the
     * entity id.
     */
    private fun hooksFor(viewerId: UUID, event: PacketSendEvent): List<EntityPacketHook>? {
        val byEntity = entityHooks[viewerId] ?: return null
        val entityId = peekEntityId(event) ?: return null
        return byEntity[entityId]
    }

    private fun peekEntityId(event: PacketSendEvent): Int? = peek(event) { _, nextByte ->
        decodeVarInt(nextByte)
    }

    private fun peekTeamPacketHead(event: PacketSendEvent): TeamPacketHead? =
        peek(event) { readable, nextByte -> decodeTeamPacketHead(readable, nextByte) }

    /**
     * Reads the start of the packet without consuming it, so a hook can be looked up before the packet
     * is committed to a re encode.
     */
    private fun <T> peek(event: PacketSendEvent, read: (Int, () -> Byte?) -> T?): T? {
        val buffer = event.byteBuf
        val start = ByteBufHelper.readerIndex(buffer)
        try {
            return read(ByteBufHelper.readableBytes(buffer)) {
                if (ByteBufHelper.readableBytes(buffer) <= 0) null else ByteBufHelper.readByte(buffer)
            }
        } finally {
            ByteBufHelper.readerIndex(buffer, start)
        }
    }

    private fun handleMetadata(viewerId: UUID, event: PacketSendEvent) {
        val hooks = hooksFor(viewerId, event) ?: return
        val packet = WrapperPlayServerEntityMetadata(event)
        hooks.forEach { it.onMetadata(packet) }
        event.markForReEncode(true)
    }

    private fun handleEquipment(viewerId: UUID, event: PacketSendEvent) {
        val hooks = hooksFor(viewerId, event) ?: return
        val packet = WrapperPlayServerEntityEquipment(event)
        hooks.forEach { it.onEquipment(packet) }
        event.markForReEncode(true)
    }

    private fun handleAttributes(viewerId: UUID, event: PacketSendEvent) {
        val hooks = hooksFor(viewerId, event) ?: return
        val packet = WrapperPlayServerUpdateAttributes(event)
        hooks.forEach { it.onAttributes(packet) }
        event.markForReEncode(true)
    }

    private fun handlePassengers(viewerId: UUID, event: PacketSendEvent) {
        val hooks = hooksFor(viewerId, event) ?: return
        val packet = WrapperPlayServerSetPassengers(event)
        hooks.forEach { it.onPassengers(packet) }
        event.markForReEncode(true)
    }

    private fun handleSpawn(viewerId: UUID, event: PacketSendEvent) {
        val hooks = hooksFor(viewerId, event) ?: return
        val packet = WrapperPlayServerSpawnEntity(event)
        val position = packet.position
        val info = WrapperPlayServerSpawnInfo(position.x, position.y, position.z, packet.yaw, packet.pitch)
        hooks.forEach { it.onSpawn(event, info) }
    }

    private fun handleDestroy(viewerId: UUID, event: PacketSendEvent) {
        val byEntity = entityHooks[viewerId] ?: return
        if (byEntity.isEmpty()) return
        val packet = WrapperPlayServerDestroyEntities(event)
        for (entityId in packet.entityIds) {
            val hooks = byEntity[entityId] ?: continue
            hooks.forEach { it.onDestroy(event) }
        }
    }


    private fun handlePlayerInfo(viewerId: UUID, event: PacketSendEvent) {
        val byProfile = profileHooks[viewerId] ?: return
        if (byProfile.isEmpty()) return
        // The packet opens with one byte of action bits. Only an add or a display name change carries
        // anything a profile hook rewrites, and a latency update comes round for every player every
        // few seconds, so the rest skip the decode and the re encode a wrapper costs.
        val actions = peek(event) { _, nextByte -> nextByte()?.toInt() } ?: return
        if (actions and PROFILE_HOOK_ACTIONS == 0) return
        val packet = WrapperPlayServerPlayerInfoUpdate(event)
        for (entry in packet.entries) {
            val hooks = byProfile[entry.profileId] ?: continue
            hooks.forEach { it.onPlayerInfo(packet.actions, entry) }
        }
        // Building the wrapper already committed this packet to a re encode, so a conditional flag
        // would save nothing here.
        event.markForReEncode(true)
    }

    /**
     * Keeps the server's own scoreboard packets off the names the team manager holds.
     *
     * A client entry belongs to exactly one team, so a real team claiming a name moved into one of
     * ours removes it from that team and the effect stops applying. Removing such a name is worse:
     * the client routes it through a vanilla method that throws when the entry sits on a different
     * team, which disconnects the viewer.
     *
     * The packet is read off the buffer rather than through a wrapper. Building one commits the
     * packet to a re encode, and that round trip is lossy: packetevents reads the `RESET` color that
     * every uncolored team carries as `WHITE`, so merely inspecting a team packet would recolor every
     * team on the server for this viewer.
     */
    private fun handleTeams(viewerId: UUID, event: PacketSendEvent) {
        val held = teamManager.heldTeamMembers(viewerId)
        if (held.isEmpty()) return

        val head = peekTeamPacketHead(event) ?: return
        if (head.teamName.startsWith(VISIBILITY_TEAM_PREFIX)) return

        // Any team packet may have changed the real team ours copy their prefix, suffix and collision
        // behaviour from, and identifying which one would require decoding the packet. Only the viewer
        // is recorded here: the engine's own tick serves the request, so a plugin rewriting its
        // scoreboard every tick cannot turn its packet volume into server thread work.
        teamManager.requestRealTeamRefresh(viewerId)

        val members = head.members
        if (members == null) {
            // A create keeps its member list behind component data that cannot be skipped without
            // decoding it. Letting it through and reclaiming our names immediately costs the viewer
            // one frame of the wrong team, and unlike removing an entry it cannot throw.
            if (head.mode == WrapperPlayServerTeams.TeamMode.CREATE) reclaimHeldTeams(viewerId, event)
            return
        }

        when (val edit = editTeamPacket(head.teamName, head.mode, members, held)) {
            is TeamPacketEdit.Untouched -> return
            is TeamPacketEdit.Cancel -> event.isCancelled = true
            is TeamPacketEdit.KeepMembers -> rewriteMembers(event, head, edit.members)
        }
    }

    /**
     * Sends the members of our own teams again, after something else may have claimed them.
     *
     * Adding an entry to a team is the one team operation that cannot throw on the client, because it
     * removes the entry from its previous team first. That is what makes this safe to do
     * unconditionally.
     */
    private fun reclaimHeldTeams(viewerId: UUID, event: PacketSendEvent) {
        if (teamManager.heldTeamMemberships(viewerId).isEmpty()) return
        val user = event.user
        event.tasksAfterSend.add {
            // The memberships are read here, not when the create passed. The server thread can recompose this
            // viewer's teams in between, and replaying the earlier layout would put a member back into
            // a team they were just removed from.
            teamManager.heldTeamMemberships(viewerId).forEach { (name, members) ->
                user.sendPacketSilently(teamAddEntitiesPacket(name, members))
            }
        }
    }

    /**
     * Writes [members] over the packet's own entry list, in place.
     *
     * The bytes are rewritten instead of going through a wrapper. The wrapper refuses an entry longer
     * than 40 characters, which vanilla allows, and a packet it cannot read would have to be dropped
     * whole, leaving the client's copy of that team stale. The entry list is the last thing in these
     * packets, so the name and the mode the peek validated stay where they are and everything after
     * them is written again. The list only ever shrinks, so the buffer never has to grow.
     */
    private fun rewriteMembers(event: PacketSendEvent, head: TeamPacketHead, members: List<String>) {
        val buffer = event.byteBuf
        val start = ByteBufHelper.readerIndex(buffer)
        val name = head.teamName.toByteArray(Charsets.UTF_8)
        ByteBufHelper.writerIndex(buffer, start + varIntSize(name.size) + name.size + 1)
        writeVarInt(buffer, members.size)
        for (member in members) {
            val bytes = member.toByteArray(Charsets.UTF_8)
            writeVarInt(buffer, bytes.size)
            ByteBufHelper.writeBytes(buffer, bytes)
        }
        ByteBufHelper.readerIndex(buffer, start)
    }

    /**
     * Runs [block] on the server thread.
     * Packet hooks run on a netty thread, where the Bukkit api is off limits, so anything a hook does
     * that touches the server has to be scheduled rather than run in place.
     */
    fun onServerThread(block: suspend () -> Unit) {
        serverThreadScope.value.launch { block() }
    }
}

/**
 * Reads one varint from a source of bytes, the way the protocol encodes it.
 *
 * Returns null when the bytes run out or when no byte within the first [VAR_INT_MAX_BYTES] ends the
 * number, which is the longest a valid one can be. Kept beside the bridge rather than inside it so
 * the decoding can be tested without a live connection.
 */
internal fun decodeVarInt(nextByte: () -> Byte?): Int? {
    var value = 0
    for (byteIndex in 0 until VAR_INT_MAX_BYTES) {
        val current = nextByte() ?: return null
        value = value or ((current.toInt() and 0x7F) shl (byteIndex * 7))
        if (current.toInt() and 0x80 == 0) return value
    }
    return null
}

/**
 * Reads one length prefixed string from a source of bytes.
 * [maxBytes] is what remains in the packet, which no single string inside it can exceed, so a length
 * read out of a malformed packet cannot request an enormous allocation.
 */
internal fun decodeString(maxBytes: Int, nextByte: () -> Byte?): String? {
    val length = decodeVarInt(nextByte) ?: return null
    if (length < 0 || length > maxBytes) return null
    val bytes = ByteArray(length)
    for (index in 0 until length) bytes[index] = nextByte() ?: return null
    return String(bytes, Charsets.UTF_8)
}

/**
 * The part of a team packet that can be read without decoding the component data a create carries.
 *
 * @property members the entries the packet moves, or null when they sit behind that component data
 * and reaching them would require decoding the packet in full.
 */
internal data class TeamPacketHead(
    val teamName: String,
    val mode: WrapperPlayServerTeams.TeamMode,
    val members: List<String>?,
)

internal fun decodeTeamPacketHead(maxBytes: Int, nextByte: () -> Byte?): TeamPacketHead? {
    val teamName = decodeString(maxBytes, nextByte) ?: return null
    val mode = WrapperPlayServerTeams.TeamMode.entries.getOrNull((nextByte() ?: return null).toInt())
        ?: return null
    if (mode !in ENTRY_LIST_TEAM_MODES) return TeamPacketHead(teamName, mode, null)

    val count = decodeVarInt(nextByte) ?: return null
    // Every entry costs at least its own length byte, so a count past what is left is malformed.
    if (count < 0 || count > maxBytes) return null
    val members = ArrayList<String>()
    repeat(count) { members.add(decodeString(maxBytes, nextByte) ?: return null) }
    return TeamPacketHead(teamName, mode, members)
}

/** The modes whose entry list starts directly after the mode, with nothing in between. */
private val ENTRY_LIST_TEAM_MODES = setOf(
    WrapperPlayServerTeams.TeamMode.ADD_ENTITIES,
    WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES,
)

internal fun varIntSize(value: Int): Int {
    var remaining = value
    var size = 1
    while (remaining and -0x80 != 0) {
        remaining = remaining ushr 7
        size++
    }
    return size
}

private fun writeVarInt(buffer: Any, value: Int) {
    var remaining = value
    while (remaining and -0x80 != 0) {
        ByteBufHelper.writeByte(buffer, (remaining and 0x7F) or 0x80)
        remaining = remaining ushr 7
    }
    ByteBufHelper.writeByte(buffer, remaining)
}

/** The action bits, ADD_PLAYER and UPDATE_DISPLAY_NAME, of the player info packets profile hooks rewrite. */
private const val PROFILE_HOOK_ACTIONS = 0b100001

private const val VAR_INT_MAX_BYTES = 5
