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
