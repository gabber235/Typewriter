package com.typewritermc.playtest

import com.typewritermc.playtest.Window.Verdict.Missed
import com.typewritermc.playtest.Window.Verdict.Open
import com.typewritermc.playtest.Window.Verdict.Passed
import com.typewritermc.playtest.wire.camera
import com.typewritermc.playtest.wire.chatLine
import com.typewritermc.playtest.wire.drawnEntity
import com.typewritermc.playtest.wire.item
import com.typewritermc.playtest.wire.perception
import com.typewritermc.playtest.wire.text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import java.util.UUID

val WindowTest by testSuite {
    val steve = GamePlayer("gv-1", UUID(0, 1))
    val alex = GamePlayer("gv-2", UUID(0, 2))
    val steveSeesBank = Check(steve, chat("Bank: 1"))
    val alexHearsNothing = Check(alex, anyChat())
    val bankArrived = perception(102).copy(texts = listOf(text("chat", "Bank: 1")), chat = listOf(chatLine(102, "Bank: 1")))

    test("a chat line that arrives after the stimulus and is drawn passes at the tick it shows") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(101)) shouldBe Open
        window.perceived(steve, perception(103).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(103, "Hello")))) shouldBe
            Passed(103)
    }

    test("a frame a clip draws between two ticks judges nothing: a fact holds from the tick whose end shows it") {
        val window =
            Window(
                anchor = 100,
                length = 10.ticks,
                barrier = 1,
                checks = listOf(Check(steve, chat("Hello"))),
                nevers = listOf(alexHearsNothing),
            )
        val hello = listOf(text("chat", "Hello"))

        window.perceived(
            steve,
            perception(103, partial = 2f / 3, frame = 4).copy(texts = hello, chat = listOf(chatLine(103, "Hello"))),
        ) shouldBe
            Open
        window.perceived(alex, perception(104, partial = 1f / 3, frame = 5).copy(chat = listOf(chatLine(104, "Psst")))) shouldBe Open
        window.perceived(steve, perception(105).copy(texts = hello, chat = listOf(chatLine(103, "Hello")))) shouldBe Open
        window.barrierSeen(alex, 1) shouldBe Open
        window.barrierSeen(steve, 1) shouldBe Passed(105)
    }

    test("a chat line expected several times passes only once that many arrived after the stimulus") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Beat", times = 2))))
        val drawn = listOf(text("chat", "Beat"))

        window.perceived(steve, perception(103).copy(texts = drawn, chat = listOf(chatLine(99, "Beat"), chatLine(103, "Beat")))) shouldBe
            Open
        window.perceived(steve, perception(106).copy(texts = drawn, chat = listOf(chatLine(103, "Beat"), chatLine(106, "Beat")))) shouldBe
            Passed(106)
    }

    test("a chat line on the last tick of the window passes") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(110).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(110, "Hello")))) shouldBe
            Passed(110)
    }

    test("a record from before the window still shown at the barrier holds from the window's first tick") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(99).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(101, "Hello")))) shouldBe
            Open
        window.barrierSeen(steve, 1) shouldBe Passed(101)
    }

    test("a record from before the window holds from the window's first tick once a later record follows it") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(100).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(101, "Hello")))) shouldBe
            Open
        window.perceived(steve, perception(105).copy(texts = listOf(), chat = listOf(chatLine(101, "Hello")))) shouldBe Passed(101)
    }

    test("a chat line that arrived before the stimulus does not pass while it still shows") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))
        val earlier = listOf(chatLine(100, "Hello"))

        window.perceived(steve, perception(100).copy(texts = listOf(text("chat", "Hello")), chat = earlier)) shouldBe Open
        window.perceived(
            steve,
            perception(104).copy(texts = listOf(text("chat", "Hello"), text("chat", "Bye")), chat = earlier + chatLine(104, "Bye")),
        ) shouldBe
            Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("a record from before the window showing only an earlier line does not pass at the barrier") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(100).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(100, "Hello")))) shouldBe
            Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("a chat line that arrived but is not drawn legibly does not pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(
            steve,
            perception(101).copy(texts = listOf(text("actionbar", "Hello")), chat = listOf(chatLine(101, "Hello"))),
        ) shouldBe
            Open
    }

    test("a chat line drawn but holding other text does not pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Goodbye"))))

        window.perceived(steve, perception(101).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(101, "Hello")))) shouldBe
            Open
    }

    test("a record after the window's last tick is too late to pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, perception(111).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(111, "Hello")))) shouldBe
            Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("the barrier with a check still open fails, naming the window's last tick and what the player perceived") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))
        window.perceived(
            steve,
            perception(101).copy(texts = listOf(text("chat", "Hello"), text("other", "Survival")), chat = listOf(chatLine(101, "Hello"))),
        )

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "gv-1 did not see chat \"Goodbye\" within 5 ticks"
        missed.report shouldContain "At tick 105 gv-1 perceived chat \"Hello\", other \"Survival\""
    }

    test("the failure reports what the player perceived at the window's last tick, not after it") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))
        window.perceived(steve, perception(102).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(102, "Hello"))))
        window.perceived(steve, perception(106).copy(texts = listOf(text("chat", "Later")), chat = listOf(chatLine(106, "Later"))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "At tick 105 gv-1 perceived chat \"Hello\""
    }

    test("the failure says so when the player perceived nothing") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "At tick 105 gv-1 perceived nothing"
    }

    test("the failure of a check about an entity reports what the frame showed of it at the window's last tick") {
        val zombie = EntityRef(UUID(0, 7), "minecraft:zombie")
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, entity(zombie).visible())))
        window.perceived(steve, perception(101).copy(entities = listOf(drawnEntity(UUID(0, 7), false, null, 0.0))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "gv-1 did not see entity zombie visible within 5 ticks"
        missed.report shouldContain "At tick 105 gv-1 perceived entity zombie drawn, owning 0% of the frame."
    }

    test("a barrier of another window changes nothing") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Hello"))))

        window.barrierSeen(steve, 6) shouldBe Open
        window.perceived(steve, perception(102).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(102, "Hello")))) shouldBe
            Passed(102)
    }

    test("a window with several checks passes once each has held, each in its own record") {
        val window =
            Window(
                anchor = 100,
                length = 10.ticks,
                barrier = 1,
                checks = listOf(Check(steve, chat("Bank: 1")), Check(alex, chat("Bank: 1"))),
            )

        window.perceived(steve, bankArrived) shouldBe Open
        window.perceived(
            alex,
            perception(104).copy(texts = listOf(text("chat", "Bank: 1")), chat = listOf(chatLine(104, "Bank: 1"))),
        ) shouldBe
            Passed(104)
    }

    test("a window with several players fails only once every checked player's barrier arrived") {
        val window =
            Window(
                anchor = 100,
                length = 10.ticks,
                barrier = 1,
                checks = listOf(Check(steve, chat("Bank: 1")), Check(alex, chat("Bank: 1"))),
            )

        window.barrierSeen(steve, 1) shouldBe Open
        val missed = window.barrierSeen(alex, 1).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "gv-1 did not see chat \"Bank: 1\""
        missed.report shouldContain "gv-2 did not see chat \"Bank: 1\""
    }

    test("a decided window stays decided") {
        val passed = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Hello"))))
        passed.perceived(steve, perception(101).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(101, "Hello"))))

        passed.barrierSeen(steve, 7) shouldBe Passed(101)
        passed.perceived(steve, perception(103).copy(texts = listOf(), chat = listOf(chatLine(101, "Hello")))) shouldBe Passed(101)

        val missed = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Hello"))))
        val verdict = missed.barrierSeen(steve, 7)

        missed.perceived(steve, perception(104).copy(texts = listOf(text("chat", "Hello")), chat = listOf(chatLine(104, "Hello")))) shouldBe
            verdict
    }

    test("a fact about a change compares with the record that stood at the stimulus") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, camera.rose())))

        window.perceived(steve, perception(90).copy(camera = camera(y = 101.62))) shouldBe Open
        window.perceived(steve, perception(102).copy(camera = camera(y = 101.62))) shouldBe Open
        window.perceived(steve, perception(103).copy(camera = camera(y = 102.1))) shouldBe Passed(103)
    }

    test("a later record before the stimulus replaces what stood at it") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, camera.rose())))

        window.perceived(steve, perception(90).copy(camera = camera(y = 100.0))) shouldBe Open
        window.perceived(steve, perception(99).copy(camera = camera(y = 103.0))) shouldBe Open
        window.perceived(steve, perception(102).copy(camera = camera(y = 102.0))) shouldBe Open
    }

    test("a window without a check is refused, since it could never fail") {
        val refusal = shouldThrow<RequirementRefused> { Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf()) }

        refusal.message shouldContain "positive check"
    }

    test("a never check fails at the first tick its fact shows, naming what the player saw and when") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(alexHearsNothing))

        window.perceived(steve, bankArrived) shouldBe Open
        val broken =
            window.perceived(
                alex,
                perception(103).copy(texts = listOf(text("chat", "Bank: 1")), chat = listOf(chatLine(103, "Bank: 1"))),
            )

        broken.shouldBeInstanceOf<Missed>().report shouldContain "gv-2 saw chat \"Bank: 1\" at tick 3 of the 10 tick window (tick 103)"
    }

    test("a window with a never check passes only once every checked player's barrier arrived, at the tick its checks held") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(alexHearsNothing))

        window.perceived(steve, bankArrived) shouldBe Open
        window.perceived(alex, perception(105)) shouldBe Open
        window.barrierSeen(steve, 1) shouldBe Open
        window.barrierSeen(alex, 1) shouldBe Passed(102)
    }

    test("a never check of the same player as a positive one keeps the window open until the barrier") {
        val holdsStick = Check(steve, held("stick"))
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(holdsStick))

        window.perceived(steve, bankArrived) shouldBe Open
        window.barrierSeen(steve, 1) shouldBe Passed(102)
    }

    test("a never check passes over a line that arrived before the stimulus, even while it is still drawn") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(alexHearsNothing))

        window.perceived(steve, bankArrived)
        window.perceived(alex, perception(104).copy(texts = listOf(text("chat", "Old")), chat = listOf(chatLine(99, "Old")))) shouldBe Open
        window.barrierSeen(steve, 1)
        window.barrierSeen(alex, 1) shouldBe Passed(102)
    }

    test("a record from before the window that shows a never fact breaks it at the window's first tick") {
        val stick = listOf(item("hotbar", 0, true, "minecraft:stick", 1))
        val holdsStick = Check(alex, held("stick"))
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(holdsStick))

        window.perceived(alex, perception(99).copy(items = stick)) shouldBe Open
        val broken = window.barrierSeen(alex, 1)

        broken.shouldBeInstanceOf<Missed>().report shouldContain "gv-2 saw held stick at tick 1 of the 10 tick window (tick 101)"
    }

    test("a fact a never check names after the window's last tick does not break it") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 1, checks = listOf(steveSeesBank), nevers = listOf(alexHearsNothing))

        window.perceived(steve, bankArrived)
        window.perceived(alex, perception(106).copy(texts = listOf(text("chat", "Late")), chat = listOf(chatLine(106, "Late")))) shouldBe
            Open
        window.barrierSeen(steve, 1)
        window.barrierSeen(alex, 1) shouldBe Passed(102)
    }

    test("a window with only never checks is refused, since a requirement needs one positive check") {
        val refusal =
            shouldThrow<RequirementRefused> {
                Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(), nevers = listOf(alexHearsNothing))
            }

        refusal.message shouldContain "positive check"
    }

    test("a state check holds at the first tick it is seen to hold, and the window passes once every check held") {
        val listed = StateCheck("Steve's session listed") { true }
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(steveSeesBank), states = listOf(listed))

        window.perceived(steve, bankArrived) shouldBe Open
        window.statesSeen(at = 101, held = listOf()) shouldBe Open
        window.openStates shouldBe listOf(listed)
        window.statesSeen(at = 104, held = listOf(listed)) shouldBe Passed(104)
    }

    test("a window with only a state check is a positive window") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(), states = listOf(StateCheck("listed") { true }))

        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("the barrier with a state check still open fails, naming the state") {
        val window =
            Window(
                anchor = 100,
                length = 5.ticks,
                barrier = 7,
                checks = listOf(),
                states = listOf(StateCheck("Steve's session listed") { false }),
            )

        window.statesSeen(at = 105, held = listOf()) shouldBe Open
        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "Steve's session listed did not hold within 5 ticks (ticks 101 to 105)."
    }
}
