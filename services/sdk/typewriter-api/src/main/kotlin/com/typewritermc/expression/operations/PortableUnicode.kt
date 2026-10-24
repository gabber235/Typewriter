package com.typewritermc.expression.operations

import java.util.Arrays

/**
 * Unicode text semantics of the portable expression language: case mapping, case folding, normalization and white
 * space, all from the pinned release in [PortableUnicodeTables]. It never consults the JVM's case, character property
 * or normalization APIs, so Realm produces exactly what the panel's `portable_unicode.dart` produces for every input.
 *
 * Strings are processed by code point; an unpaired surrogate is a code point without mappings. Case operations apply
 * the default, untailored mappings of the Unicode Standard (section 3.13): no locale changes them, and the only
 * conditional mapping is Final_Sigma. Tables are decoded once, at first use.
 */
internal object PortableUnicode {
    /** Full lowercase mapping; U+03A3 maps to final sigma U+03C2 where the Final_Sigma condition holds. */
    fun lower(value: String): String {
        val codePoints = value.codePoints().toArray()
        return buildString(value.length) {
            codePoints.indices.forEach { index -> appendLower(codePoints, index) }
        }
    }

    /** Full uppercase mapping, such as `ß` to `SS`. */
    fun upper(value: String): String = mapCodePoints(value) { codePoint -> CaseTables.upper(codePoint) }

    /**
     * Titlecases each word: the first code point of the text and every code point after a [isWhiteSpace] code point
     * take their full titlecase mapping, and all others their full lowercase mapping, including Final_Sigma.
     */
    fun title(value: String): String {
        val codePoints = value.codePoints().toArray()
        return buildString(value.length) {
            codePoints.indices.forEach { index ->
                if (index == 0 || isWhiteSpace(codePoints[index - 1])) {
                    appendCodePoints(CaseTables.title(codePoints[index]))
                } else {
                    appendLower(codePoints, index)
                }
            }
        }
    }

    /** Full case folding (CaseFolding.txt statuses C and F), for caseless comparison. */
    fun foldCase(value: String): String = mapCodePoints(value) { codePoint -> CaseTables.fold(codePoint) }

    /**
     * Normalizes per UAX #15: NFD without [compatibility] or [compose], NFC with [compose], NFKD with [compatibility],
     * and NFKC with both. Decomposition is full and recursive, combining marks are put in canonical order, and
     * composition skips fully excluded composites. Hangul syllables decompose and compose algorithmically.
     */
    fun normalize(
        value: String,
        compatibility: Boolean,
        compose: Boolean,
    ): String {
        val buffer = IntBuffer(value.length)
        value.codePoints().forEach { codePoint -> NormalizationTables.decompose(codePoint, compatibility, buffer) }
        NormalizationTables.orderCanonically(buffer)
        if (compose) NormalizationTables.compose(buffer)
        return buildString(buffer.size) { (0 until buffer.size).forEach { appendCodePoint(buffer[it]) } }
    }

    /** Whether [codePoint] has the White_Space property or is U+FEFF ZERO WIDTH NO-BREAK SPACE. */
    fun isWhiteSpace(codePoint: Int): Boolean = codePoint in CaseTables.whiteSpace

    /** Removes the leading [isWhiteSpace] code points. */
    fun trimStart(value: String): String {
        var index = 0
        while (index < value.length) {
            val codePoint = value.codePointAt(index)
            if (!isWhiteSpace(codePoint)) break
            index += Character.charCount(codePoint)
        }
        return value.substring(index)
    }

    /** Removes the trailing [isWhiteSpace] code points. */
    fun trimEnd(value: String): String {
        var end = value.length
        while (end > 0) {
            val codePoint = value.codePointBefore(end)
            if (!isWhiteSpace(codePoint)) break
            end -= Character.charCount(codePoint)
        }
        return value.substring(0, end)
    }

    private fun mapCodePoints(
        value: String,
        mapping: (Int) -> IntArray,
    ): String =
        buildString(value.length) {
            value.codePoints().forEach { codePoint -> appendCodePoints(mapping(codePoint)) }
        }

    private fun StringBuilder.appendLower(
        codePoints: IntArray,
        index: Int,
    ) {
        val codePoint = codePoints[index]
        val finalSigma = CaseTables.finalSigmaLower[codePoint]
        appendCodePoints(
            if (finalSigma != null && isFinalSigma(codePoints, index)) finalSigma else CaseTables.lower(codePoint),
        )
    }

    /**
     * The Final_Sigma condition: a cased code point, then only case ignorable ones, precede [index], and no case
     * ignorable run followed by a cased code point follows it. A code point that is both cased and case ignorable
     * counts as cased, so it satisfies the preceding part and fails the following part.
     */
    private fun isFinalSigma(
        codePoints: IntArray,
        index: Int,
    ): Boolean {
        var before = index - 1
        while (true) {
            if (before < 0) return false
            val codePoint = codePoints[before]
            if (codePoint in CaseTables.cased) break
            if (codePoint !in CaseTables.caseIgnorable) return false
            before--
        }
        for (after in index + 1 until codePoints.size) {
            val codePoint = codePoints[after]
            if (codePoint in CaseTables.cased) return false
            if (codePoint !in CaseTables.caseIgnorable) return true
        }
        return true
    }

    private fun StringBuilder.appendCodePoints(codePoints: IntArray) {
        codePoints.forEach(::appendCodePoint)
    }
}

/** The decoded case and white space tables. */
private object CaseTables {
    val whiteSpace = RangeSet(PortableUnicodeTables.whiteSpace())
    val cased = RangeSet(PortableUnicodeTables.cased())
    val caseIgnorable = RangeSet(PortableUnicodeTables.caseIgnorable())
    val finalSigmaLower = multiMap(PortableUnicodeTables.finalSigmaLower())
    private val simpleUpper = CaseRuns(PortableUnicodeTables.simpleUpper())
    private val simpleLower = CaseRuns(PortableUnicodeTables.simpleLower())
    private val simpleTitle = CaseRuns(PortableUnicodeTables.simpleTitle())
    private val simpleFold = CaseRuns(PortableUnicodeTables.simpleFold())
    private val specialUpper = multiMap(PortableUnicodeTables.specialUpper())
    private val specialLower = multiMap(PortableUnicodeTables.specialLower())
    private val specialTitle = multiMap(PortableUnicodeTables.specialTitle())
    private val fullFold = multiMap(PortableUnicodeTables.fullFold())

    fun upper(codePoint: Int): IntArray = specialUpper[codePoint] ?: intArrayOf(simpleUpper.map(codePoint))

    fun lower(codePoint: Int): IntArray = specialLower[codePoint] ?: intArrayOf(simpleLower.map(codePoint))

    fun title(codePoint: Int): IntArray = specialTitle[codePoint] ?: intArrayOf(simpleTitle.map(codePoint))

    fun fold(codePoint: Int): IntArray = fullFold[codePoint] ?: intArrayOf(simpleFold.map(codePoint))
}

/** The decoded normalization tables and the UAX #15 steps that use them. */
private object NormalizationTables {
    private const val S_BASE = 0xAC00
    private const val L_BASE = 0x1100
    private const val V_BASE = 0x1161
    private const val T_BASE = 0x11A7
    private const val L_COUNT = 19
    private const val V_COUNT = 21
    private const val T_COUNT = 28
    private const val N_COUNT = V_COUNT * T_COUNT
    private const val S_COUNT = L_COUNT * N_COUNT

    private val combiningClasses = ClassRuns(PortableUnicodeTables.combiningClasses())
    private val canonical = HashMap<Int, IntArray>()
    private val compatibility = HashMap<Int, IntArray>()
    private val composites = HashMap<Long, Int>()

    init {
        val reader = TableReader(PortableUnicodeTables.decompositions())
        var codePoint = 0
        var previous = intArrayOf(0)
        while (reader.hasNext) {
            codePoint += reader.next()
            val header = reader.next()
            val mapping = IntArray(header shr 1)
            for (index in mapping.indices) {
                mapping[index] = previous[minOf(index, previous.lastIndex)] + reader.nextSigned()
            }
            (if (header and 1 == 1) compatibility else canonical)[codePoint] = mapping
            previous = mapping
        }
        val composite = TableReader(PortableUnicodeTables.primaryComposites())
        var primary = 0
        while (composite.hasNext) {
            primary += composite.next()
            val pair = canonical.getValue(primary)
            composites[pairKey(pair[0], pair[1])] = primary
        }
    }

    fun combiningClass(codePoint: Int): Int = combiningClasses.value(codePoint)

    /** Appends the full decomposition of [codePoint]. */
    fun decompose(
        codePoint: Int,
        compatible: Boolean,
        output: IntBuffer,
    ) {
        val syllable = codePoint - S_BASE
        if (syllable in 0 until S_COUNT) {
            output.add(L_BASE + syllable / N_COUNT)
            output.add(V_BASE + syllable % N_COUNT / T_COUNT)
            if (syllable % T_COUNT != 0) output.add(T_BASE + syllable % T_COUNT)
            return
        }
        val mapping = canonical[codePoint] ?: compatibility[codePoint]?.takeIf { compatible }
        if (mapping == null) {
            output.add(codePoint)
        } else {
            mapping.forEach { decompose(it, compatible, output) }
        }
    }

    /** Stably sorts every run of nonzero combining classes by class. */
    fun orderCanonically(buffer: IntBuffer) {
        for (index in 1 until buffer.size) {
            val codePoint = buffer[index]
            val combiningClass = combiningClass(codePoint)
            if (combiningClass == 0) continue
            var target = index
            while (target > 0 && combiningClass(buffer[target - 1]) > combiningClass) {
                buffer[target] = buffer[target - 1]
                target--
            }
            buffer[target] = codePoint
        }
    }

    /** Canonically composes a decomposed, canonically ordered buffer in place. */
    fun compose(buffer: IntBuffer) {
        if (buffer.size == 0) return
        var starter = 0
        var lastClass = if (combiningClass(buffer[0]) == 0) 0 else Int.MAX_VALUE
        var size = 1
        for (index in 1 until buffer.size) {
            val codePoint = buffer[index]
            val combiningClass = combiningClass(codePoint)
            val composite = composePair(buffer[starter], codePoint)
            if (composite >= 0 && (lastClass == 0 || lastClass < combiningClass)) {
                buffer[starter] = composite
                continue
            }
            if (combiningClass == 0) starter = size
            lastClass = combiningClass
            buffer[size++] = codePoint
        }
        buffer.size = size
    }

    /** The primary composite of [first] and [second], or -1. */
    private fun composePair(
        first: Int,
        second: Int,
    ): Int {
        val leading = first - L_BASE
        val vowel = second - V_BASE
        if (leading in 0 until L_COUNT && vowel in 0 until V_COUNT) return S_BASE + (leading * V_COUNT + vowel) * T_COUNT
        val syllable = first - S_BASE
        val trailing = second - T_BASE
        if (syllable in 0 until S_COUNT && syllable % T_COUNT == 0 && trailing in 1 until T_COUNT) return first + trailing
        return composites[pairKey(first, second)] ?: -1
    }

    private fun pairKey(
        first: Int,
        second: Int,
    ): Long = first.toLong() * CODE_POINT_LIMIT + second
}

private const val CODE_POINT_LIMIT = 0x110000

/** A growable array of code points or table values. */
private class IntBuffer(
    capacity: Int,
) {
    private var values = IntArray(maxOf(capacity, 4))
    var size = 0

    operator fun get(index: Int): Int = values[index]

    operator fun set(
        index: Int,
        value: Int,
    ) {
        values[index] = value
    }

    fun add(value: Int) {
        if (size == values.size) values = values.copyOf(size * 2)
        values[size++] = value
    }

    fun toIntArray(): IntArray = values.copyOf(size)
}

/** Reads the unsigned and zigzag signed numbers of one table. */
private class TableReader(
    private val data: String,
) {
    private var index = 0

    val hasNext: Boolean get() = index < data.length

    fun next(): Int {
        var value = 0
        while (true) {
            val digit = DIGITS[data[index++].code]
            if (digit < PortableUnicodeTables.TERMINAL_DIGITS) return value * PortableUnicodeTables.TERMINAL_DIGITS + digit
            value = value * CONTINUATION_DIGITS + digit - PortableUnicodeTables.TERMINAL_DIGITS
        }
    }

    fun nextSigned(): Int {
        val value = next()
        return if (value and 1 == 0) value ushr 1 else -(value ushr 1) - 1
    }

    private companion object {
        val CONTINUATION_DIGITS = PortableUnicodeTables.ALPHABET.length - PortableUnicodeTables.TERMINAL_DIGITS
        val DIGITS =
            IntArray(128) { -1 }.also { digits ->
                PortableUnicodeTables.ALPHABET.forEachIndexed { value, character -> digits[character.code] = value }
            }
    }
}

/** The greatest index whose start is at most [codePoint], or -1. */
private fun IntArray.floorIndex(codePoint: Int): Int {
    val found = Arrays.binarySearch(this, codePoint)
    return if (found >= 0) found else -found - 2
}

/** A set of disjoint, ascending code point ranges. */
private class RangeSet(
    data: String,
) {
    private val starts: IntArray
    private val ends: IntArray

    init {
        val reader = TableReader(data)
        val starts = IntBuffer(64)
        val ends = IntBuffer(64)
        var end = 0
        while (reader.hasNext) {
            val start = end + reader.next()
            end = start + reader.next()
            starts.add(start)
            ends.add(end)
        }
        this.starts = starts.toIntArray()
        this.ends = ends.toIntArray()
    }

    operator fun contains(codePoint: Int): Boolean {
        val index = starts.floorIndex(codePoint)
        return index >= 0 && codePoint < ends[index]
    }
}

/** Simple case mappings as runs of code points that share a delta. */
private class CaseRuns(
    data: String,
) {
    private val starts: IntArray
    private val ends: IntArray
    private val strides: IntArray
    private val deltas: IntArray

    init {
        val reader = TableReader(data)
        val starts = IntBuffer(256)
        val ends = IntBuffer(256)
        val strides = IntBuffer(256)
        val deltas = IntBuffer(256)
        var end = 0
        while (reader.hasNext) {
            val start = end + reader.next()
            val shape = reader.next()
            val stride = (shape and 1) + 1
            end = start + (shape shr 1) * stride + 1
            starts.add(start)
            ends.add(end)
            strides.add(stride)
            deltas.add(reader.nextSigned())
        }
        this.starts = starts.toIntArray()
        this.ends = ends.toIntArray()
        this.strides = strides.toIntArray()
        this.deltas = deltas.toIntArray()
    }

    /** The mapping of [codePoint], or [codePoint] itself when it has none. */
    fun map(codePoint: Int): Int {
        val index = starts.floorIndex(codePoint)
        if (index < 0 || codePoint >= ends[index] || (codePoint - starts[index]) % strides[index] != 0) return codePoint
        return codePoint + deltas[index]
    }
}

/** Nonzero canonical combining classes as runs of equal class. */
private class ClassRuns(
    data: String,
) {
    private val starts: IntArray
    private val ends: IntArray
    private val values: IntArray

    init {
        val reader = TableReader(data)
        val starts = IntBuffer(1024)
        val ends = IntBuffer(1024)
        val values = IntBuffer(1024)
        var end = 0
        while (reader.hasNext) {
            val start = end + reader.next()
            end = start + reader.next()
            starts.add(start)
            ends.add(end)
            values.add(reader.next())
        }
        this.starts = starts.toIntArray()
        this.ends = ends.toIntArray()
        this.values = values.toIntArray()
    }

    fun value(codePoint: Int): Int {
        val index = starts.floorIndex(codePoint)
        return if (index >= 0 && codePoint < ends[index]) values[index] else 0
    }
}

/** Decodes a multi map table: code points with a mapping of several code points. */
private fun multiMap(data: String): Map<Int, IntArray> {
    val reader = TableReader(data)
    val mappings = HashMap<Int, IntArray>()
    var codePoint = 0
    while (reader.hasNext) {
        codePoint += reader.next()
        mappings[codePoint] = IntArray(reader.next()) { reader.next() }
    }
    return mappings
}
