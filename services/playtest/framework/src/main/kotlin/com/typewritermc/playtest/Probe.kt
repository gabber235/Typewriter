package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Kind
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.ProbeCancelBreaking
import com.typewritermc.playtest.wire.Message.ProbeChat
import com.typewritermc.playtest.wire.Message.ProbeCommand
import com.typewritermc.playtest.wire.Message.ProbeFill
import com.typewritermc.playtest.wire.Message.ProbeGameMode
import com.typewritermc.playtest.wire.Message.ProbeGive
import com.typewritermc.playtest.wire.Message.ProbeMark
import com.typewritermc.playtest.wire.Message.ProbePacketEntity
import com.typewritermc.playtest.wire.Message.ProbeSelectSlot
import com.typewritermc.playtest.wire.Message.ProbeSpawn
import com.typewritermc.playtest.wire.Message.ProbeTeleport
import java.util.UUID

/** A player's game mode. */
enum class GameMode { SURVIVAL, CREATIVE, ADVENTURE, SPECTATOR }

/**
 * The framework's Paper probe: arrangements and stimuli that run inside Paper, between ticks. Each call
 * returns once the clients of the players it concerns hold what it caused, so the next stimulus finds it
 * there, and becomes the anchor of the windows after it. Positions count from the middle of the
 * attempt's region. Every attempt finds its players wiped, as players who never played, so a
 * requirement arranges only what it needs beyond that.
 */
class Probe internal constructor(
    private val attempt: Attempt,
    private val anchored: (Mark) -> Unit,
) {
    /** Paper sends [text] to [to] as a chat line. */
    suspend fun chat(
        to: GamePlayer,
        text: String,
    ): Mark = chat(listOf(to), text)

    /** Paper sends [text] to each of [to] as a chat line, all between the same two ticks. */
    suspend fun chat(
        to: List<GamePlayer>,
        text: String,
    ): Mark = run(to, ProbeChat(text))

    /** [player] plays in [mode] from now on. */
    suspend fun gameMode(
        player: GamePlayer,
        mode: GameMode,
    ): Mark = run(listOf(player), ProbeGameMode(mode.name.lowercase()))

    /** [player] stands at [x], [y], [z], looking toward [yaw] (0 is south) and [pitch] (positive is down). */
    suspend fun teleport(
        player: GamePlayer,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        pitch: Float = 0f,
    ): Mark = run(listOf(player), ProbeTeleport(attempt.region.worldX(x), y, attempt.region.worldZ(z), yaw, pitch))

    /** [player]'s inventory [slot] holds [count] of [item]: 0 to 8 is the hotbar, 9 to 35 the rest, 40 the off hand. */
    suspend fun give(
        player: GamePlayer,
        slot: Int,
        item: String,
        count: Int = 1,
    ): Mark = run(listOf(player), ProbeGive(slot, item.id(), count))

    /** [player] holds hotbar [slot], 0 to 8. */
    suspend fun selectSlot(
        player: GamePlayer,
        slot: Int,
    ): Mark = run(listOf(player), ProbeSelectSlot(slot))

    /** Every block from [from] to [to], both included, becomes [block], a block state such as `stone`. */
    suspend fun fill(
        from: BlockPos,
        to: BlockPos,
        block: String,
    ): Mark = run(attempt.players, ProbeFill(attempt.region.world(from), attempt.region.world(to), block.id()))

    /**
     * The block at [at] becomes [block], a block state such as `oak_leaves[persistent=true]`, and every
     * player of the attempt watches it, so `block(ref)` facts can judge it.
     */
    suspend fun block(
        at: BlockPos,
        block: String,
    ): BlockRef {
        fill(at, at, block)
        return BlockRef(at, block.id()).also { attempt.watch(blocks = listOf(it), entities = listOf()) }
    }

    /**
     * An entity of [type] stands still at [x], [y], [z] facing [yaw], and every player of the attempt
     * watches it. When a player hits it, its name tag shows [onHit]; when a player uses it, [onClick].
     */
    suspend fun spawn(
        type: String,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        onHit: String? = null,
        onClick: String? = null,
    ): EntityRef = spawn(attempt.players, type, x, y, z, yaw, packetOnly = false, onHit, onClick)

    /**
     * An entity of [type] that only [player]'s client knows, as Paper never holds it, standing still at
     * [x], [y], [z] facing [yaw]. It reacts like [spawn]'s entity: its name tag shows [onHit] or [onClick].
     */
    suspend fun packetEntity(
        player: GamePlayer,
        type: String,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        onHit: String? = null,
        onClick: String? = null,
    ): EntityRef = spawn(listOf(player), type, x, y, z, yaw, packetOnly = true, onHit, onClick)

    /** Paper cancels every break of [block], as a protection plugin would. */
    suspend fun cancelBreaking(block: BlockRef): Mark = run(attempt.players, ProbeCancelBreaking(attempt.region.world(block.at)))

    /**
     * The command `/name` exists for every player of the attempt and nobody else: its argument suggests
     * each of [suggests] that starts with what is typed, and running it answers with a chat line of
     * [answer], a space and the arguments.
     */
    suspend fun command(
        name: String,
        suggests: List<String>,
        answer: String,
    ): Mark = run(attempt.players, ProbeCommand(name, suggests, answer))

    /**
     * A new entity of [type] for [players], which watch it: one Paper holds, or with [packetOnly] one only
     * their clients know.
     */
    private suspend fun spawn(
        players: List<GamePlayer>,
        type: String,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float,
        packetOnly: Boolean,
        onHit: String?,
        onClick: String?,
    ): EntityRef {
        val entity = EntityRef(UUID.randomUUID(), type.id())
        val (worldX, worldZ) = attempt.region.worldX(x) to attempt.region.worldZ(z)
        val action =
            if (packetOnly) {
                ProbePacketEntity(entity.uuid, entity.type, worldX, y, worldZ, yaw, onHit, onClick)
            } else {
                ProbeSpawn(entity.uuid, entity.type, worldX, y, worldZ, yaw, onHit, onClick)
            }
        run(players, action)
        attempt.watch(blocks = listOf(), entities = listOf(entity))
        return entity
    }

    /** [player] carries a mark of [kind], as an earlier attempt could leave it; for the framework's own test kit. */
    internal suspend fun mark(
        player: GamePlayer,
        kind: Kind,
    ): Mark = run(listOf(player), ProbeMark(kind))

    private suspend fun run(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Mark = attempt.probe(players, action).also(anchored)
}

/** A Minecraft id with its namespace: `stick` is `minecraft:stick`. */
internal fun String.id(): String = if (':' in substringBefore('[')) this else "minecraft:$this"
