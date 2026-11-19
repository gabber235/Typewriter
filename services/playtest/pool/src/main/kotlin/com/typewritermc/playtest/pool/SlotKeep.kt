package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.isDirectory
import kotlin.io.path.relativeTo

/**
 * What a slot keeps across its Papers: a restart attempt's own Paper gets a fresh folder, but the
 * [paths] its slot's earlier Paper wrote there come back, as a plugin's identity must when every own
 * Paper of a slot is to be the same server to the outside. [store] holds one folder per slot; a run
 * starts it empty ([fresh]), so nothing outlives the run.
 */
internal class SlotKeep(
    private val store: Path,
    private val paths: List<String>,
) {
    /** Keeps what [paper]'s folder holds at the kept paths for slot [slot], replacing what the slot kept before. */
    fun save(
        slot: Int,
        paper: Path,
    ) {
        paths.forEach { path ->
            val kept = slotDir(slot).resolve(path)
            remove(kept)
            val source = paper.resolve(path)
            if (source.exists()) copy(source, kept)
        }
    }

    /** Puts what slot [slot] kept into the fresh Paper folder [paper]. */
    fun restore(
        slot: Int,
        paper: Path,
    ) {
        paths.forEach { path ->
            val kept = slotDir(slot).resolve(path)
            if (kept.exists()) copy(kept, paper.resolve(path))
        }
    }

    private fun slotDir(slot: Int): Path = store.resolve(slot.toString())

    companion object {
        /** A keep in [store] that holds nothing yet: whatever an earlier run kept there goes. */
        fun fresh(
            store: Path,
            paths: List<String>,
        ): SlotKeep {
            remove(store)
            return SlotKeep(store.createDirectories(), paths)
        }

        private fun copy(
            source: Path,
            target: Path,
        ) {
            val files = if (source.isDirectory()) Files.walk(source).use { it.filter(Files::isRegularFile).toList() } else listOf(source)
            files.forEach { file ->
                val copied = if (file == source) target else target.resolve(file.relativeTo(source).toString())
                copied.parent.createDirectories()
                Files.copy(file, copied)
            }
        }

        private fun remove(path: Path) {
            if (path.exists()) path.toFile().deleteRecursively()
        }
    }
}
