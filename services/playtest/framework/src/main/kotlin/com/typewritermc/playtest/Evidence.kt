package com.typewritermc.playtest

import java.nio.file.Path

/**
 * Where one attempt of a case keeps the frames and clips it writes: the folder `<case>/<attempt>`
 * beside the run file, named after the case's test id and the attempt (`attempt-2`, or `demo`), so the
 * run file and its evidence travel together.
 */
internal class Evidence(
    runFolder: Path,
    testId: String,
    attempt: String,
) {
    /** The attempt's folder, relative to the run file's folder. */
    val folder = "${testId.replace(Regex("[^A-Za-z0-9-]+"), "-").trim('-')}/$attempt"

    private val dir = runFolder.resolve(folder)

    /** The frames written so far, relative to [folder]. */
    val screenshots = mutableListOf<String>()

    /** The clips written so far, relative to [folder]. */
    val clips = mutableListOf<String>()

    /** The file [name] in the attempt's folder. */
    fun file(name: String): Path = dir.resolve(name)
}
