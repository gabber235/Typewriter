package com.typewritermc.expression.operations

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import java.nio.file.Files
import java.nio.file.Path

val PortableUnicodeTest by testSuite {
    test("case mapping applies full untailored mappings with Final_Sigma") {
        PortableUnicode.upper("Straße") shouldBe "STRASSE"
        PortableUnicode.lower("ΟΔΟΣ") shouldBe "οδος"
        PortableUnicode.lower("ΣΑ") shouldBe "σα"
        PortableUnicode.lower("ΆΣ.") shouldBe "άς."
        PortableUnicode.lower("ΑΣ́Β") shouldBe "ασ́β"
        PortableUnicode.lower("İ") shouldBe "i̇"
        PortableUnicode.upper("i") shouldBe "I"
        PortableUnicode.upper("ŉ") shouldBe "ʼN"
        PortableUnicode.lower("𐐀") shouldBe "𐐨"
        PortableUnicode.upper("\uD800x") shouldBe "\uD800X"
    }

    test("title case starts each white space separated word with its titlecase mapping") {
        PortableUnicode.title("ǆemal") shouldBe "ǅemal"
        PortableUnicode.title("hello wORLD") shouldBe "Hello World"
        PortableUnicode.title("ΟΔΟΣ ΑΒ") shouldBe "Οδος Αβ"
        PortableUnicode.title("ﬂour　ﬁx") shouldBe "Flour　Fix"
        PortableUnicode.title("a-b c") shouldBe "A-b C"
    }

    test("case folding applies the full C and F foldings") {
        PortableUnicode.foldCase("Straße") shouldBe "strasse"
        PortableUnicode.foldCase("ΣΑΣ") shouldBe "σασ"
        PortableUnicode.foldCase("İ") shouldBe "i̇"
        PortableUnicode.foldCase("ẞ") shouldBe "ss"
    }

    test("normalization produces the four UAX 15 forms") {
        PortableUnicode.normalize("Å", compatibility = false, compose = true) shouldBe "Å"
        PortableUnicode.normalize("Å", compatibility = false, compose = false) shouldBe "Å"
        PortableUnicode.normalize("ﬁ", compatibility = true, compose = true) shouldBe "fi"
        PortableUnicode.normalize("ﬁ", compatibility = false, compose = true) shouldBe "ﬁ"
        PortableUnicode.normalize("가", compatibility = false, compose = false) shouldBe "가"
        PortableUnicode.normalize("각", compatibility = false, compose = true) shouldBe "각"
        PortableUnicode.normalize("", compatibility = false, compose = true) shouldBe ""
    }

    test("white space is the pinned White_Space property plus U+FEFF") {
        PortableUnicode.trimStart("　﻿x") shouldBe "x"
        PortableUnicode.trimEnd("x\u0085") shouldBe "x"
        PortableUnicode.trimStart(" \tx ") shouldBe "x "
        PortableUnicode.trimEnd(" x  ") shouldBe " x"
        PortableUnicode.trimEnd("x​") shouldBe "x​"
        PortableUnicode.isWhiteSpace(0x180E) shouldBe false
        PortableUnicode.isWhiteSpace(0x1680) shouldBe true
    }

    test("every code point maps and folds as the pinned UnicodeData, SpecialCasing and CaseFolding files say") {
        val simple = HashMap<Int, List<String>>()
        Files.readAllLines(unicodeFile("UnicodeData.txt")).forEach { line ->
            val fields = line.split(';')
            simple[fields[0].toInt(16)] = listOf(fields[12], fields[13], fields[14].ifEmpty { fields[12] })
        }
        val special = HashMap<Int, List<String>>()
        unicodeRecords("SpecialCasing.txt").filter { it[4].isEmpty() }.forEach { special[it[0].toInt(16)] = it }
        val folding = HashMap<Int, String>()
        unicodeRecords("CaseFolding.txt").filter { it[1] == "C" || it[1] == "F" }.forEach { folding[it[0].toInt(16)] = it[2] }

        val failures = mutableListOf<String>()
        for (codePoint in 0..0x10FFFF) {
            if (codePoint in 0xD800..0xDFFF) continue
            val value = String(Character.toChars(codePoint))
            val self = "%04X".format(codePoint)
            val expected =
                listOf(
                    "upper" to (special[codePoint]?.get(3) ?: simple[codePoint]?.get(0)),
                    "lower" to (special[codePoint]?.get(1) ?: simple[codePoint]?.get(1)),
                    "title" to (special[codePoint]?.get(2) ?: simple[codePoint]?.get(2)),
                    "fold" to folding[codePoint],
                ).map { (operation, mapping) -> operation to codePoints(mapping?.ifEmpty { null } ?: self) }
            val actual =
                listOf(
                    PortableUnicode.upper(value),
                    PortableUnicode.lower(value),
                    PortableUnicode.title(value),
                    PortableUnicode.foldCase(value),
                )
            expected.zip(actual).forEach { (expectation, outcome) ->
                if (outcome != expectation.second) failures += "${expectation.first}($self) was ${outcome.hex()}"
            }
        }
        failures.take(20).shouldBeEmpty()
    }

    test("normalization conforms to every line of the pinned NormalizationTest.txt") {
        PortableUnicodeTables.RELEASE shouldBe "17.0.0"
        val failures = mutableListOf<String>()
        val listed = HashSet<Int>()
        var part = ""
        var lines = 0
        Files.readAllLines(unicodeFile("NormalizationTest.txt")).forEach { line ->
            val data = line.substringBefore('#').trim()
            if (data.isEmpty()) return@forEach
            if (data.startsWith("@")) {
                part = data
                return@forEach
            }
            lines++
            val (source, nfc, nfd, nfkc, nfkd) = data.split(';').take(5).map(::codePoints)
            if (part == "@Part1") listed += source.codePointAt(0)
            checkForms(line, listOf(source, nfc, nfd), nfc = nfc, nfd = nfd, nfkc = nfkc, nfkd = nfkd, failures)
            checkForms(line, listOf(nfkc, nfkd), nfc = nfkc, nfd = nfkd, nfkc = nfkc, nfkd = nfkd, failures)
        }
        for (codePoint in 0..0x10FFFF) {
            if (codePoint in 0xD800..0xDFFF || codePoint in listed) continue
            val value = String(Character.toChars(codePoint))
            checkForms("unlisted U+%04X".format(codePoint), listOf(value), value, value, value, value, failures)
        }
        (lines > 20_000) shouldBe true
        failures.take(20).shouldBeEmpty()
    }
}

private fun checkForms(
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

private fun codePoints(field: String): String =
    buildString {
        field.trim().split(' ').forEach { appendCodePoint(it.toInt(16)) }
    }

private fun String.hex(): String = codePoints().toArray().joinToString(" ") { "%04X".format(it) }

/** The data lines of a semicolon separated Unicode data file, with comments removed and fields trimmed. */
private fun unicodeRecords(file: String): List<List<String>> =
    Files
        .readAllLines(unicodeFile(file))
        .map { it.substringBefore('#').trim() }
        .filter(String::isNotEmpty)
        .map { line -> line.split(';').map(String::trim) }

private fun unicodeFile(name: String): Path =
    generateSequence(Path.of("").toAbsolutePath()) { it.parent }
        .map { it.resolve("services/protocol/unicode/${PortableUnicodeTables.RELEASE}/$name") }
        .first(Files::exists)
