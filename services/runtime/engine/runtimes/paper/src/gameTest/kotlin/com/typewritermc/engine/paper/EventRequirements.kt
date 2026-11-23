package com.typewritermc.engine.paper

import com.typewritermc.engine.events.cancelableEventEntry
import com.typewritermc.engine.events.eventEntry
import com.typewritermc.engine.pages.definition
import com.typewritermc.engine.pages.sequencePage
import com.typewritermc.engine.pages.staticPage
import com.typewritermc.extensions.basic.entries.sequence.actions.simpleMessageActionEntry
import com.typewritermc.extensions.basic.entries.sequence.events.intervalEventEntry
import com.typewritermc.extensions.basic.events.BlockBreak
import com.typewritermc.extensions.basic.events.BlockBreakDefinition
import com.typewritermc.extensions.basic.events.PlayerChat
import com.typewritermc.extensions.basic.events.PlayerChatDefinition
import com.typewritermc.extensions.basic.events.PlayerJoin
import com.typewritermc.extensions.basic.events.PlayerJoinDefinition
import com.typewritermc.formula.Formula
import com.typewritermc.formula.Var
import com.typewritermc.library.library
import com.typewritermc.playtest.BlockPos
import com.typewritermc.playtest.Button
import com.typewritermc.playtest.GameCompartment
import com.typewritermc.playtest.block
import com.typewritermc.playtest.chat
import com.typewritermc.playtest.requirement
import com.typewritermc.playtest.ticks
import com.typewritermc.realm.testing.boundFormula
import com.typewritermc.types.integerScalar
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.aroundAll
import de.infix.testBalloon.framework.core.testSuite
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.harness.v1.wire.GameMode
import skirout.harness.v1.wire.KeyboardKey
import kotlin.time.Duration.Companion.minutes

val EventRequirements by testSuite(
    compartment = { GameCompartment },
    testConfig =
        TestConfig.aroundAll { requirements ->
            StackObserver.fromEnvironment().use { it.awaitActive("game_paper_0", 3.minutes) }
            requirements()
        },
) {
    requirement(
        "GAME-E1",
        "a player who joins sees the message a join trigger's linked action sends",
        content =
            listOf(
                content("e1-join-reward") { copy ->
                    library {
                        books.attemptBook(copy) {
                            val total =
                                pages.staticPage("values") {
                                    elements.definition<Int>("total", integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use) {
                                        name = "total"
                                        value = Var.Value(3)
                                    }
                                }
                            pages.sequencePage("join") {
                                val reward =
                                    elements.simpleMessageActionEntry("reward") {
                                        name = "reward"
                                        triggers = emptySet()
                                        message = Var.Computed(boundFormula("\"Reward: \${total}\"", mapOf("total" to total.id.toSkir())))
                                    }
                                elements.eventEntry<PlayerJoin>("joined", PlayerJoinDefinition.id.use()) {
                                    name = "joined"
                                    triggers = setOf(reward)
                                }
                            }
                        }
                    }
                },
            ),
    ) {
        player.quit()
        player.rejoin()
        within(20.ticks) { player sees chat("Reward: 3") }
    }

    requirement(
        "GAME-E2",
        "a block whose break a cancelable event entry cancels stays, and the entry's linked message shows",
        content =
            listOf(
                content("e2-kept-block") { copy ->
                    library {
                        books.attemptBook(copy) {
                            pages.sequencePage("break") {
                                val kept =
                                    elements.simpleMessageActionEntry("kept") {
                                        name = "kept"
                                        triggers = emptySet()
                                        message = Var.Value("This block stays")
                                    }
                                elements.cancelableEventEntry<BlockBreak>("guard", BlockBreakDefinition.id.use()) {
                                    name = "guard"
                                    triggers = setOf(kept)
                                    cancel = Var.Value(true)
                                }
                            }
                        }
                    }
                },
            ),
    ) {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        val leaves = probe.block(BlockPos(0, 101, 2), "oak_leaves[persistent=true]")

        player.aimAt(leaves)
        player.hold(Button.LEFT, 20.ticks)

        within(30.ticks) {
            player sees chat("This block stays")
            player sees block(leaves).becomes("oak_leaves")
        }
    }

    requirement(
        "GAME-E3",
        "publishing a cancelable event entry that no longer cancels lets the block break, without a restart, and its message still shows",
        content =
            listOf(
                content("e3-released-block") { copy ->
                    library {
                        books.attemptBook(copy) {
                            pages.sequencePage("break") {
                                val noticed =
                                    elements.simpleMessageActionEntry("noticed") {
                                        name = "noticed"
                                        triggers = emptySet()
                                        message = Var.Value("A break was noticed")
                                    }
                                elements.cancelableEventEntry<BlockBreak>("guard", BlockBreakDefinition.id.use()) {
                                    name = "guard"
                                    triggers = setOf(noticed)
                                    cancel = Var.Value(!copy.changed)
                                }
                            }
                        }
                    }
                },
            ),
    ) {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.SURVIVAL)
        val leaves = probe.block(BlockPos(0, 101, 2), "oak_leaves[persistent=true]")
        player.aimAt(leaves)
        player.hold(Button.LEFT, 20.ticks)
        within(30.ticks) {
            player sees chat("A break was noticed")
            player sees block(leaves).becomes("oak_leaves")
        }

        content.single().change()

        player.hold(Button.LEFT, 20.ticks)
        within(30.ticks) {
            player sees chat("A break was noticed")
            player sees block(leaves).gone()
        }
    }

    requirement(
        "GAME-E4",
        "a chat event entry whose condition reads the message sends its linked message only on a matching line",
        content =
            listOf(
                content("e4-heard-hello") { copy ->
                    library {
                        books.attemptBook(copy) {
                            pages.sequencePage("chat") {
                                val heard =
                                    elements.simpleMessageActionEntry("heard") {
                                        name = "heard"
                                        triggers = emptySet()
                                        message = Var.Value("Hello to you too")
                                    }
                                elements.eventEntry<PlayerChat>("greeting", PlayerChatDefinition.id.use()) {
                                    name = "greeting"
                                    triggers = setOf(heard)
                                    condition = Var.Computed(Formula("event.message.contains(\"hello\")"))
                                }
                            }
                        }
                    }
                },
            ),
    ) {
        probe.fill(BlockPos(-2, 99, -2), BlockPos(2, 99, 8), "stone")
        probe.teleport(player, 0.5, 100.0, 0.5)
        probe.gameMode(player, GameMode.CREATIVE)

        player.typeInChat("bye")
        player.press(KeyboardKey.ENTER)
        within(20.ticks) {
            player sees chat("<${player.name}> bye")
            player.never sees chat("Hello to you too")
        }

        player.typeInChat("hello there")
        player.press(KeyboardKey.ENTER)
        within(20.ticks) { player sees chat("Hello to you too") }
    }

    requirement(
        "GAME-E5",
        "an interval entry's linked message repeats about every 20 ticks while the entry is published, and stops once it is removed, without a restart",
        content =
            listOf(
                content("e5-interval-beat") { copy ->
                    library {
                        books.attemptBook(copy) {
                            pages.sequencePage("ticks") {
                                val beat =
                                    elements.simpleMessageActionEntry("beat") {
                                        name = "beat"
                                        triggers = emptySet()
                                        message = Var.Value("Interval beat")
                                    }
                                elements.intervalEventEntry("every") {
                                    name = "every"
                                    triggers = setOf(beat)
                                    interval = 20
                                }
                            }
                        }
                    }
                },
            ),
    ) {
        probe.chat(player, "Waiting for the interval")
        within(25.ticks) {
            player sees chat("Waiting for the interval")
            player sees chat("Interval beat")
        }

        // A beat reaches chat through its chain, so one can arrive a few ticks late: the cadence is counted, not timed.
        probe.chat(player, "Counting beats")
        within(70.ticks) {
            player sees chat("Counting beats")
            player sees chat("Interval beat", times = 2)
            player.never sees chat("Interval beat", times = 5)
        }

        content.single().remove()
        probe.chat(player, "The interval is gone")
        within(80.ticks) {
            player sees chat("The interval is gone")
            // One beat may already be on its way when the entry goes.
            player.never sees chat("Interval beat", times = 2)
        }
    }
}
