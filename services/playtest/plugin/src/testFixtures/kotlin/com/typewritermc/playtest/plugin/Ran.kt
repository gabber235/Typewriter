package com.typewritermc.playtest.plugin

/**
 * A stand in for the JaCoCo agent inside Paper: it counts the code that [run] names, hands it over and
 * forgets it on each read, and keeps every read [Coverage] sends, so a test sees which attempt got what.
 */
class Ran {
    private val since = linkedSetOf<String>()

    /** Every read [Coverage] handed on, in order. */
    val reads = mutableListOf<Coverage.Read>()

    /** Plugin code named [code] runs now. */
    fun run(code: String) {
        since += code
    }

    /** What ran since the last read, which counts as not run from now on. */
    fun readAndReset(): ByteArray = since.joinToString("\n").toByteArray().also { since.clear() }

    /** Each attempt with all the code its reads named. */
    fun covered(): Map<Long, Set<String>> =
        reads
            .flatMap { read -> read.attempts.map { attempt -> attempt to String(read.exec).lines().filter(String::isNotEmpty) } }
            .groupBy({ it.first }, { it.second })
            .mapValues { (_, code) -> code.flatten().toSet() }
}
