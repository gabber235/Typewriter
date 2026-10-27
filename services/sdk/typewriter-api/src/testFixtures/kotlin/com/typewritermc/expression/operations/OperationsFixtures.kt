package com.typewritermc.expression.operations

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.Path

internal fun checkForms(
    label: String,
    sources: List<String>,
    nfc: String,
    nfd: String,
    nfkc: String,
    nfkd: String,
    failures: MutableList<String>,
) {
    for (source in sources) {
        val forms =
            listOf(
                "NFC" to (PortableUnicode.normalize(source, compatibility = false, compose = true) to nfc),
                "NFD" to (PortableUnicode.normalize(source, compatibility = false, compose = false) to nfd),
                "NFKC" to (PortableUnicode.normalize(source, compatibility = true, compose = true) to nfkc),
                "NFKD" to (PortableUnicode.normalize(source, compatibility = true, compose = false) to nfkd),
            )
        for ((form, outcome) in forms) {
            if (outcome.first != outcome.second) failures += "$label: $form(${source.hex()}) was ${outcome.first.hex()}"
        }
    }
}

internal fun codePoints(field: String): String =
    buildString {
        field.trim().split(' ').forEach { appendCodePoint(it.toInt(16)) }
    }

internal fun String.hex(): String = codePoints().toArray().joinToString(" ") { "%04X".format(it) }

/** The data lines of a semicolon separated Unicode data file, with comments removed and fields trimmed. */
internal fun unicodeRecords(file: String): List<List<String>> =
    Files
        .readAllLines(unicodeFile(file))
        .map { it.substringBefore('#').trim() }
        .filter(String::isNotEmpty)
        .map { line -> line.split(';').map(String::trim) }

internal fun unicodeFile(name: String): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("services/protocol/unicode/${PortableUnicodeTables.RELEASE}/$name") }
        .first(Files::exists)
