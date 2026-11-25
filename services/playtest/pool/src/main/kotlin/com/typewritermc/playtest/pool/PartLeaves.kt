package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path

/**
 * The cgroup v2 folder the run's tree gives the game ([game]), where every game part runs in a leaf of
 * its own, the pool's own included. The kernel counts each leaf's memory, records the most it took, and
 * kills the leaf's processes together once they take more than the leaf's limit. While limits are only
 * measured, every leaf takes the game's limit, the runner's memory; each kind's own limit ([PartLimit])
 * comes in once the measured peaks set it.
 */
internal class PartLeaves(
    private val game: Path,
) {
    /** The game's limit as the pool's memory budget; null when the game's cgroup has none. */
    fun budget(): MemoryBudget? = limitOf(game)?.let { MemoryBudget(it, "the game's cgroup") }

    /** Makes the leaf [name] and moves the process [pid] into it. */
    fun place(
        name: String,
        pid: Long,
    ): Leaf {
        val dir = game.resolve(name)
        Files.createDirectories(dir)
        Files.writeString(dir.resolve("memory.max"), Files.readString(game.resolve("memory.max")).trim())
        // The kernel kills every process of the leaf together, so a part dies whole.
        Files.writeString(dir.resolve("memory.oom.group"), "1")
        Files.writeString(dir.resolve("cgroup.procs"), pid.toString())
        return Leaf(dir)
    }

    /** One part's leaf. */
    class Leaf(
        val dir: Path,
    ) {
        /** Whether the kernel killed a process of the part for memory. */
        fun killedForMemory(): Boolean =
            read("memory.events")
                ?.lineSequence()
                ?.map { it.split(' ') }
                ?.any { it.size == 2 && it[0] == "oom_kill" && it[1].toLong() > 0 } == true

        /** The most memory the part took, in bytes; null when the kernel records none. */
        fun peakBytes(): Long? = read("memory.peak")?.trim()?.toLongOrNull()

        /** Removes the leaf once its processes are gone; one that still holds any stays. */
        fun remove() {
            runCatching { Files.deleteIfExists(dir) }
        }

        private fun read(file: String): String? = dir.resolve(file).takeIf(Files::isRegularFile)?.let(Files::readString)
    }

    companion object {
        /** The limit in the cgroup folder [dir]'s `memory.max`, in bytes; null for none. */
        private fun limitOf(dir: Path): Long? = Files.readString(dir.resolve("memory.max")).trim().toLongOrNull()
    }
}
