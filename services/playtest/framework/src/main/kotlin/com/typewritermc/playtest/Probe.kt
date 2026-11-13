package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.ProbeCancelBreaking
import com.typewritermc.playtest.wire.Message.ProbeChat
import com.typewritermc.playtest.wire.Message.ProbeCommand
import com.typewritermc.playtest.wire.Message.ProbeFill
import com.typewritermc.playtest.wire.Message.ProbeGameMode
import com.typewritermc.playtest.wire.Message.ProbeGive
import com.typewritermc.playtest.wire.Message.ProbeSelectSlot
import com.typewritermc.playtest.wire.Message.ProbeSpawn
import com.typewritermc.playtest.wire.Message.ProbeTeleport
import java.util.UUID
import com.typewritermc.playtest.wire.Message.BlockPos as WireBlockPos

/** A player's game mode. */
enum class GameMode { SURVIVAL, CREATIVE, ADVENTURE, SPECTATOR }

/**
 * The framework's Paper probe: arrangements and stimuli that run inside Paper, between ticks. Each call
 * becomes the anchor of the windows after it. Until the attempt's wipe exists, a requirement arranges
 * everything it relies on, since earlier attempts leave their arrangements behind.
 */
class Probe internal constructor(
    private val attempt: Attempt,
    private val anchored: (Mark) -> Unit,
) {
    /** Paper sends [text] to [to] as a chat line. */
    suspend fun chat(
        to: GamePlayer,
        text: String,
    ): Mark = run(to, ProbeChat(text))

    /** [player] plays in [mode] from now on. */
    suspend fun gameMode(
        player: GamePlayer,
        mode: GameMode,
    ): Mark = run(player, ProbeGameMode(mode.name.lowercase()))

    /** [player] stands at [x], [y], [z], looking toward [yaw] (0 is south) and [pitch] (positive is down). */
    suspend fun teleport(
        player: GamePlayer,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        pitch: Float = 0f,
    ): Mark = run(player, ProbeTeleport(x, y, z, yaw, pitch))

    /** [player]'s inventory [slot] holds [count] of [item]: 0 to 8 is the hotbar, 9 to 35 the rest, 40 the off hand. */
    suspend fun give(
        player: GamePlayer,
        slot: Int,
        item: String,
        count: Int = 1,
    ): Mark = run(player, ProbeGive(slot, item.id(), count))

    /** [player] holds hotbar [slot], 0 to 8. */
    suspend fun selectSlot(
        player: GamePlayer,
        slot: Int,
    ): Mark = run(player, ProbeSelectSlot(slot))

    /** Every block from [from] to [to], both included, becomes [block], a block state such as `stone`. */
    suspend fun fill(
        from: BlockPos,
        to: BlockPos,
        block: String,
    ): Mark = run(attempt.players.first(), ProbeFill(from.wire(), to.wire(), block.id()))

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
    ): EntityRef = spawn(attempt.players.first(), type, x, y, z, yaw, packetOnly = false, onHit, onClick)

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
    ): EntityRef = spawn(player, type, x, y, z, yaw, packetOnly = true, onHit, onClick)

    /** Paper cancels every break of [block], as a protection plugin would. */
    suspend fun cancelBreaking(block: BlockRef): Mark = run(attempt.players.first(), ProbeCancelBreaking(block.at.wire()))

    /**
     * The command `/name` exists: its argument suggests each of [suggests] that starts with what is
     * typed, and running it answers with a chat line of [answer], a space and the arguments.
     */
    suspend fun command(
        name: String,
        suggests: List<String>,
        answer: String,
    ): Mark = run(attempt.players.first(), ProbeCommand(name, suggests, answer))

    private suspend fun spawn(
        player: GamePlayer,
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
        run(player, ProbeSpawn(entity.uuid, entity.type, x, y, z, yaw, packetOnly, onHit, onClick))
        attempt.watch(blocks = listOf(), entities = listOf(entity))
        return entity
    }

    private suspend fun run(
        player: GamePlayer,
        action: ProbeAction,
    ): Mark = attempt.probe(player, action).also(anchored)
}

/** A Minecraft id with its namespace: `stick` is `minecraft:stick`. */
internal fun String.id(): String = if (':' in substringBefore('[')) this else "minecraft:$this"

internal fun BlockPos.wire() = WireBlockPos(x, y, z)
