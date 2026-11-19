package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import kotlin.io.path.exists
import kotlin.io.path.readText

val SlotKeepTest by testSuite {
    test("what a slot's Paper wrote at a kept path is in that slot's next Paper, and in no other slot's") {
        val keep = SlotKeep(Files.createTempDirectory("slots"), listOf("plugins/Typewriter/state"))
        val first = paperFolder()
        first.writeAt("plugins/Typewriter/state/identity", "slot 1 identity")

        keep.save(slot = 1, paper = first)
        val next = paperFolder()
        val other = paperFolder()
        keep.restore(slot = 1, paper = next)
        keep.restore(slot = 2, paper = other)

        next.resolve("plugins/Typewriter/state/identity").readText() shouldBe "slot 1 identity"
        other.resolve("plugins/Typewriter/state").exists() shouldBe false
    }

    test("a slot keeps what its latest Paper wrote, and only the kept paths") {
        val keep = SlotKeep(Files.createTempDirectory("slots"), listOf("plugins/Typewriter/state"))
        val first = paperFolder()
        first.writeAt("plugins/Typewriter/state/identity", "old")
        first.writeAt("plugins/Typewriter/state/stale", "gone later")
        keep.save(slot = 1, paper = first)
        val second = paperFolder()
        second.writeAt("plugins/Typewriter/state/identity", "new")
        second.writeAt("world/level.dat", "not kept")

        keep.save(slot = 1, paper = second)
        val third = paperFolder()
        keep.restore(slot = 1, paper = third)

        third.resolve("plugins/Typewriter/state/identity").readText() shouldBe "new"
        third.resolve("plugins/Typewriter/state/stale").exists() shouldBe false
        third.resolve("world").exists() shouldBe false
    }

    test("a new run keeps nothing an earlier run's Papers wrote") {
        val store = Files.createTempDirectory("slots")
        val earlier = SlotKeep(store, listOf("plugins/Typewriter/state"))
        earlier.save(slot = 1, paper = paperFolder().also { it.writeAt("plugins/Typewriter/state/identity", "earlier run") })

        val run = SlotKeep.fresh(store, listOf("plugins/Typewriter/state"))
        val next = paperFolder()
        run.restore(slot = 1, paper = next)

        next.resolve("plugins/Typewriter/state").exists() shouldBe false
    }
}
