package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

/** One game module's additions to Paper in a fresh folder, as its build writes them: [files] by their path in Paper's folder, and [env]. */
fun addition(
    files: Map<String, String> = mapOf(),
    env: Map<String, String> = mapOf(),
): Path {
    val dir = Files.createTempDirectory("addition")
    files.forEach { (path, text) ->
        val file = dir.resolve(PaperAdditions.FILES).resolve(path)
        file.parent.createDirectories()
        file.writeText(text)
    }
    if (env.isNotEmpty()) dir.resolve(PaperAdditions.ENV).writeText(env.entries.joinToString("\n") { "${it.key}=${it.value}" })
    return dir
}
