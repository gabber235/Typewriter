package com.typewritermc.playtest

import com.typewritermc.playtest.Window.Verdict.Missed
import com.typewritermc.playtest.Window.Verdict.Open
import com.typewritermc.playtest.Window.Verdict.Passed
import com.typewritermc.playtest.wire.Message.ChatLine
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.Text
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import java.util.UUID

val WindowTest by testSuite {
    val steve = GamePlayer("gv-1", UUID(0, 1))
    val alex = GamePlayer("gv-2", UUID(0, 2))

    test("a chat line that arrives after the stimulus and is drawn passes at the tick it shows") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(101, listOf(), listOf())) shouldBe Open
        window.perceived(steve, Perception(103, listOf(Text("chat", "Hello")), listOf(ChatLine(103, "Hello")))) shouldBe Passed(103)
    }

    test("a chat line on the last tick of the window passes") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(110, listOf(Text("chat", "Hello")), listOf(ChatLine(110, "Hello")))) shouldBe Passed(110)
    }

    test("a record from before the window still shown at the barrier holds from the window's first tick") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(99, listOf(Text("chat", "Hello")), listOf(ChatLine(101, "Hello")))) shouldBe Open
        window.barrierSeen(steve, 1) shouldBe Passed(101)
    }

    test("a record from before the window holds from the window's first tick once a later record follows it") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(100, listOf(Text("chat", "Hello")), listOf(ChatLine(101, "Hello")))) shouldBe Open
        window.perceived(steve, Perception(105, listOf(), listOf(ChatLine(101, "Hello")))) shouldBe Passed(101)
    }

    test("a chat line that arrived before the stimulus does not pass while it still shows") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))
        val earlier = listOf(ChatLine(100, "Hello"))

        window.perceived(steve, Perception(100, listOf(Text("chat", "Hello")), earlier)) shouldBe Open
        window.perceived(
            steve,
            Perception(104, listOf(Text("chat", "Hello"), Text("chat", "Bye")), earlier + ChatLine(104, "Bye")),
        ) shouldBe
            Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("a record from before the window showing only an earlier line does not pass at the barrier") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(100, listOf(Text("chat", "Hello")), listOf(ChatLine(100, "Hello")))) shouldBe Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("a chat line that arrived but is not drawn legibly does not pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(101, listOf(Text("actionbar", "Hello")), listOf(ChatLine(101, "Hello")))) shouldBe Open
    }

    test("a chat line drawn but holding other text does not pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Goodbye"))))

        window.perceived(steve, Perception(101, listOf(Text("chat", "Hello")), listOf(ChatLine(101, "Hello")))) shouldBe Open
    }

    test("a record after the window's last tick is too late to pass") {
        val window = Window(anchor = 100, length = 10.ticks, barrier = 1, checks = listOf(Check(steve, chat("Hello"))))

        window.perceived(steve, Perception(111, listOf(Text("chat", "Hello")), listOf(ChatLine(111, "Hello")))) shouldBe Open
        window.barrierSeen(steve, 1).shouldBeInstanceOf<Missed>()
    }

    test("the barrier with a check still open fails, naming the window's last tick and what the player perceived") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))
        window.perceived(steve, Perception(101, listOf(Text("chat", "Hello"), Text("other", "Survival")), listOf(ChatLine(101, "Hello"))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "gv-1 did not see chat \"Goodbye\" within 5 ticks"
        missed.report shouldContain "At tick 105 gv-1 perceived chat \"Hello\", other \"Survival\""
    }

    test("the failure reports what the player perceived at the window's last tick, not after it") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))
        window.perceived(steve, Perception(102, listOf(Text("chat", "Hello")), listOf(ChatLine(102, "Hello"))))
        window.perceived(steve, Perception(106, listOf(Text("chat", "Later")), listOf(ChatLine(106, "Later"))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "At tick 105 gv-1 perceived chat \"Hello\""
    }

    test("the failure says so when the player perceived nothing") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Goodbye"))))

        val missed = window.barrierSeen(steve, 7).shouldBeInstanceOf<Missed>()

        missed.report shouldContain "At tick 105 gv-1 perceived nothing"
    }

    test("a barrier of another window changes nothing") {
        val window = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Hello"))))

        window.barrierSeen(steve, 6) shouldBe Open
        window.perceived(steve, Perception(102, listOf(Text("chat", "Hello")), listOf(ChatLine(102, "Hello")))) shouldBe Passed(102)
    }

    test("a window with several checks passes once each has held, each in its own record") {
        val window =
            Window(
                anchor = 100,
                length = 10.ticks,
                barrier = 1,
                checks = listOf(Check(steve, chat("Bank: 1")), Check(alex, chat("Bank: 1"))),
            )

        window.perceived(steve, Perception(102, listOf(Text("chat", "Bank: 1")), listOf(ChatLine(102, "Bank: 1")))) shouldBe Open
        window.perceived(alex, Perception(104, listOf(Text("chat", "Bank: 1")), listOf(ChatLine(104, "Bank: 1")))) shouldBe Passed(104)
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
        passed.perceived(steve, Perception(101, listOf(Text("chat", "Hello")), listOf(ChatLine(101, "Hello"))))

        passed.barrierSeen(steve, 7) shouldBe Passed(101)
        passed.perceived(steve, Perception(103, listOf(), listOf(ChatLine(101, "Hello")))) shouldBe Passed(101)

        val missed = Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf(Check(steve, chat("Hello"))))
        val verdict = missed.barrierSeen(steve, 7)

        missed.perceived(steve, Perception(104, listOf(Text("chat", "Hello")), listOf(ChatLine(104, "Hello")))) shouldBe verdict
    }

    test("a window without a check is refused, since it could never fail") {
        val refusal = shouldThrow<IllegalArgumentException> { Window(anchor = 100, length = 5.ticks, barrier = 7, checks = listOf()) }

        refusal.message shouldContain "positive check"
    }
}
