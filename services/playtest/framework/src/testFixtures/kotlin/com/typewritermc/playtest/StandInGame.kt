package com.typewritermc.playtest

import build.skir.JsonFlavor
import skirout.harness.v1.golden.Golden
import skirout.harness.v1.golden.Renderer
import skirout.harness.v1.wire.Answer
import skirout.harness.v1.wire.InputStep
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.Perception
import skirout.harness.v1.wire.ProbeAction
import skirout.harness.v1.wire.Region
import skirout.harness.v1.wire.StateKind
import java.nio.file.Files
import java.nio.file.Path
import java.util.UUID

/**
 * A game standing in for the pool behind one [attempt] of one [player], so a body runs as a pool
 * session runs it, without a pool. Every probe and input runs between ticks, after the last one that
 * ran; a window's ticks run at once, and at the end of each the player perceives [shows]. A query finds
 * the player carrying [marks], and a capture draws [frame] with [renderer]. A quit runs between ticks
 * too; a rejoin lets 5 ticks run first, as a client takes ticks to join, and is back after
 * [rejoinedAfter]. Its goldens, exact for [PINNED], and the attempt's evidence live in a folder of their
 * own. With [restartsPaper] the attempt may ask for a restart, which a stand in game never runs.
 */
internal class StandInGame(
    restartsPaper: Boolean = false,
) : AttemptPool {
    private val folder: Path = Files.createTempDirectory("stand-in-game")
    private var tick = 100
    private var barriers = 0

    /** The last tick the stand in game ran. */
    val ranTo: Int get() = tick

    val player = GamePlayer("gv-1", UUID(0, 1))

    var shows: Perception = Perception.partial()

    var marks: List<StateKind> = listOf()

    var frame = Frame(1, 1, intArrayOf(0x7F7F7F))

    var renderer: Renderer = PINNED

    /** Whether a window asked Paper to step. */
    var stepped = false
        private set

    /** The tick after which the last rejoin brought the player back. */
    var rejoinedAfter = -1
        private set

    override val goldens = Goldens(folder, "goldens", folder.resolve("images"), PinnedRenderer(mesa = "26.2.5"))

    val attempt =
        Attempt(this, SubmissionId(1), listOf(player), Region(x = 0, z = 0), "paper-1", RequirementCode.of(this), restartsPaper)
            .also { it.evidence = Evidence(folder, "stand-in", "attempt-1") }

    /** [frame], as [renderer] draws it now, is the approved golden [name]. */
    fun approve(name: String) {
        val file = folder.resolve(goldens.file(name))
        Files.createDirectories(file.parent)
        val golden = Golden(sha256 = frame.sha256, width = frame.width, height = frame.height, renderer = renderer)
        Files.writeString(file, Golden.serializer.toJsonCode(golden, JsonFlavor.READABLE))
    }

    override fun send(message: Message) {
        val step = (message as? Message.StepUntilWrapper)?.value ?: return
        stepped = true
        while (tick < step.tick) attempt.deliver(Attempt.Event.Perceived(player, shows.copy(tick = ++tick, partial = 1f)))
        attempt.deliver(Attempt.Event.Barrier(player, step.barrier))
    }

    override fun nextBarrier(): Int = ++barriers

    override suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Int = tick

    override suspend fun query(player: GamePlayer): List<StateKind> = marks

    override suspend fun restart(
        attempt: Attempt,
        submission: SubmissionId,
    ): Int = throw UnsupportedOperationException("a stand in game never restarts its Paper")

    override suspend fun quit(player: GamePlayer): Int = tick

    override suspend fun rejoin(player: GamePlayer): Int {
        tick += REJOIN_TICKS
        rejoinedAfter = tick
        return tick
    }

    override suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Int = tick

    override suspend fun capture(
        player: GamePlayer,
        png: Path,
    ): Renderer = renderer.also { frame.writePng(png) }

    override suspend fun startClip(
        player: GamePlayer,
        mp4: Path,
    ): Answer.ClipStarted = throw UnsupportedOperationException("a stand in game records no clip")

    override suspend fun stopClip(player: GamePlayer): Answer.ClipWritten =
        throw UnsupportedOperationException("a stand in game records no clip")

    companion object {
        /** The ticks a stand in client takes to join its Paper again. */
        private const val REJOIN_TICKS = 5

        /** The renderer the stand in game's goldens are exact for. */
        val PINNED =
            Renderer(
                backend = "Vulkan",
                device = "llvmpipe (LLVM 20.1.2, 256 bits)",
                driver = "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)",
                os = "Linux",
                arch = "amd64",
            )
    }
}
