package com.typewritermc.playtest

import com.typewritermc.playtest.wire.PoolFile
import kotlin.jvm.optionals.getOrNull

/**
 * The heap share, as `-XX:MaxRAMPercentage`, that the JVM of the game part whose folder in the pool
 * folder is [folder] runs with; null when it runs with none or no process of that part runs.
 */
fun heapShareOf(folder: String): Double? = partProcess(folder)?.let(::heapShareOf)

/** The heap share the pool's JVM runs with; null when it runs with none. */
fun poolHeapShare(): Double? =
    PoolFile
        .read(PlaytestSettings.fromSystemProperties().poolDir.resolve(PoolFile.NAME))
        .flatMap { it.process().running() }
        .getOrNull()
        ?.let(::heapShareOf)

/** The folder in the pool folder of the Paper the attempt runs on: `paper`, or the name of its own. */
val RequirementScope.paperFolder: String get() = attempt.paper

/**
 * Asks the JVM of [process] itself through `jcmd`, since Linux hands the JDK only the first page of a
 * command line and Paper's and a client's run longer.
 */
private fun heapShareOf(process: ProcessHandle): Double? {
    val jcmd = PlaytestSettings.fromSystemProperties().java.resolveSibling("jcmd")
    val flags =
        ProcessBuilder(jcmd.toString(), process.pid().toString(), "VM.flags")
            .redirectErrorStream(true)
            .start()
            .run { inputStream.bufferedReader().readText().also { waitFor() } }
    return Regex("""-XX:MaxRAMPercentage=([0-9.]+)""")
        .find(flags)
        ?.groupValues
        ?.get(1)
        ?.toDouble()
}
