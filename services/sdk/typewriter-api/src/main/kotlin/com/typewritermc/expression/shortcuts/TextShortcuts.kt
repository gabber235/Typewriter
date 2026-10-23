package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.and
import com.typewritermc.expression.codePoints
import com.typewritermc.expression.codePointsToText
import com.typewritermc.expression.eq
import com.typewritermc.expression.flatten
import com.typewritermc.expression.foldCase
import com.typewritermc.expression.indexOf
import com.typewritermc.expression.join
import com.typewritermc.expression.lastIndexOf
import com.typewritermc.expression.length
import com.typewritermc.expression.let
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.minus
import com.typewritermc.expression.not
import com.typewritermc.expression.plus
import com.typewritermc.expression.rangeExpr
import com.typewritermc.expression.reversed
import com.typewritermc.expression.size
import com.typewritermc.expression.split
import com.typewritermc.expression.substring
import com.typewritermc.expression.titlecase
import com.typewritermc.expression.toByteList
import com.typewritermc.expression.toBytes
import com.typewritermc.expression.toText
import com.typewritermc.expression.trimEnd
import com.typewritermc.expression.trimStart

/*
 * Text shortcuts. Indexes and lengths count code points; whitespace is the portable White_Space set plus U+FEFF of
 * text.trim_start and text.trim_end; a line break is LF, CR, U+2028 or U+2029, and CR LF counts as one.
 */

/** This text without portable whitespace at either end. */
@JvmName("textTrim")
fun <M : MissingPolicy> Expr<String, M>.trim(): Expr<String, M> = trimEnd().trimStart()

/** Whether this text has no code points. */
@JvmName("textIsEmpty")
fun <M : MissingPolicy> Expr<String, M>.isEmpty(): Expr<Boolean, M> = this eq literal("").lift()

/** Whether this text has a code point. */
@JvmName("textIsNotEmpty")
fun <M : MissingPolicy> Expr<String, M>.isNotEmpty(): Expr<Boolean, M> = isEmpty().not()

/** Whether this text is empty or only portable whitespace. */
@JvmName("textIsBlank")
fun <M : MissingPolicy> Expr<String, M>.isBlank(): Expr<Boolean, M> = trimStart().isEmpty()

/** Whether this text has a code point besides portable whitespace. */
@JvmName("textIsNotBlank")
fun <M : MissingPolicy> Expr<String, M>.isNotBlank(): Expr<Boolean, M> = isBlank().not()

/** Whether [other] occurs in this text. Stops at the first occurrence. */
@JvmName("textContains")
fun <M : MissingPolicy> Expr<String, M>.contains(other: Expr<String, M>): Expr<Boolean, M> =
    (indexOf(other, literal(0).lift()) eq literal(-1).lift()).not()

/** Whether [other] occurs in this text. Stops at the first occurrence. */
@JvmName("textContainsRaw")
fun <M : MissingPolicy> Expr<String, M>.contains(other: String): Expr<Boolean, M> = contains(literal(other).lift())

/** Whether this text starts with [prefix]. Only the code points at the start are compared. */
@JvmName("textStartsWith")
fun <M : MissingPolicy> Expr<String, M>.startsWith(prefix: Expr<String, M>): Expr<Boolean, M> =
    lastIndexOf(prefix, literal(0).lift()) eq literal(0).lift()

/** Whether this text starts with [prefix]. Only the code points at the start are compared. */
@JvmName("textStartsWithRaw")
fun <M : MissingPolicy> Expr<String, M>.startsWith(prefix: String): Expr<Boolean, M> = startsWith(literal(prefix).lift())

/** Whether this text ends with [suffix]. Only the code points at the end are compared. */
@JvmName("textEndsWith")
fun <M : MissingPolicy> Expr<String, M>.endsWith(suffix: Expr<String, M>): Expr<Boolean, M> =
    shared(this) { text -> shared(suffix) { ending -> text.endsWithAt(ending, ending.length) } }

/** Whether this text ends with [suffix]. Only the code points at the end are compared. */
@JvmName("textEndsWithRaw")
fun <M : MissingPolicy> Expr<String, M>.endsWith(suffix: String): Expr<Boolean, M> =
    shared(this) { text -> text.endsWithAt(literal(suffix).lift(), literal(suffix.codePointLength).lift()) }

private fun <M : MissingPolicy> Expr<String, M>.endsWithAt(
    suffix: Expr<String, M>,
    suffixLength: Expr<Int, M>,
): Expr<Boolean, M> =
    shared(length - suffixLength) { start ->
        (start gte literal(0).lift()) and (substring(start, length) eq suffix)
    }

/** This text with every occurrence of [oldValue] replaced by [newValue]; fails with empty_separator for "". */
@JvmName("textReplace")
fun <M : MissingPolicy> Expr<String, M>.replace(
    oldValue: Expr<String, M>,
    newValue: Expr<String, M>,
): Expr<String, M> = split(oldValue).join(newValue)

/** This text with every occurrence of [oldValue] replaced by [newValue]. */
@JvmName("textReplaceRaw")
fun <M : MissingPolicy> Expr<String, M>.replace(
    oldValue: String,
    newValue: String,
): Expr<String, M> {
    require(oldValue.isNotEmpty()) { "The replaced text must not be empty." }
    return split(oldValue).join(newValue)
}

/** Whether this text contains a line break. */
fun <M : MissingPolicy> Expr<String, M>.hasLineBreaks(): Expr<Boolean, M> =
    shared(this) { text -> anyOf(*LINE_BREAKS.map { text.contains(it) }.toTypedArray()) }

/** Whether this text has no line break. */
fun <M : MissingPolicy> Expr<String, M>.isSingleLine(): Expr<Boolean, M> = hasLineBreaks().not()

/** The lines of this text, split at every line break; the empty text is one empty line. Ids are positional. */
fun <M : MissingPolicy> Expr<String, M>.lines(): Expr<List<String>, M> =
    LINE_BREAKS.fold(replace("\r\n", "\n")) { text, lineBreak -> if (lineBreak == "\n") text else text.replace(lineBreak, "\n") }
        .split("\n")

/** The number of lines of this text: none for the empty text, otherwise one more than its line breaks. */
fun <M : MissingPolicy> Expr<String, M>.lineCount(): Expr<Int, M> =
    shared(this) { text -> choose(text.isEmpty(), literal(0).lift(), text.lines().size) }

/** This text followed by [other]. */
@JvmName("textPlus")
operator fun <M : MissingPolicy> Expr<String, M>.plus(other: Expr<String, M>): Expr<String, M> = concat(this, other)

/** This text followed by [other]. */
@JvmName("textPlusRaw")
operator fun <M : MissingPolicy> Expr<String, M>.plus(other: String): Expr<String, M> = concat(this, literal(other).lift())

/** The [parts] joined without separator. */
fun <M : MissingPolicy> concat(vararg parts: Expr<String, M>): Expr<String, M> =
    when (parts.size) {
        0 -> literal("").lift()
        1 -> parts.single()
        else -> listExpr(*parts).join("")
    }

/**
 * The [pattern] with every placeholder `{n}` replaced by the canonical text (value.to_text) of [arguments] at n.
 * Other braces stay literal. An argument that appears more than once evaluates once.
 */
fun <M : MissingPolicy> template(
    pattern: String,
    vararg arguments: Expr<*, M>,
): Expr<String, M> {
    val pieces = TemplatePiece.parse(pattern)
    pieces.filterIsInstance<TemplatePiece.Argument>().forEach { argument ->
        require(argument.index < arguments.size) { "The template refers to argument ${argument.index} of ${arguments.size}." }
    }
    val repeated =
        pieces
            .filterIsInstance<TemplatePiece.Argument>()
            .groupingBy { it.index }
            .eachCount()
            .filterValues { it > 1 }
            .keys
            .sorted()
    return bindArguments(arguments.map { it.toText() }, repeated) { texts ->
        concat(
            *pieces
                .map { piece ->
                    when (piece) {
                        is TemplatePiece.Text -> literal(piece.text).lift<String, M>()
                        is TemplatePiece.Argument -> texts[piece.index]
                    }
                }.toTypedArray(),
        )
    }
}

private fun <M : MissingPolicy> bindArguments(
    texts: List<Expr<String, M>>,
    repeated: List<Int>,
    body: (List<Expr<String, M>>) -> Expr<String, M>,
): Expr<String, M> =
    if (repeated.isEmpty()) {
        body(texts)
    } else {
        val index = repeated.first()
        shared(texts[index]) { bound ->
            bindArguments(texts.toMutableList().also { it[index] = bound }, repeated.drop(1), body)
        }
    }

private sealed interface TemplatePiece {
    data class Text(
        val text: String,
    ) : TemplatePiece

    data class Argument(
        val index: Int,
    ) : TemplatePiece

    companion object {
        private val PLACEHOLDER = Regex("""\{(\d+)\}""")

        fun parse(pattern: String): List<TemplatePiece> =
            buildList {
                var copied = 0
                PLACEHOLDER.findAll(pattern).forEach { match ->
                    if (match.range.first > copied) add(Text(pattern.substring(copied, match.range.first)))
                    add(Argument(match.groupValues[1].toInt()))
                    copied = match.range.last + 1
                }
                if (copied < pattern.length) add(Text(pattern.substring(copied)))
            }
    }
}

/** This text [count] times in a row; empty when [count] is not positive. */
@JvmName("textRepeat")
fun <M : MissingPolicy> Expr<String, M>.repeat(count: Expr<Int, M>): Expr<String, MayBeMissing> =
    let(this) { text -> rangeExpr(literal(0).lift(), count, literal(1).lift()).map { text }.join("") }

/** This text [count] times in a row; empty when [count] is not positive. */
@JvmName("textRepeatRaw")
fun <M : MissingPolicy> Expr<String, M>.repeat(count: Int): Expr<String, MayBeMissing> = repeat(literal(count).lift())

/** This text preceded by [padChar] until it has [length] code points; unchanged when it is long enough. */
@JvmName("textPadStart")
fun <M : MissingPolicy> Expr<String, M>.padStart(
    length: Expr<Int, M>,
    padChar: Char = ' ',
): Expr<String, MayBeMissing> = let(this) { text -> literal(padChar.toString()).repeat(length - text.length) + text }

/** This text preceded by [padChar] until it has [length] code points; unchanged when it is long enough. */
@JvmName("textPadStartRaw")
fun <M : MissingPolicy> Expr<String, M>.padStart(
    length: Int,
    padChar: Char = ' ',
): Expr<String, MayBeMissing> = padStart(literal(length).lift(), padChar)

/** This text followed by [padChar] until it has [length] code points; unchanged when it is long enough. */
@JvmName("textPadEnd")
fun <M : MissingPolicy> Expr<String, M>.padEnd(
    length: Expr<Int, M>,
    padChar: Char = ' ',
): Expr<String, MayBeMissing> = let(this) { text -> text + literal(padChar.toString()).repeat(length - text.length) }

/** This text followed by [padChar] until it has [length] code points; unchanged when it is long enough. */
@JvmName("textPadEndRaw")
fun <M : MissingPolicy> Expr<String, M>.padEnd(
    length: Int,
    padChar: Char = ' ',
): Expr<String, MayBeMissing> = padEnd(literal(length).lift(), padChar)

/** The code points of this text in reverse order. */
@JvmName("textReversed")
fun <M : MissingPolicy> Expr<String, M>.reversed(): Expr<String, M> = codePoints().reversed().codePointsToText()

/** The first [count] code points, or the whole text when it is shorter; fails with substring_range when negative. */
@JvmName("textTake")
fun <M : MissingPolicy> Expr<String, M>.take(count: Expr<Int, M>): Expr<String, M> =
    shared(this) { text -> text.substring(literal(0).lift(), min(count, text.length)) }

/** The first [count] code points, or the whole text when it is shorter. */
@JvmName("textTakeRaw")
fun <M : MissingPolicy> Expr<String, M>.take(count: Int): Expr<String, M> = take(literal(count).lift())

/** This text without its first [count] code points; empty when it is shorter. */
@JvmName("textDrop")
fun <M : MissingPolicy> Expr<String, M>.drop(count: Expr<Int, M>): Expr<String, M> =
    shared(this) { text -> shared(text.length) { length -> text.substring(min(count, length), length) } }

/** This text without its first [count] code points; empty when it is shorter. */
@JvmName("textDropRaw")
fun <M : MissingPolicy> Expr<String, M>.drop(count: Int): Expr<String, M> = drop(literal(count).lift())

/** The last [count] code points, or the whole text when it is shorter. */
@JvmName("textTakeLast")
fun <M : MissingPolicy> Expr<String, M>.takeLast(count: Expr<Int, M>): Expr<String, M> =
    shared(this) { text -> shared(text.length) { length -> text.substring(length - min(count, length), length) } }

/** The last [count] code points, or the whole text when it is shorter. */
@JvmName("textTakeLastRaw")
fun <M : MissingPolicy> Expr<String, M>.takeLast(count: Int): Expr<String, M> = takeLast(literal(count).lift())

/** This text without its last [count] code points; empty when it is shorter. */
@JvmName("textDropLast")
fun <M : MissingPolicy> Expr<String, M>.dropLast(count: Expr<Int, M>): Expr<String, M> =
    shared(this) { text -> shared(text.length) { length -> text.substring(literal(0).lift(), length - min(count, length)) } }

/** This text without its last [count] code points; empty when it is shorter. */
@JvmName("textDropLastRaw")
fun <M : MissingPolicy> Expr<String, M>.dropLast(count: Int): Expr<String, M> = dropLast(literal(count).lift())

/** This text without the leading [prefix], or unchanged when it does not start with it. */
fun <M : MissingPolicy> Expr<String, M>.removePrefix(prefix: String): Expr<String, M> =
    shared(this) { text -> choose(text.startsWith(prefix), text.substring(literal(prefix.codePointLength).lift(), text.length), text) }

/** This text without the trailing [suffix], or unchanged when it does not end with it. */
fun <M : MissingPolicy> Expr<String, M>.removeSuffix(suffix: String): Expr<String, M> =
    shared(this) { text ->
        choose(text.endsWith(suffix), text.substring(literal(0).lift(), text.length - literal(suffix.codePointLength).lift()), text)
    }

/** The text before the first [delimiter], or the whole text when it has none. */
fun <M : MissingPolicy> Expr<String, M>.substringBefore(delimiter: String): Expr<String, M> =
    shared(this) { text ->
        shared(text.indexOf(delimiter, 0)) { index -> choose(index eq literal(-1).lift(), text, text.substring(literal(0).lift(), index)) }
    }

/** The text after the first [delimiter], or the whole text when it has none. */
fun <M : MissingPolicy> Expr<String, M>.substringAfter(delimiter: String): Expr<String, M> =
    shared(this) { text ->
        shared(text.indexOf(delimiter, 0)) { index ->
            choose(index eq literal(-1).lift(), text, text.substring(index + delimiter.codePointLength, text.length))
        }
    }

/** The text before the last [delimiter], or the whole text when it has none. */
fun <M : MissingPolicy> Expr<String, M>.substringBeforeLast(delimiter: String): Expr<String, M> =
    shared(this) { text ->
        shared(text.lastIndexOf(literal(delimiter).lift(), text.length)) { index ->
            choose(index eq literal(-1).lift(), text, text.substring(literal(0).lift(), index))
        }
    }

/** The text after the last [delimiter], or the whole text when it has none. */
fun <M : MissingPolicy> Expr<String, M>.substringAfterLast(delimiter: String): Expr<String, M> =
    shared(this) { text ->
        shared(text.lastIndexOf(literal(delimiter).lift(), text.length)) { index ->
            choose(index eq literal(-1).lift(), text, text.substring(index + delimiter.codePointLength, text.length))
        }
    }

/** This text with its first code point titlecased, like Kotlin's replaceFirstChar { it.titlecase() }. */
fun <M : MissingPolicy> Expr<String, M>.capitalize(): Expr<String, M> =
    shared(this) { text ->
        choose(text.isEmpty(), text, text.substring(0, 1).titlecase() + text.substring(literal(1).lift(), text.length))
    }

/** Whether this text equals [other] after full Unicode case folding. */
fun <M : MissingPolicy> Expr<String, M>.equalsIgnoreCase(other: Expr<String, M>): Expr<Boolean, M> =
    foldCase() eq other.foldCase()

/** Whether this text equals [other] after full Unicode case folding. */
@JvmName("equalsIgnoreCaseRaw")
fun <M : MissingPolicy> Expr<String, M>.equalsIgnoreCase(other: String): Expr<Boolean, M> = equalsIgnoreCase(literal(other).lift())

/** The number of non overlapping occurrences of [needle]; fails with empty_separator for "". */
fun <M : MissingPolicy> Expr<String, M>.countOf(needle: String): Expr<Int, M> {
    require(needle.isNotEmpty()) { "The counted text must not be empty." }
    return split(needle).size - 1
}

/**
 * This text when it has at most [maxLength] code points, otherwise its start followed by [ellipsis] so that the result
 * has exactly [maxLength] code points.
 */
fun <M : MissingPolicy> Expr<String, M>.truncate(
    maxLength: Int,
    ellipsis: String = "…",
): Expr<String, M> {
    require(maxLength >= ellipsis.codePointLength) { "The maximum length must leave room for the ellipsis." }
    return shared(this) { text ->
        choose(text.length lte maxLength, text, text.take(maxLength - ellipsis.codePointLength) + ellipsis)
    }
}

/** The bytes as lowercase hexadecimal text, two digits per byte. */
fun <M : MissingPolicy> Expr<ByteArray, M>.toHexString(): Expr<String, MayBeMissing> =
    toByteList().map { hexDigit(this shr 4) + hexDigit(this and 15) }.join("")

private fun <M : MissingPolicy> hexDigit(value: Expr<Int, M>): Expr<String, M> =
    shared(value) { digit -> literal("0123456789abcdef").lift<String, M>().substring(digit, digit + 1) }

/** The UTF-8 encoding of this text. */
fun <M : MissingPolicy> Expr<String, M>.encodeToByteArray(): Expr<ByteArray, MayBeMissing> =
    codePoints()
        .map { utf8Bytes(this) }
        .flatten()
        .toBytes()

private fun utf8Bytes(point: Expr<Int, MayBeMissing>): Expr<List<Int>, MayBeMissing> {
    fun continuation(shift: Int) = ((point shr shift) and 0x3F) or 0x80
    return choose(
        point lt 0x80,
        listExpr(point),
        choose(
            point lt 0x800,
            listExpr((point shr 6) or 0xC0, continuation(0)),
            choose(
                point lt 0x10000,
                listExpr((point shr 12) or 0xE0, continuation(6), continuation(0)),
                listExpr((point shr 18) or 0xF0, continuation(12), continuation(6), continuation(0)),
            ),
        ),
    )
}

private val String.codePointLength: Int get() = codePointCount(0, length)

private val LINE_BREAKS = listOf("\n", "\r", " ", " ")
