package com.typewritermc.expression

import java.util.ArrayDeque

internal class PortableRegexMatcher private constructor(
    private val instructions: List<RegexInstruction>,
    private val start: Int,
    val groupCount: Int,
) {
    fun containsMatchIn(
        input: String,
        consumeStep: () -> Unit,
    ): Boolean = find(input, consumeStep) != null

    fun matches(
        input: String,
        consumeStep: () -> Unit,
    ): Boolean {
        val codePoints = input.codePoints().toArray()
        val captures = IntArray((groupCount + 1) * 2) { UNSET_CAPTURE }
        var current = closure(listOf(MachineThread(start, captures)), 0, codePoints.size, consumeStep)
        codePoints.forEachIndexed { index, codePoint ->
            current = advance(current, codePoint, index + 1, codePoints.size, consumeStep)
        }
        return current.firstOrNull { instructions[it.instruction] is RegexInstruction.Match } != null
    }

    fun find(
        input: String,
        consumeStep: () -> Unit,
    ): PortableRegexMatch? = find(input.codePoints().toArray(), 0, consumeStep)

    fun replace(
        input: String,
        replacement: String,
        consumeStep: () -> Unit,
    ): String {
        val codePoints = input.codePoints().toArray()
        val output = StringBuilder(input.length)
        var copiedUntil = 0
        var searchFrom = 0
        while (searchFrom <= codePoints.size) {
            val match = find(codePoints, searchFrom, consumeStep) ?: break
            output.appendCodePoints(codePoints, copiedUntil, match.start, consumeStep)
            output.appendReplacement(replacement, codePoints, match.captures, groupCount, consumeStep)
            copiedUntil = match.end
            searchFrom =
                if (match.start == match.end) {
                    if (match.end == codePoints.size) codePoints.size + 1 else match.end + 1
                } else {
                    match.end
                }
        }
        output.appendCodePoints(codePoints, copiedUntil, codePoints.size, consumeStep)
        return output.toString()
    }

    private fun find(
        codePoints: IntArray,
        fromIndex: Int,
        consumeStep: () -> Unit,
    ): PortableRegexMatch? {
        val emptyCaptures = IntArray((groupCount + 1) * 2) { UNSET_CAPTURE }
        var current = emptyList<MachineThread>()
        var best: PortableRegexMatch? = null
        for (position in fromIndex..codePoints.size) {
            consumeStep()
            val seeds =
                if (best == null) {
                    current + MachineThread(start, emptyCaptures, position)
                } else {
                    current
                }
            current = closure(seeds, position, codePoints.size, consumeStep)
            val matchIndex = current.indexOfFirst { instructions[it.instruction] is RegexInstruction.Match }
            if (matchIndex >= 0) {
                best = PortableRegexMatch(current[matchIndex].captures)
                current = current.take(matchIndex)
                if (current.isEmpty()) return best
            }
            if (position == codePoints.size) break
            current = consume(current, codePoints[position], consumeStep)
        }
        return best
    }

    private fun advance(
        current: List<MachineThread>,
        codePoint: Int,
        position: Int,
        length: Int,
        consumeStep: () -> Unit,
    ): List<MachineThread> = closure(consume(current, codePoint, consumeStep), position, length, consumeStep)

    private fun consume(
        current: List<MachineThread>,
        codePoint: Int,
        consumeStep: () -> Unit,
    ): List<MachineThread> =
        buildList {
            current.forEach { thread ->
                when (val instruction = instructions[thread.instruction]) {
                    is RegexInstruction.Character -> {
                        consumeStep()
                        if (instruction.predicate.matches(codePoint)) {
                            add(thread.copy(instruction = instruction.next))
                        }
                    }

                    is RegexInstruction.Repeat -> {
                        consumeStep()
                        if (instruction.predicate.matches(codePoint)) {
                            val nextCount = thread.repeatCount + 1
                            add(
                                thread.copy(
                                    repeatInstruction = thread.instruction,
                                    repeatCount = if (instruction.maximum == null) minOf(nextCount, instruction.minimum) else nextCount,
                                ),
                            )
                        }
                    }

                    else -> {}
                }
            }
        }

    private fun closure(
        seeds: List<MachineThread>,
        position: Int,
        length: Int,
        consumeStep: () -> Unit,
    ): List<MachineThread> {
        val result = mutableListOf<MachineThread>()
        val pending = ArrayDeque(seeds)
        val seen = mutableSetOf<ThreadIdentity>()
        while (pending.isNotEmpty()) {
            val thread = pending.removeFirst()
            val identity = ThreadIdentity(thread.instruction, thread.repeatInstruction, thread.repeatCount)
            if (!seen.add(identity)) continue
            consumeStep()
            when (val instruction = instructions[thread.instruction]) {
                is RegexInstruction.Jump -> {
                    pending.addFirst(thread.copy(instruction = instruction.next))
                }

                is RegexInstruction.Split -> {
                    pending.addFirst(thread.copy(instruction = instruction.alternative))
                    pending.addFirst(thread.copy(instruction = instruction.preferred))
                }

                is RegexInstruction.Save -> {
                    val captures = thread.captures.copyOf()
                    captures[instruction.slot] = position
                    pending.addFirst(thread.copy(instruction = instruction.next, captures = captures))
                }

                is RegexInstruction.Start -> {
                    if (position == 0) pending.addFirst(thread.copy(instruction = instruction.next))
                }

                is RegexInstruction.End -> {
                    if (position == length) pending.addFirst(thread.copy(instruction = instruction.next))
                }

                is RegexInstruction.Repeat -> {
                    val count = if (thread.repeatInstruction == thread.instruction) thread.repeatCount else 0
                    if (instruction.maximum == null || count < instruction.maximum) result += thread
                    if (count >= instruction.minimum) {
                        pending.addFirst(
                            thread.copy(
                                instruction = instruction.next,
                                repeatInstruction = NO_REPEAT,
                                repeatCount = 0,
                            ),
                        )
                    }
                }

                is RegexInstruction.Character, RegexInstruction.Match -> {
                    result += thread
                }
            }
        }
        return result
    }

    companion object {
        fun compile(pattern: String): PortableRegexMatcher {
            val parser = PortableRegexParser(pattern)
            val parsed = parser.parse()
            val compiler = PortableRegexCompiler(MAX_PROGRAM_SIZE)
            val program = compiler.finish(parsed)
            return PortableRegexMatcher(program.instructions, program.start, parser.groupCount)
        }
    }
}

internal class PortableRegexMatch internal constructor(
    internal val captures: IntArray,
) {
    val start: Int
        get() = captures[0]

    val end: Int
        get() = captures[1]

    fun group(
        input: String,
        index: Int,
    ): String? {
        val start = captures.getOrNull(index * 2) ?: return null
        val end = captures.getOrNull(index * 2 + 1) ?: return null
        if (start == UNSET_CAPTURE || end == UNSET_CAPTURE) return null
        val startOffset = input.offsetByCodePoints(0, start)
        val endOffset = input.offsetByCodePoints(0, end)
        return input.substring(startOffset, endOffset)
    }
}

internal class PortableRegexCompileFailure(
    message: String,
) : IllegalArgumentException(message)

private data class MachineThread(
    val instruction: Int,
    val captures: IntArray,
    val start: Int = 0,
    val repeatInstruction: Int = NO_REPEAT,
    val repeatCount: Int = 0,
)

private data class ThreadIdentity(
    val instruction: Int,
    val repeatInstruction: Int,
    val repeatCount: Int,
)

private sealed interface RegexInstruction {
    data class Jump(
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data class Character(
        val predicate: CodePointPredicate,
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data class Repeat(
        val predicate: CodePointPredicate,
        val minimum: Int,
        val maximum: Int?,
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data class Split(
        var preferred: Int = UNPATCHED,
        var alternative: Int = UNPATCHED,
    ) : RegexInstruction

    data class Save(
        val slot: Int,
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data class Start(
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data class End(
        var next: Int = UNPATCHED,
    ) : RegexInstruction

    data object Match : RegexInstruction
}

private fun interface CodePointPredicate {
    fun matches(codePoint: Int): Boolean
}

private sealed interface ParsedRegex {
    data object Empty : ParsedRegex

    data class Character(
        val predicate: CodePointPredicate,
    ) : ParsedRegex

    data object Start : ParsedRegex

    data object End : ParsedRegex

    data class Sequence(
        val values: List<ParsedRegex>,
    ) : ParsedRegex

    data class Alternate(
        val values: List<ParsedRegex>,
    ) : ParsedRegex

    data class Group(
        val index: Int,
        val value: ParsedRegex,
    ) : ParsedRegex

    data class Repeat(
        val value: Character,
        val minimum: Int,
        val maximum: Int?,
    ) : ParsedRegex
}

private class PortableRegexParser(
    private val pattern: String,
) {
    private var index = 0
    var groupCount = 0
        private set

    fun parse(): ParsedRegex {
        val result = alternative()
        if (index != pattern.length) fail("The regular expression contains an unexpected closing group.")
        return result
    }

    private fun alternative(): ParsedRegex {
        val choices = mutableListOf(sequence())
        while (peek() == '|') {
            index += 1
            choices += sequence()
        }
        return if (choices.size == 1) choices.single() else ParsedRegex.Alternate(choices)
    }

    private fun sequence(): ParsedRegex {
        val values = mutableListOf<ParsedRegex>()
        while (index < pattern.length && peek() != ')' && peek() != '|') values += quantified()
        return when (values.size) {
            0 -> ParsedRegex.Empty
            1 -> values.single()
            else -> ParsedRegex.Sequence(values)
        }
    }

    private fun quantified(): ParsedRegex {
        val value = atom()
        val marker = peek()
        val bounds =
            when (marker) {
                '*' -> 0 to null
                '+' -> 1 to null
                '?' -> 0 to 1
                '{' -> repetitionBounds()
                else -> return value
            }
        if (marker != '{') index += 1
        val character = value as? ParsedRegex.Character ?: fail("Only character atoms can be repeated.")
        return ParsedRegex.Repeat(character, bounds.first, bounds.second)
    }

    private fun repetitionBounds(): Pair<Int, Int?> {
        val end = pattern.indexOf('}', index + 1)
        if (end < 0) fail("The regular expression contains an unterminated repetition.")
        val parts = pattern.substring(index + 1, end).split(',')
        if (
            parts.size !in 1..2 ||
            parts.firstOrNull().isNullOrEmpty() ||
            parts[0].any { !it.isDigit() } ||
            (parts.size == 2 && parts[1].isNotEmpty() && parts[1].any { !it.isDigit() })
        ) {
            fail("The regular expression contains an invalid repetition.")
        }
        val minimum = parts[0].toIntOrNull() ?: fail("The regular expression contains an invalid repetition.")
        val maximum = if (parts.size == 1) minimum else parts[1].takeIf(String::isNotEmpty)?.toIntOrNull()
        if (maximum != null && minimum > maximum) fail("The regular expression repetition range is reversed.")
        index = end + 1
        return minimum to maximum
    }

    private fun atom(): ParsedRegex {
        val value = takeCodePoint()
        return when (value) {
            '('.code -> {
                groupCount += 1
                val group = groupCount
                val body = alternative()
                if (takeCodePoint() != ')'.code) fail("The regular expression contains an unterminated group.")
                ParsedRegex.Group(group, body)
            }

            '.'.code -> {
                ParsedRegex.Character(CodePointPredicate { codePoint -> codePoint !in DOT_EXCLUSIONS })
            }

            '^'.code -> {
                ParsedRegex.Start
            }

            '$'.code -> {
                ParsedRegex.End
            }

            '['.code -> {
                characterClass()
            }

            '\\'.code -> {
                escape()
            }

            else -> {
                ParsedRegex.Character(CodePointPredicate { codePoint -> codePoint == value })
            }
        }
    }

    private fun characterClass(): ParsedRegex {
        val negate = peek() == '^'
        if (negate) index += 1
        val predicates = mutableListOf<CodePointPredicate>()
        while (index < pattern.length && peek() != ']') {
            val first = classAtom()
            if (peek() == '-' && pattern.getOrNull(index + 1) != ']') {
                index += 1
                val last = classAtom()
                val minimum = first.literal ?: fail("The regular expression contains an invalid character range.")
                val maximum = last.literal ?: fail("The regular expression contains an invalid character range.")
                if (minimum > maximum) fail("The regular expression contains a reversed character range.")
                predicates += CodePointPredicate { codePoint -> codePoint in minimum..maximum }
            } else {
                predicates += first.predicate
            }
        }
        if (takeCodePoint() != ']'.code) fail("The regular expression contains an unterminated character class.")
        return ParsedRegex.Character(
            if (negate) {
                CodePointPredicate { codePoint -> predicates.none { it.matches(codePoint) } }
            } else {
                CodePointPredicate { codePoint -> predicates.any { it.matches(codePoint) } }
            },
        )
    }

    private fun classAtom(): ClassAtom {
        if (peek() != '\\') {
            val codePoint = takeCodePoint()
            return ClassAtom(CodePointPredicate { value -> value == codePoint }, codePoint)
        }
        index += 1
        return escapedClassAtom()
    }

    private fun escape(): ParsedRegex.Character = ParsedRegex.Character(escapedClassAtom().predicate)

    private fun escapedClassAtom(): ClassAtom {
        val marker = takeCodePoint()
        return when (marker) {
            'd'.code -> predicateAtom { it in '0'.code..'9'.code }
            'D'.code -> predicateAtom { it !in '0'.code..'9'.code }
            'w'.code -> predicateAtom(::isAsciiWord)
            'W'.code -> predicateAtom { !isAsciiWord(it) }
            's'.code -> predicateAtom { it in PORTABLE_WHITESPACE }
            'S'.code -> predicateAtom { it !in PORTABLE_WHITESPACE }
            'x'.code -> literalAtom(fixedHex(2))
            'u'.code -> literalAtom(fixedHex(4))
            '0'.code -> literalAtom(0)
            'n'.code -> literalAtom('\n'.code)
            'r'.code -> literalAtom('\r'.code)
            't'.code -> literalAtom('\t'.code)
            'f'.code -> literalAtom(12)
            else -> literalAtom(marker)
        }
    }

    private fun fixedHex(digits: Int): Int {
        val end = index + digits
        if (end > pattern.length) fail("The regular expression contains an incomplete hexadecimal escape.")
        val value =
            pattern.substring(index, end).toIntOrNull(16)
                ?: fail("The regular expression contains an invalid hexadecimal escape.")
        index = end
        return value
    }

    private fun takeCodePoint(): Int {
        if (index >= pattern.length) fail("The regular expression ended unexpectedly.")
        val value = pattern.codePointAt(index)
        index += Character.charCount(value)
        return value
    }

    private fun peek(): Char? = pattern.getOrNull(index)

    private fun fail(message: String): Nothing = throw PortableRegexCompileFailure(message)
}

private data class ClassAtom(
    val predicate: CodePointPredicate,
    val literal: Int?,
)

private fun predicateAtom(predicate: (Int) -> Boolean): ClassAtom = ClassAtom(CodePointPredicate(predicate), null)

private fun literalAtom(value: Int): ClassAtom = ClassAtom(CodePointPredicate { it == value }, value)

private data class RegexFragment(
    val start: Int,
    val exits: List<RegexExit>,
)

private data class RegexExit(
    val instruction: Int,
    val link: RegexLink,
)

private enum class RegexLink { Next, Preferred, Alternative }

private data class RegexProgram(
    val instructions: List<RegexInstruction>,
    val start: Int,
)

private class PortableRegexCompiler(
    private val limit: Int,
) {
    private val instructions = mutableListOf<RegexInstruction>()

    fun finish(value: ParsedRegex): RegexProgram {
        val opening = emit(RegexInstruction.Save(0))
        val body = compile(value)
        val closing = emit(RegexInstruction.Save(1))
        val accepted = emit(RegexInstruction.Match)
        patch(opening, RegexLink.Next, body.start)
        patch(body.exits, closing)
        patch(closing, RegexLink.Next, accepted)
        return RegexProgram(instructions, opening)
    }

    private fun compile(value: ParsedRegex): RegexFragment =
        when (value) {
            ParsedRegex.Empty -> {
                single(RegexInstruction.Jump())
            }

            is ParsedRegex.Character -> {
                single(RegexInstruction.Character(value.predicate))
            }

            ParsedRegex.Start -> {
                single(RegexInstruction.Start())
            }

            ParsedRegex.End -> {
                single(RegexInstruction.End())
            }

            is ParsedRegex.Sequence -> {
                value.values.map(::compile).reduce { current, next ->
                    patch(current.exits, next.start)
                    RegexFragment(current.start, next.exits)
                }
            }

            is ParsedRegex.Alternate -> {
                value.values.map(::compile).reduce { current, next ->
                    val split = emit(RegexInstruction.Split(current.start, next.start))
                    RegexFragment(split, current.exits + next.exits)
                }
            }

            is ParsedRegex.Group -> {
                val opening = emit(RegexInstruction.Save(value.index * 2))
                val body = compile(value.value)
                val closing = emit(RegexInstruction.Save(value.index * 2 + 1))
                patch(opening, RegexLink.Next, body.start)
                patch(body.exits, closing)
                RegexFragment(opening, listOf(RegexExit(closing, RegexLink.Next)))
            }

            is ParsedRegex.Repeat -> {
                val repeat = emit(RegexInstruction.Repeat(value.value.predicate, value.minimum, value.maximum))
                RegexFragment(repeat, listOf(RegexExit(repeat, RegexLink.Next)))
            }
        }

    private fun single(instruction: RegexInstruction): RegexFragment {
        val index = emit(instruction)
        return RegexFragment(index, listOf(RegexExit(index, RegexLink.Next)))
    }

    private fun emit(instruction: RegexInstruction): Int {
        if (instructions.size >= limit) {
            throw PortableRegexCompileFailure("The regular expression program exceeds its limit.")
        }
        instructions += instruction
        return instructions.lastIndex
    }

    private fun patch(
        exits: List<RegexExit>,
        target: Int,
    ) = exits.forEach { patch(it.instruction, it.link, target) }

    private fun patch(
        instruction: Int,
        link: RegexLink,
        target: Int,
    ) {
        when (val value = instructions[instruction]) {
            is RegexInstruction.Jump -> {
                value.next = target
            }

            is RegexInstruction.Character -> {
                value.next = target
            }

            is RegexInstruction.Repeat -> {
                value.next = target
            }

            is RegexInstruction.Save -> {
                value.next = target
            }

            is RegexInstruction.Start -> {
                value.next = target
            }

            is RegexInstruction.End -> {
                value.next = target
            }

            is RegexInstruction.Split -> {
                when (link) {
                    RegexLink.Preferred -> value.preferred = target
                    RegexLink.Alternative -> value.alternative = target
                    RegexLink.Next -> error("A split instruction has no next link.")
                }
            }

            RegexInstruction.Match -> {
                error("A match instruction cannot be patched.")
            }
        }
    }
}

private fun StringBuilder.appendCodePoints(
    codePoints: IntArray,
    start: Int,
    end: Int,
    consumeStep: () -> Unit,
) {
    for (index in start until end) {
        consumeStep()
        appendCodePoint(codePoints[index])
    }
}

private fun StringBuilder.appendReplacement(
    replacement: String,
    codePoints: IntArray,
    captures: IntArray,
    groupCount: Int,
    consumeStep: () -> Unit,
) {
    var index = 0
    while (index < replacement.length) {
        val marker = replacement.codePointAt(index)
        index += Character.charCount(marker)
        when (marker) {
            '\\'.code -> {
                if (index == replacement.length) throw PortableRegexCompileFailure("The regular expression replacement is invalid.")
                val escaped = replacement.codePointAt(index)
                consumeStep()
                appendCodePoint(escaped)
                index += Character.charCount(escaped)
            }

            '$'.code -> {
                if (index == replacement.length || !replacement[index].isDigit()) {
                    throw PortableRegexCompileFailure("The regular expression replacement is invalid.")
                }
                var group = replacement[index].digitToInt()
                if (group > groupCount) throw PortableRegexCompileFailure("The regular expression replacement is invalid.")
                index += 1
                while (index < replacement.length && replacement[index].isDigit()) {
                    val candidate = group * 10 + replacement[index].digitToInt()
                    if (candidate > groupCount) break
                    group = candidate
                    index += 1
                }
                val captureStart = captures[group * 2]
                val captureEnd = captures[group * 2 + 1]
                if (captureStart != UNSET_CAPTURE && captureEnd != UNSET_CAPTURE) {
                    appendCodePoints(codePoints, captureStart, captureEnd, consumeStep)
                }
            }

            else -> {
                consumeStep()
                appendCodePoint(marker)
            }
        }
    }
}

private fun isAsciiWord(codePoint: Int): Boolean =
    codePoint == '_'.code || codePoint in '0'.code..'9'.code || codePoint in 'A'.code..'Z'.code ||
        codePoint in 'a'.code..'z'.code

private const val MAX_PROGRAM_SIZE = 2_048
private const val UNPATCHED = -1
private const val UNSET_CAPTURE = -1
private const val NO_REPEAT = -1
private val DOT_EXCLUSIONS = setOf('\n'.code, '\r'.code, 0x2028, 0x2029)
private val PORTABLE_WHITESPACE =
    setOf(
        0x0009,
        0x000A,
        0x000B,
        0x000C,
        0x000D,
        0x0020,
        0x0085,
        0x00A0,
        0x1680,
        0x2028,
        0x2029,
        0x202F,
        0x205F,
        0x3000,
        0xFEFF,
    ) + (0x2000..0x200A)
