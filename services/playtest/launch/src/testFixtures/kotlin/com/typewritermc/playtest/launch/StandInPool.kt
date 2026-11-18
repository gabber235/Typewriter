package com.typewritermc.playtest.launch

import java.nio.file.Path

/**
 * A process standing in for the game pool: it names itself in the pool file `args[0]` as listening for
 * the run `args[1]`, then runs until its standard input ends, as the pool does.
 */
fun main(args: Array<String>) {
    PoolFile.of(0, args[1]).write(Path.of(args[0]))
    System.`in`.readAllBytes()
}

/** The command that runs the stand in pool of [run], named in [poolFile], on this test JVM's Java. */
fun standInPool(
    poolFile: Path,
    run: String,
): List<String> =
    listOf(
        ProcessHandle
            .current()
            .info()
            .command()
            .get(),
        "-cp",
        System.getProperty("java.class.path"),
        "com.typewritermc.playtest.launch.StandInPoolKt",
        poolFile.toString(),
        run,
    )
