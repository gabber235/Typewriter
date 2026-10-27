package com.typewritermc.types

import java.io.File
import java.net.URLClassLoader
import java.nio.file.Path
import java.util.concurrent.TimeUnit

/**
 * Runs one [SkirColdProbeMain] process per entry, each first touching the named serializer, and returns each exit code.
 * Fails when a probe times out or exits non zero; [entries] named "concurrent" race first access on several threads.
 */
fun runColdProbes(entries: List<String>): List<Int> {
    val java = Path.of(System.getProperty("java.home"), "bin", "java").toString()
    val classpath = coldProbeClasspath()
    val probes =
        entries.map { entry ->
            entry to
                ProcessBuilder(
                    java,
                    "-cp",
                    classpath,
                    SkirColdProbeMain::class.java.name,
                    entry,
                ).redirectErrorStream(true)
                    .start()
        }
    val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(45)
    probes.forEach { (_, process) ->
        val remaining = deadline - System.nanoTime()
        if (remaining > 0) process.waitFor(remaining, TimeUnit.NANOSECONDS)
    }
    val unfinished = probes.filter { (_, process) -> process.isAlive }
    if (unfinished.isNotEmpty()) {
        unfinished.forEach { (_, process) -> process.destroyForcibly() }
        unfinished.forEach { (_, process) -> process.waitFor(5, TimeUnit.SECONDS) }
        val output =
            unfinished.joinToString("\n") { (entry, process) ->
                "$entry:\n${process.inputStream.bufferedReader().readText()}"
            }
        error("Cold serializer probes timed out.\n$output")
    }
    return probes.map { (entry, process) ->
        val output = process.inputStream.bufferedReader().readText()
        check(process.exitValue() == 0) {
            "Cold serializer probe failed for $entry\n$output"
        }
        process.exitValue()
    }
}

fun coldProbeClasspath(): String =
    buildSet {
        addAll(System.getProperty("java.class.path").split(File.pathSeparator))
        generateSequence(SkirColdProbeMain::class.java.classLoader) { loader -> loader.parent }
            .filterIsInstance<URLClassLoader>()
            .flatMap { loader -> loader.urLs.asSequence() }
            .filter { url -> url.protocol == "file" }
            .map { url -> Path.of(url.toURI()).toString() }
            .forEach(::add)
    }.joinToString(File.pathSeparator)
