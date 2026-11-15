package com.typewritermc.playtest

import java.nio.file.Path

/**
 * Where one attempt of a case keeps the frames it writes: the folder `<case>/attempt-<n>` beside the
 * run file, named after the case's test id, so the run file and its evidence travel together.
 */
internal class Evidence(
    runFolder: Path,
    testId: String,
    attempt: Int,
) {
    /** The attempt's folder, relative to the run file's folder. */
    val folder = "${testId.replace(Regex("[^A-Za-z0-9-]+"), "-").trim('-')}/attempt-$attempt"

    private val dir = runFolder.resolve(folder)

    /** The frames written so far, relative to [folder]. */
    val screenshots = mutableListOf<String>()

    /** The file [name] in the attempt's folder. */
    fun file(name: String): Path = dir.resolve(name)
}
