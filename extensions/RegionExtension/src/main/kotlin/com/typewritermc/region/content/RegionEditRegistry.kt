package com.typewritermc.region.content

import com.google.common.collect.Sets
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.Shape
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * A live snapshot of an edit session's working model, published every tick. Nothing in it is
 * authoritative entry state; it is what the editor currently sees.
 */
data class SessionPreview(
    val regionName: String,
    val transform: ResolvedTransform,
    val shape: Shape,
    val color: Color,
    val activity: String,
)

/**
 * One open editor on a region entry: the edit lock (one session per entry), the live
 * [preview] of the working model, and the [spectators] currently watching it.
 */
class RegionEditSession(
    val entryId: String,
    val editorId: UUID,
    val editorName: String,
) {
    @Volatile
    var preview: SessionPreview? = null

    /** The players the spectator renderer currently shows this session to. */
    val spectators: MutableSet<UUID> = Sets.newConcurrentHashSet()
}

/** Which region content mode a player currently has open. */
enum class RegionModeKind {
    Workspace,
    Editor,
    Debug,
}

/**
 * Tracks the open region edit sessions. It is the edit lock (one editor per entry at a
 * time), the source of the live previews the spectator renderer draws for bystanders, and
 * the authority on which players already see a live editor preview of a region, so
 * boundary displays and the visualizer can hide their own rendering for those players.
 *
 * It also tracks which region content mode each player has open. The engine only exposes
 * whether a player is in some content interaction, so the region modes report themselves:
 * the edit command uses it to stop stacking modes, and the barrier audience to leave
 * editing players alone.
 */
@Singleton
class RegionEditRegistry : Initializable {
    private val sessions = ConcurrentHashMap<String, RegionEditSession>()
    private val activeModes = ConcurrentHashMap<UUID, RegionModeKind>()

    override suspend fun initialize() {}

    override suspend fun shutdown() {
        sessions.clear()
        activeModes.clear()
    }

    /**
     * Reports a region content mode as the player's active one. The engine initializes a
     * mode only while it is on top of the stack, so one slot per player is enough.
     */
    fun enterMode(playerId: UUID, kind: RegionModeKind) {
        activeModes[playerId] = kind
    }

    /** Withdraws a mode registration; only [kind] itself, so teardown order cannot misfire. */
    fun exitMode(playerId: UUID, kind: RegionModeKind) {
        activeModes.remove(playerId, kind)
    }

    fun activeMode(playerId: UUID): RegionModeKind? = activeModes[playerId]

    fun inRegionMode(playerId: UUID): Boolean = activeModes.containsKey(playerId)

    /**
     * Claims the edit lock on [entryId] for [playerId]. Returns the session on success,
     * including when the player already holds it, or `null` while another player does.
     */
    fun tryStartEditing(playerId: UUID, playerName: String, entryId: String): RegionEditSession? {
        val session = sessions.computeIfAbsent(entryId) { RegionEditSession(entryId, playerId, playerName) }
        return session.takeIf { it.editorId == playerId }
    }

    /** Releases the edit lock, if [playerId] is the one holding it. */
    fun stopEditing(playerId: UUID, entryId: String) {
        val session = sessions[entryId] ?: return
        if (session.editorId != playerId) return
        sessions.remove(entryId, session)
    }

    fun sessionOf(entryId: String): RegionEditSession? = sessions[entryId]

    fun sessions(): Collection<RegionEditSession> = sessions.values

    fun isEditing(playerId: UUID, entryId: String): Boolean = sessions[entryId]?.editorId == playerId

    /** `true` when [playerId] sees a live preview of [entryId], as its editor or a spectator. */
    fun hasLiveView(playerId: UUID, entryId: String): Boolean {
        val session = sessions[entryId] ?: return false
        return session.editorId == playerId || playerId in session.spectators
    }

    /**
     * `true` when [playerId] already sees a live editor preview covering [region]: their
     * own editor, or another player's session they are spectating. Also checks the entry
     * the consumer itself lives on ([ownerEntryId]), which covers inline definitions.
     */
    fun isSuppressed(playerId: UUID, ownerEntryId: String?, region: RegionData): Boolean {
        if (ownerEntryId != null && hasLiveView(playerId, ownerEntryId)) return true
        val reference = region as? RegionReferenceData ?: return false
        return hasLiveView(playerId, reference.definition.id)
    }
}
