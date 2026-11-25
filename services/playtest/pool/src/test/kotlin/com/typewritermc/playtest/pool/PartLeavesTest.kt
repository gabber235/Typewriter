package com.typewritermc.playtest.pool

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import java.nio.file.Files

val PartLeavesTest by testSuite {
    // A folder stands in for the game's cgroup, which the run's tree gives the pool: the kernel makes a
    // leaf's control files as the leaf is made, and counts into memory.events and memory.peak.

    test(
        "each part runs in a leaf of its own under the game's cgroup, held to the game's limit while limits are only measured, and dies whole",
    ) {
        val game = Files.createTempDirectory("game")
        Files.writeString(game.resolve("memory.max"), "16834887680\n")

        PartLeaves(game).place("client-gv-1-4242", 4242)

        val leaf = game.resolve("client-gv-1-4242")
        Files.readString(leaf.resolve("memory.max")) shouldBe "16834887680"
        Files.readString(leaf.resolve("memory.oom.group")) shouldBe "1"
        Files.readString(leaf.resolve("cgroup.procs")) shouldBe "4242"
    }

    test("a leaf tells whether the kernel killed its part for memory, and the most memory the part took") {
        val game = Files.createTempDirectory("game")
        Files.writeString(game.resolve("memory.max"), "max\n")
        val leaf = PartLeaves(game).place("paper-77", 77)
        val dir = leaf.dir
        Files.writeString(dir.resolve("memory.events"), "low 0\nhigh 0\nmax 12\noom 1\noom_kill 0\noom_group_kill 0\n")
        Files.writeString(dir.resolve("memory.peak"), "3221225472\n")

        leaf.killedForMemory() shouldBe false
        leaf.peakBytes() shouldBe 3221225472L

        Files.writeString(dir.resolve("memory.events"), "low 0\nhigh 0\nmax 40\noom 2\noom_kill 1\noom_group_kill 1\n")
        leaf.killedForMemory() shouldBe true
    }

    test("the game's cgroup gives the pool its memory budget, unless it has no limit") {
        val limited = Files.createTempDirectory("game")
        Files.writeString(limited.resolve("memory.max"), "16834887680\n")
        val unlimited = Files.createTempDirectory("game")
        Files.writeString(unlimited.resolve("memory.max"), "max\n")

        PartLeaves(limited).budget()?.bytes shouldBe 16834887680L
        PartLeaves(unlimited).budget() shouldBe null
    }
}
