package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

/** A fresh, empty Paper folder. */
fun paperFolder(): Path = Files.createTempDirectory("paper")

/** Writes [text] at [path] inside this Paper folder, creating its folders. */
fun Path.writeAt(
    path: String,
    text: String,
) {
    resolve(path).also { it.parent.createDirectories() }.writeText(text)
}

/** The pool's Papers, each own Paper in a fresh folder of one temporary pool folder that goes when its Paper is gone. */
internal fun scratchPapers(): Papers {
    val pool = Files.createTempDirectory("papers")
    return Papers(
        folderOf = { name, slot -> PaperFolder(name, pool.resolve(name).createDirectories(), 0, pool.resolve("$name.log"), slot) },
        remove = { it.dir.toFile().deleteRecursively() },
    )
}

/** The shared Paper, in slot 0 and a fresh folder, with [players] joined. */
internal fun sharedPaper(players: Set<String> = setOf("gv-1")): Server {
    val dir = paperFolder()
    return Server(PaperFolder("paper", dir, 0, dir.resolveSibling("${dir.fileName}.log"), slot = 0), SharedPaper("paper", players))
}
