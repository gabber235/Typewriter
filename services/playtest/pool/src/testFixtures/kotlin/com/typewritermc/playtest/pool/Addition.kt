package com.typewritermc.playtest.pool

import java.nio.file.Files
import java.nio.file.Path
import kotlin.io.path.createDirectories
import kotlin.io.path.writeText

/**
 * One game module's additions to Paper in a fresh folder, as its build writes them: [files] by their path in Paper's
 * folder, [env] for every Paper, [slotEnv] for the Paper of one slot each, and the paths [kept] per slot.
 */
fun addition(
    files: Map<String, String> = mapOf(),
    env: Map<String, String> = mapOf(),
    slotEnv: Map<Int, Map<String, String>> = mapOf(),
    kept: List<String> = listOf(),
): Path {
    val dir = Files.createTempDirectory("addition")
    files.forEach { (path, text) ->
        val file = dir.resolve(PaperAdditions.FILES).resolve(path)
        file.parent.createDirectories()
        file.writeText(text)
    }
    if (env.isNotEmpty()) dir.resolve(PaperAdditions.ENV).writeProperties(env)
    slotEnv.forEach { (slot, values) ->
        dir
            .resolve(PaperAdditions.SLOTS)
            .resolve(slot.toString())
            .createDirectories()
            .resolve(PaperAdditions.ENV)
            .writeProperties(values)
    }
    if (kept.isNotEmpty()) dir.resolve(PaperAdditions.KEPT).writeText(kept.joinToString("\n"))
    return dir
}

private fun Path.writeProperties(values: Map<String, String>) = writeText(values.entries.joinToString("\n") { "${it.key}=${it.value}" })
