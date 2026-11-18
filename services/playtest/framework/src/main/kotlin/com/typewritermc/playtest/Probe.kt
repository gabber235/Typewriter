package com.typewritermc.playtest

import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.PlayerAction
import skirout.harness.v1.wire.ProbeAction
import skirout.harness.v1.wire.StateKind
import skirout.harness.v1.wire.WorldAction
import java.util.UUID

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
    ): Mark = run(to, PlayerAction.createChat(text = text))

    /** [player] plays in [mode] from now on. */
    suspend fun gameMode(
        player: GamePlayer,
        mode: GameMode,
    ): Mark = run(listOf(player), PlayerAction.GameModeWrapper(mode))

    /** [player] sees a sidebar titled [title] holding [lines], top to bottom, each line once. */
    suspend fun sidebar(
        player: GamePlayer,
        title: String,
        lines: List<String>,
    ): Mark = run(listOf(player), PlayerAction.createSidebar(title = title, lines = lines))

    /** [player] sees the time of day stand still at [time] ticks: 0 is sunrise, 6000 noon, 18000 midnight. */
    suspend fun time(
        player: GamePlayer,
        time: Long,
    ): Mark = run(listOf(player), PlayerAction.createTime(time = time))

    /** [player] stands at [x], [y], [z], looking toward [yaw] (0 is south) and [pitch] (positive is down). */
    suspend fun teleport(
        player: GamePlayer,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        pitch: Float = 0f,
    ): Mark =
        run(
            listOf(player),
            PlayerAction.createTeleport(x = attempt.region.worldX(x), y = y, z = attempt.region.worldZ(z), yaw = yaw, pitch = pitch),
        )

    /** [player]'s inventory [slot] holds [count] of [item]: 0 to 8 is the hotbar, 9 to 35 the rest, 40 the off hand. */
    suspend fun give(
        player: GamePlayer,
        slot: Int,
        item: String,
        count: Int = 1,
    ): Mark = run(listOf(player), PlayerAction.createGive(slot = slot, item = item.id(), count = count))

    /** Paper writes [player]'s data to disk now, as it does when the player quits or the world saves. */
    suspend fun save(player: GamePlayer): Mark = run(listOf(player), PlayerAction.SAVE)

    /** [player] holds hotbar [slot], 0 to 8. */
    suspend fun selectSlot(
        player: GamePlayer,
        slot: Int,
    ): Mark = run(listOf(player), PlayerAction.createSelectSlot(slot = slot))

    /** Every block from [from] to [to], both included, becomes [block], a block state such as `stone`. */
    suspend fun fill(
        from: BlockPos,
        to: BlockPos,
        block: String,
    ): Mark =
        run(attempt.players, WorldAction.createFill(from = attempt.region.world(from), to = attempt.region.world(to), block = block.id()))

    /**
     * The block at [at] becomes [block], a block state such as `oak_leaves[persistent=true]`, and every
     * player of the attempt watches it, so `block(ref)` facts can judge it.
     */
    suspend fun block(
        at: BlockPos,
        block: String,
    ): BlockRef {
        run(attempt.players, WorldAction.createBlock(at = attempt.region.world(at), block = block.id()))
        return BlockRef(at, block.id())
    }

    /**
     * An entity of [type] stands still at [x], [y], [z] facing [yaw], [invisible] as the invisibility
     * effect makes it, and every player of the attempt watches it. When a player hits it, its name tag
     * shows [onHit]; when a player uses it, [onClick].
     */
    suspend fun spawn(
        type: String,
        x: Double,
        y: Double,
        z: Double,
        yaw: Float = 0f,
        invisible: Boolean = false,
        onHit: String? = null,
        onClick: String? = null,
    ): EntityRef = spawn(attempt.players, type, x, y, z, yaw, packetOnly = false, invisible, onHit, onClick)

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
    ): EntityRef = spawn(listOf(player), type, x, y, z, yaw, packetOnly = true, invisible = false, onHit, onClick)

    /** Paper cancels every break of [block], as a protection plugin would. */
    suspend fun cancelBreaking(block: BlockRef): Mark =
        run(attempt.players, WorldAction.createCancelBreaking(at = attempt.region.world(block.at)))

    /**
     * The command `/name` exists for every player of the attempt and nobody else: its argument suggests
     * each of [suggests] that starts with what is typed, and running it answers with a chat line of
     * [answer], a space and the arguments.
     */
    suspend fun command(
        name: String,
        suggests: List<String>,
        answer: String,
    ): Mark = run(attempt.players, PlayerAction.createCommand(name = name, suggestions = suggests, answer = answer))

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
        invisible: Boolean,
        onHit: String?,
        onClick: String?,
    ): EntityRef {
        val entity = EntityRef(UUID.randomUUID(), type.id())
        val (worldX, worldZ) = attempt.region.worldX(x) to attempt.region.worldZ(z)
        val uuid = entity.uuid.toString()
        if (packetOnly) {
            run(
                players,
                PlayerAction.createPacketEntity(
                    uuid = uuid,
                    entityType = entity.type,
                    x = worldX,
                    y = y,
                    z = worldZ,
                    yaw = yaw,
                    onHit = onHit,
                    onClick = onClick,
                ),
            )
        } else {
            run(
                players,
                WorldAction.createSpawn(
                    uuid = uuid,
                    entityType = entity.type,
                    x = worldX,
                    y = y,
                    z = worldZ,
                    yaw = yaw,
                    invisible = invisible,
                    onHit = onHit,
                    onClick = onClick,
                ),
            )
        }
        return entity
    }

    /** [player] carries a mark of [kind], as an earlier attempt could leave it; for the framework's own test kit. */
    internal suspend fun mark(
        player: GamePlayer,
        kind: StateKind,
    ): Mark = run(listOf(player), PlayerAction.createMark(kind = kind))

    /**
     * [player]'s work [name] runs off Paper's main thread for [millis] of wall clock, counted as a
     * plugin counts its work, then sends [chat] as a chat line; for the framework's own test kit.
     */
    internal suspend fun work(
        player: GamePlayer,
        name: String,
        millis: Int,
        chat: String,
    ): Mark = run(listOf(player), PlayerAction.createWork(name = name, millis = millis, chat = chat))

    private suspend fun run(
        players: List<GamePlayer>,
        action: PlayerAction,
    ): Mark = run(players, ProbeAction.OnPlayerWrapper(action))

    private suspend fun run(
        players: List<GamePlayer>,
        action: WorldAction,
    ): Mark = run(players, ProbeAction.OnWorldWrapper(action))

    private suspend fun run(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Mark = attempt.probe(players, action).also(anchored)
}

/** A Minecraft id with its namespace: `stick` is `minecraft:stick`. */
internal fun String.id(): String = if (':' in substringBefore('[')) this else "minecraft:$this"
