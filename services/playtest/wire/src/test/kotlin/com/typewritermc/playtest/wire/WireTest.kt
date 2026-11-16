package com.typewritermc.playtest.wire

import com.typewritermc.playtest.wire.Message.AimAtBlockStep
import com.typewritermc.playtest.wire.Message.AimAtEntityStep
import com.typewritermc.playtest.wire.Message.AttemptPolicy
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Block
import com.typewritermc.playtest.wire.Message.BlockPos
import com.typewritermc.playtest.wire.Message.ButtonStep
import com.typewritermc.playtest.wire.Message.Camera
import com.typewritermc.playtest.wire.Message.Capture
import com.typewritermc.playtest.wire.Message.Captured
import com.typewritermc.playtest.wire.Message.ChatLine
import com.typewritermc.playtest.wire.Message.Claim
import com.typewritermc.playtest.wire.Message.Claimed
import com.typewritermc.playtest.wire.Message.ClientLost
import com.typewritermc.playtest.wire.Message.ClientStalled
import com.typewritermc.playtest.wire.Message.ClipStarted
import com.typewritermc.playtest.wire.Message.ClipWritten
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.Covered
import com.typewritermc.playtest.wire.Message.CoveredClass
import com.typewritermc.playtest.wire.Message.Declined
import com.typewritermc.playtest.wire.Message.Demonstrates
import com.typewritermc.playtest.wire.Message.Disconnected
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Entity
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.HungEnded
import com.typewritermc.playtest.wire.Message.Input
import com.typewritermc.playtest.wire.Message.InputDone
import com.typewritermc.playtest.wire.Message.Item
import com.typewritermc.playtest.wire.Message.Joined
import com.typewritermc.playtest.wire.Message.Key
import com.typewritermc.playtest.wire.Message.KeyStep
import com.typewritermc.playtest.wire.Message.Kind
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.LeaseFailed
import com.typewritermc.playtest.wire.Message.Marks
import com.typewritermc.playtest.wire.Message.PaperLost
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.PlayerLeft
import com.typewritermc.playtest.wire.Message.PointAtSlotStep
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeBlock
import com.typewritermc.playtest.wire.Message.ProbeCancelBreaking
import com.typewritermc.playtest.wire.Message.ProbeChat
import com.typewritermc.playtest.wire.Message.ProbeCommand
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.ProbeFill
import com.typewritermc.playtest.wire.Message.ProbeGameMode
import com.typewritermc.playtest.wire.Message.ProbeGive
import com.typewritermc.playtest.wire.Message.ProbeMark
import com.typewritermc.playtest.wire.Message.ProbePacketEntity
import com.typewritermc.playtest.wire.Message.ProbeSave
import com.typewritermc.playtest.wire.Message.ProbeSelectSlot
import com.typewritermc.playtest.wire.Message.ProbeSidebar
import com.typewritermc.playtest.wire.Message.ProbeSpawn
import com.typewritermc.playtest.wire.Message.ProbeTeleport
import com.typewritermc.playtest.wire.Message.ProbeTime
import com.typewritermc.playtest.wire.Message.ProbeWork
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Queue
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.RegionsAhead
import com.typewritermc.playtest.wire.Message.Release
import com.typewritermc.playtest.wire.Message.Renderer
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Restart
import com.typewritermc.playtest.wire.Message.Restarted
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Resume
import com.typewritermc.playtest.wire.Message.Resumed
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.ScrollStep
import com.typewritermc.playtest.wire.Message.Settle
import com.typewritermc.playtest.wire.Message.Settled
import com.typewritermc.playtest.wire.Message.StartClip
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.Stepping
import com.typewritermc.playtest.wire.Message.StopClip
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Message.Text
import com.typewritermc.playtest.wire.Message.TypeInChatStep
import com.typewritermc.playtest.wire.Message.WaitStep
import com.typewritermc.playtest.wire.Message.WalkToStep
import com.typewritermc.playtest.wire.Message.WorkHung
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.property.Arb
import io.kotest.property.PropTestConfig
import io.kotest.property.arbitrary.codepoints
import io.kotest.property.arbitrary.filterNot
import io.kotest.property.arbitrary.int
import io.kotest.property.arbitrary.list
import io.kotest.property.arbitrary.string
import io.kotest.property.checkAll
import java.util.UUID

val WireTest by testSuite {
    val player = UUID.fromString("5b3a7f43-37a8-3e9a-8f0e-61c1d7c3a1b2")

    test("every message reads back as the message that was written") {
        val messages =
            listOf<Message>(
                Hello(Role.CLIENT, "gv-1"),
                Refused("Paper stopped while starting; see pool/paper/logs/latest.log"),
                Queue(
                    listOf(
                        Submit(
                            7,
                            "PROBE-1 a chat line the probe sends reaches the player",
                            "PROBE-1",
                            1,
                            Demonstrates.HAPPY_PATH,
                            false,
                            false,
                        ),
                    ),
                ),
                Queue(
                    listOf(
                        Submit(
                            8,
                            "LOST-1 a client that crashes fails its own attempt (attempt 1 of 3)",
                            "LOST-1",
                            1,
                            Demonstrates.FAILURE,
                            false,
                            false,
                        ),
                        Submit(
                            9,
                            "LOST-1 a client that crashes fails its own attempt (attempt 2 of 3)",
                            "LOST-1",
                            1,
                            Demonstrates.EDGE_CASE,
                            false,
                            true,
                        ),
                    ),
                ),
                Queue(
                    listOf(
                        Submit(10, "RESTART-1 a saved item survives a killed Paper", "RESTART-1", 1, Demonstrates.HAPPY_PATH, true, false),
                    ),
                ),
                Declined(8, "GROUP-1 claims 3 players, but the pool holds 1"),
                LeaseFailed(10, "paper-gv-1 exited with code 1 while it booted; see pool/paper-gv-1-lost-1/console.log"),
                Restart(18, 10),
                Restarted(18, 41),
                PaperLost("gv-1", "paper-gv-1 exited with code 137 while it booted; see pool/paper-gv-1-lost-1/console.log"),
                Resume(11, listOf(player, UUID(1, 2))),
                Resumed(11, 41, null),
                Resumed(12, 7, "the player gv-2 is not online"),
                Disconnected(25_566, "its connection to the Paper at 127.0.0.1:25566 dropped"),
                Reclaim(8),
                Lease(7, listOf(Player("gv-1", player), Player("gv-2", UUID(1, 2))), Region(-1_024, 2_048), "paper-a7"),
                Result(7, 1_250, null, null, listOf(), "", listOf(), listOf()),
                Result(
                    8,
                    90,
                    "gv-1 did not see chat \"Hello\"",
                    "ProbeRequirements.kt:14",
                    listOf(
                        AttemptStep(1_700_000_000_000, 12, "probe Chat[text=Hello]"),
                        AttemptStep(1_700_000_000_012, 70, "window of 5 ticks missed at tick 5, stepped 5"),
                    ),
                    "GOLDEN-1 a sidebar/attempt-1",
                    listOf("sidebar.png", "sidebar.diff.png"),
                    listOf("clips/gv-1.mp4"),
                ),
                End("run-1", "/tmp/results/test_run.json", AttemptPolicy(AttemptPolicy.Kind.RERUN_FAILURES, 4)),
                End("run-2", "/tmp/results/test_run.json", AttemptPolicy(AttemptPolicy.Kind.EXACTLY, 3)),
                Ended(),
                Probe(3, listOf(player, UUID(1, 2)), ProbeChat("Hello")),
                Probe(4, listOf(player), ProbeGameMode("survival")),
                Probe(5, listOf(player), ProbeTeleport(16.5, 100.0, -3.5, 180f, -12.5f)),
                Probe(6, listOf(player), ProbeGive(40, "minecraft:spyglass", 1)),
                Probe(7, listOf(player), ProbeSelectSlot(8)),
                Probe(8, listOf(player), ProbeFill(BlockPos(-2, 99, -2), BlockPos(2, 99, 6), "minecraft:oak_leaves[persistent=true]")),
                Probe(9, listOf(player), ProbePacketEntity(UUID(3, 4), "minecraft:villager", 0.5, 100.0, 3.5, 180f, "Ouch", null)),
                Probe(10, listOf(player), ProbeSpawn(UUID(5, 6), "minecraft:pig", 0.5, 100.0, 3.5, 0f, true, null, "Oink")),
                Probe(11, listOf(player), ProbeCancelBreaking(BlockPos(0, 101, 2))),
                Probe(11, listOf(player), ProbeBlock(BlockPos(0, 101, 2), "minecraft:oak_leaves[persistent=true]")),
                Probe(12, listOf(player), ProbeCommand("warp", listOf("spawn", "spire", "shop"), "Warping to")),
                Probe(13, listOf(player), ProbeMark(Kind.HOLD)),
                Probe(14, listOf(player), ProbeWork("Ledger lookup", 120, "Ledger ready")),
                Probe(15, listOf(player), ProbeSidebar("Quest", listOf("Find the key", "Gold: 3"))),
                Probe(16, listOf(player), ProbeTime(6_000)),
                Probe(17, listOf(player), ProbeSave()),
                Query(14, player),
                Marks(14, listOf(Kind.SCOREBOARD, Kind.HOLD), null),
                Marks(15, listOf(), "the player gv-2 is not online"),
                ProbeDone(3, 1_204, null),
                ProbeDone(4, 1_205, "no item minecraft:spyglas"),
                Claim(9, listOf(player, UUID(1, 2)), Region(1_024, -1_024)),
                Claimed(9, null),
                Claimed(10, "the player gv-2 is not online"),
                Release(9),
                RegionsAhead(listOf(Region(-1_024, -1_024), Region(-1_024, 0))),
                Settle(9),
                Settled(9, listOf()),
                Settled(
                    10,
                    listOf(
                        CoveredClass(
                            "com/typewritermc/playtest/plugin/Probes",
                            "com/typewritermc/playtest/plugin/Probes.java",
                            listOf(12, 13, 40),
                        ),
                    ),
                ),
                Covered(listOf(9L, 10L), 41_250, byteArrayOf(1, -64, 0, 7)),
                Covered(listOf(), 0, byteArrayOf()),
                WorkHung("gv-1", "Ledger lookup", 1_204),
                PlayerLeft("gv-2", "TIMED_OUT"),
                ClientLost("gv-2", "its process exited with code 137"),
                ClientStalled("gv-3", 2_048),
                HungEnded("gv-1", "Ledger lookup"),
                StepUntil(player, 1_214, 5),
                StopStepping(player),
                Stepping(),
                Connect("127.0.0.1", 25_565),
                Joined(),
                Ready(),
                Reset(),
                ResetDone(),
                Input(
                    13,
                    player,
                    listOf(
                        KeyStep(Key.LEFT_SHIFT, true),
                        WaitStep(4),
                        KeyStep(Key.LEFT_SHIFT, false),
                        ButtonStep(3, true),
                        ScrollStep(-1),
                        TypeInChatStep("/warp s"),
                        AimAtEntityStep(UUID(3, 4)),
                        AimAtBlockStep(BlockPos(0, 101, 2)),
                        PointAtSlotStep(9),
                        WalkToStep(0.5, 4.5, 80),
                    ),
                ),
                InputDone(13, 1_220, null),
                InputDone(14, 1_221, "gv-1 aimed at the villager, but the crosshair is on the block at 0 101 2"),
                StartClip(19, player, "/tmp/results/CLIP-1/demo/clips/gv-1.mp4"),
                ClipStarted(19, null),
                ClipStarted(20, "ffmpeg is not on the PATH"),
                StopClip(21, player),
                ClipWritten(21, 93, null),
                ClipWritten(22, 0, "ffmpeg exited with code 1"),
                Capture(17, player, "/tmp/results/GOLDEN-1/attempt-1/sidebar.png"),
                Captured(
                    17,
                    Renderer("Vulkan", "llvmpipe (LLVM 20.1.2, 256 bits)", "1.4.318 llvmpipe Mesa 26.2.5 (LLVM 20.1.2)", "Linux", "amd64"),
                    null,
                ),
                Captured(18, Renderer("OpenGL", "Apple M1 Max", "4.1 Metal", "Mac OS X", "aarch64"), "the frame could not be written"),
                Perceived(
                    "gv-1",
                    Perception(
                        1_205,
                        2f / 3,
                        17,
                        listOf(Text("chat", "Hello"), Text("other", "")),
                        listOf(ChatLine(1_205, "Hello")),
                        Camera(0.5, 101.62, 0.5, 180f, 12.25f, 70f, false),
                        listOf(Item("hotbar", 0, true, "minecraft:spyglass", 1), Item("carried", -1, false, "minecraft:stick", 64)),
                        listOf(
                            Block(BlockPos(0, 101, 2), "minecraft:air", true, 1_204),
                            Block(BlockPos(1, 101, 2), "minecraft:stone", false, -1),
                        ),
                        listOf(Entity(UUID(3, 4), true, "Ouch", 0.000_732), Entity(UUID(5, 6), false, null, Entity.UNMEASURED)),
                    ),
                ),
                Perceived("gv-1", Perception(0, 1f, -1, listOf(), listOf(), null, listOf(), listOf(), listOf())),
                BarrierSeen("gv-1", 5),
            )

        framed(*messages.toTypedArray()).readFrames() shouldBe messages
    }

    test("text in any script and of any length reads back unchanged") {
        val text = Arb.string(0..2_000, Arb.codepoints().filterNot { it.value in Char.MIN_SURROGATE.code..Char.MAX_SURROGATE.code })
        checkAll(PropTestConfig(seed = 2_611_131_947L, iterations = 200), Arb.list(text, 0..5), Arb.int(0..1_000_000)) { texts, tick ->
            val perceived =
                Perceived("gv-1", perception(tick, texts = texts.map { Text("chat", it) }, chat = texts.map { ChatLine(tick, it) }))

            framed(perceived).readFrames() shouldBe listOf(perceived)
        }
    }

    test("a text longer than 64 KB reads back unchanged") {
        val perceived = Perceived("gv-1", perception(1, texts = listOf(Text("chat", "é".repeat(40_000)))))

        framed(perceived).readFrames() shouldBe listOf(perceived)
    }

    test("a frame longer than the limit is refused before its body is read") {
        val failure = shouldThrow<WireException> { handFrame(type = 0, body = byteArrayOf(), length = Wire.MAX_FRAME + 1).readFrames() }

        failure.message shouldContain "${Wire.MAX_FRAME + 1} bytes"
    }

    test("a frame without even a type byte is refused") {
        shouldThrow<WireException> { handFrame(type = 0, body = byteArrayOf(), length = 0).readFrames() }
    }

    test("an unknown type is refused and named") {
        val failure = shouldThrow<WireException> { handFrame(type = 99, body = byteArrayOf()).readFrames() }

        failure.message shouldContain "type 99"
    }

    test("a body longer than its message is refused") {
        val ready = framed(Ready())
        val padded = handFrame(type = ready[4].toInt(), body = byteArrayOf(1, 2, 3))

        val failure = shouldThrow<WireException> { padded.readFrames() }

        failure.message shouldContain "3 bytes"
    }

    test("a stream that ends inside a frame is refused as cut off") {
        val whole = framed(Perceived("gv-1", perception(4, texts = listOf(Text("chat", "Hello")), chat = listOf(ChatLine(4, "Hello")))))

        shouldThrow<WireException> { whole.copyOf(whole.size - 2).readFrames() }
        shouldThrow<WireException> { whole.copyOf(2).readFrames() }
    }

    test("a stream that ends between frames is the end of the messages") {
        framed(Ready(), Reset()).readFrames() shouldBe listOf(Ready(), Reset())
        byteArrayOf().readFrames() shouldBe listOf()
    }
}
