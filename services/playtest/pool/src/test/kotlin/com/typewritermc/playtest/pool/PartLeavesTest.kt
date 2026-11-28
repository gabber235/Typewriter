package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.PartLimit
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.harness.v1.test_run.MemoryKill
import java.nio.file.Files

val PartLeavesTest by testSuite {
    // A folder stands in for the game's cgroup, which the run's tree gives the pool: the kernel makes a
    // leaf's control files as the leaf is made, and counts into memory.events and memory.peak.

    test("each part runs in a leaf of its own under the game's cgroup, held to its kind's limit, and dies whole") {
        val game = Files.createTempDirectory("game")
        Files.writeString(game.resolve("memory.max"), "11270000000\n")

        PartLeaves(game).place("client-gv-1-4242", 4242, PartLimit.CLIENT)

        val leaf = game.resolve("client-gv-1-4242")
        // A client's 1775 MiB.
        Files.readString(leaf.resolve("memory.max")) shouldBe "1861222400"
        Files.readString(leaf.resolve("memory.oom.group")) shouldBe "1"
        Files.readString(leaf.resolve("cgroup.procs")) shouldBe "4242"
    }

    test("a leaf tells the most memory its part took, and whether the kernel killed it for its own limit or as the machine ran out") {
        val game = Files.createTempDirectory("game")
        Files.writeString(game.resolve("memory.max"), "max\n")
        val leaf = PartLeaves(game).place("paper-77", 77, PartLimit.OWN_PAPER)
        val dir = leaf.dir
        Files.writeString(dir.resolve("memory.events"), "low 0\nhigh 0\nmax 12\noom 1\noom_kill 0\noom_group_kill 0\n")
        Files.writeString(dir.resolve("memory.peak"), "3221225472\n")

        leaf.memoryKill() shouldBe null
        leaf.peakBytes() shouldBe 3221225472L

        // The kernel counts an out of memory kill in the victim's cgroup whichever killer chose it, and
        // counts `oom` only where the cgroup reached its own limit.
        Files.writeString(dir.resolve("memory.events"), "low 0\nhigh 0\nmax 12\noom 0\noom_kill 1\noom_group_kill 1\n")
        leaf.memoryKill() shouldBe MemoryKill.MACHINE_OUT_OF_MEMORY

        Files.writeString(game.resolve("memory.events"), "low 0\nhigh 0\nmax 3\noom 1\noom_kill 1\noom_group_kill 1\n")
        leaf.memoryKill() shouldBe MemoryKill.GAME_BUDGET

        Files.writeString(dir.resolve("memory.events"), "low 0\nhigh 0\nmax 40\noom 2\noom_kill 1\noom_group_kill 1\n")
        leaf.memoryKill() shouldBe MemoryKill.OWN_LIMIT
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
