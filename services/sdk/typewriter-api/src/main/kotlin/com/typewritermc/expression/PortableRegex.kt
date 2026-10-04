package com.typewritermc.expression

internal fun String.normalizePortableRegex(): PortableRegexNormalization {
    val pattern = this
    if (pattern.length > PortableExpressionLimits.MAX_REGEX_PATTERN_CODE_UNITS) {
        return PortableRegexNormalization.Unsupported("The regular expression pattern exceeds its limit.")
    }
    val output = StringBuilder(pattern.length)
    var index = 0
    var groupDepth = 0
    var groupCount = 0
    var lastAtom = RegexAtom.None
    var currentAtomQuantified = false
    var priorAtomQuantified = false

    fun beginAtom() {
        priorAtomQuantified = currentAtomQuantified
        currentAtomQuantified = false
        lastAtom = RegexAtom.Value
    }

    while (index < pattern.length) {
        when (val character = pattern[index]) {
            '\\' -> {
                beginAtom()
                val escape = normalizeEscape(pattern, index + 1, inCharacterClass = false)
                when (escape) {
                    is EscapeNormalization.Ready -> {
                        output.append(escape.value)
                        index = escape.lastIndex
                    }

                    is EscapeNormalization.Invalid -> {
                        return PortableRegexNormalization.Invalid(escape.reason)
                    }

                    is EscapeNormalization.Unsupported -> {
                        return PortableRegexNormalization.Unsupported(escape.reason)
                    }
                }
            }

            '[' -> {
                beginAtom()
                val characterClass = normalizeCharacterClass(pattern, index + 1)
                when (characterClass) {
                    is CharacterClassNormalization.Ready -> {
                        output.append(characterClass.value)
                        index = characterClass.lastIndex
                    }

                    is CharacterClassNormalization.Invalid -> {
                        return PortableRegexNormalization.Invalid(characterClass.reason)
                    }

                    is CharacterClassNormalization.Unsupported -> {
                        return PortableRegexNormalization.Unsupported(characterClass.reason)
                    }
                }
            }

            '(' -> {
                if (pattern.getOrNull(index + 1) == '?') {
                    return PortableRegexNormalization.Unsupported(
                        "Lookarounds, named groups, flags, and special groups are not supported.",
                    )
                }
                groupDepth += 1
                groupCount += 1
                if (groupDepth > MAX_REGEX_GROUP_DEPTH || groupCount > MAX_REGEX_CAPTURE_GROUPS) {
                    return PortableRegexNormalization.Unsupported("The regular expression contains too many groups.")
                }
                priorAtomQuantified = false
                currentAtomQuantified = false
                lastAtom = RegexAtom.None
                output.append(character)
            }

            ')' -> {
                if (groupDepth == 0) {
                    return PortableRegexNormalization.Invalid("The regular expression contains an unmatched closing group.")
                }
                groupDepth -= 1
                priorAtomQuantified = currentAtomQuantified
                currentAtomQuantified = false
                lastAtom = RegexAtom.Group
                output.append(character)
            }

            '*', '+', '?' -> {
                if (lastAtom == RegexAtom.None) {
                    return PortableRegexNormalization.Invalid("The regular expression contains a quantifier without an atom.")
                }
                if (lastAtom == RegexAtom.Anchor) {
                    return PortableRegexNormalization.Invalid("A regular expression anchor cannot be quantified.")
                }
                if (lastAtom == RegexAtom.Group) {
                    return PortableRegexNormalization.Unsupported(
                        "Repeating a group is not supported by portable regular expressions.",
                    )
                }
                if (currentAtomQuantified || priorAtomQuantified) {
                    return PortableRegexNormalization.Unsupported("Adjacent, lazy, and possessive quantifiers are not supported.")
                }
                currentAtomQuantified = true
                output.append(character)
            }

            '{' -> {
                if (lastAtom == RegexAtom.None) {
                    return PortableRegexNormalization.Invalid("The regular expression contains a quantifier without an atom.")
                }
                if (lastAtom == RegexAtom.Anchor) {
                    return PortableRegexNormalization.Invalid("A regular expression anchor cannot be quantified.")
                }
                if (lastAtom == RegexAtom.Group) {
                    return PortableRegexNormalization.Unsupported(
                        "Repeating a group is not supported by portable regular expressions.",
                    )
                }
                if (currentAtomQuantified || priorAtomQuantified) {
                    return PortableRegexNormalization.Unsupported("Adjacent quantifiers are not supported.")
                }
                val end = pattern.indexOf('}', index + 1)
                if (end < 0) {
                    return PortableRegexNormalization.Invalid("The regular expression contains an unterminated repetition.")
                }
                val bounds = pattern.substring(index + 1, end).split(',')
                if (bounds.size !in 1..2 || bounds.any { it.isNotEmpty() && it.any { digit -> !digit.isDigit() } }) {
                    return PortableRegexNormalization.Invalid("The regular expression contains an invalid repetition.")
                }
                val values = bounds.filter(String::isNotEmpty).map(String::toIntOrNull)
                if (values.any { it == null || it > MAX_REGEX_REPETITION }) {
                    return PortableRegexNormalization.Unsupported("The regular expression repetition exceeds its limit.")
                }
                if (bounds.size == 2 && bounds[1].isNotEmpty()) {
                    val minimum =
                        bounds[0].toIntOrNull()
                            ?: return PortableRegexNormalization.Invalid("The regular expression repetition is invalid.")
                    val maximum =
                        bounds[1].toIntOrNull()
                            ?: return PortableRegexNormalization.Invalid("The regular expression repetition is invalid.")
                    if (minimum > maximum) {
                        return PortableRegexNormalization.Invalid("The regular expression repetition range is reversed.")
                    }
                }
                currentAtomQuantified = true
                output.append(pattern, index, end + 1)
                index = end
            }

            '|' -> {
                priorAtomQuantified = false
                currentAtomQuantified = false
                lastAtom = RegexAtom.None
                output.append(character)
            }

            '.' -> {
                beginAtom()
                output.append(PORTABLE_DOT)
            }

            '^', '$' -> {
                priorAtomQuantified = false
                currentAtomQuantified = false
                lastAtom = RegexAtom.Anchor
                output.append(character)
            }

            else -> {
                beginAtom()
                output.append(character)
            }
        }
        index += 1
    }
    if (groupDepth != 0) {
        return PortableRegexNormalization.Invalid("The regular expression contains an unterminated group.")
    }
    return PortableRegexNormalization.Ready(output.toString())
}

internal fun String.portableRegexValidationError(): String? =
    when (val normalization = normalizePortableRegex()) {
        is PortableRegexNormalization.Ready -> null
        is PortableRegexNormalization.Invalid -> normalization.reason
        is PortableRegexNormalization.Unsupported -> normalization.reason
    }

internal sealed interface PortableRegexNormalization {
    data class Ready(
        val pattern: String,
    ) : PortableRegexNormalization

    data class Invalid(
        val reason: String,
    ) : PortableRegexNormalization

    data class Unsupported(
        val reason: String,
    ) : PortableRegexNormalization
}

private sealed interface EscapeNormalization {
    data class Ready(
        val value: String,
        val lastIndex: Int,
    ) : EscapeNormalization

    data class Invalid(
        val reason: String,
    ) : EscapeNormalization

    data class Unsupported(
        val reason: String,
    ) : EscapeNormalization
}

private sealed interface CharacterClassNormalization {
    data class Ready(
        val value: String,
        val lastIndex: Int,
    ) : CharacterClassNormalization

    data class Invalid(
        val reason: String,
    ) : CharacterClassNormalization

    data class Unsupported(
        val reason: String,
    ) : CharacterClassNormalization
}

private fun normalizeEscape(
    pattern: String,
    escapedIndex: Int,
    inCharacterClass: Boolean,
): EscapeNormalization {
    if (escapedIndex >= pattern.length) {
        return EscapeNormalization.Invalid("The regular expression ends with an incomplete escape.")
    }
    val escaped = pattern[escapedIndex]
    if (escaped.isDigit() && escaped != '0') {
        return EscapeNormalization.Unsupported("Backreferences are not supported by portable regular expressions.")
    }
    if (escaped in "QEpPkKgGNXRLCvVbB") {
        return EscapeNormalization.Unsupported("The regular expression uses a host specific escape.")
    }
    if (inCharacterClass && escaped in "DSW") {
        return EscapeNormalization.Unsupported(
            "Complement shorthand escapes inside character classes are not supported by portable regular expressions.",
        )
    }
    return when (escaped) {
        'd' -> EscapeNormalization.Ready(if (inCharacterClass) ASCII_DIGITS else "[$ASCII_DIGITS]", escapedIndex)
        'D' -> EscapeNormalization.Ready("[^$ASCII_DIGITS]", escapedIndex)
        's' -> EscapeNormalization.Ready(if (inCharacterClass) PORTABLE_WHITESPACE else "[$PORTABLE_WHITESPACE]", escapedIndex)
        'S' -> EscapeNormalization.Ready("[^$PORTABLE_WHITESPACE]", escapedIndex)
        'w' -> EscapeNormalization.Ready(if (inCharacterClass) ASCII_WORD else "[$ASCII_WORD]", escapedIndex)
        'W' -> EscapeNormalization.Ready("[^$ASCII_WORD]", escapedIndex)
        '0' -> EscapeNormalization.Ready("\\x00", escapedIndex)
        'x' -> normalizeFixedHexEscape(pattern, escapedIndex, 2)
        'u' -> normalizeFixedHexEscape(pattern, escapedIndex, 4)
        in PORTABLE_LITERAL_ESCAPES -> EscapeNormalization.Ready("\\$escaped", escapedIndex)
        else -> EscapeNormalization.Unsupported("The regular expression uses an unsupported escape.")
    }
}

private fun normalizeFixedHexEscape(
    pattern: String,
    markerIndex: Int,
    digits: Int,
): EscapeNormalization {
    val end = markerIndex + digits + 1
    if (end > pattern.length || pattern.substring(markerIndex + 1, end).any { !it.isHexDigit() }) {
        return EscapeNormalization.Invalid(
            if (digits == 2) {
                "A hexadecimal escape must contain exactly two digits."
            } else {
                "A Unicode escape must contain exactly four digits."
            },
        )
    }
    val value = pattern.substring(markerIndex + 1, end).toInt(16)
    if (digits == 4 && value in 0xD800..0xDFFF) {
        return EscapeNormalization.Unsupported("Surrogate code unit escapes are not supported by portable regular expressions.")
    }
    return EscapeNormalization.Ready(pattern.substring(markerIndex - 1, end), end - 1)
}

private fun normalizeCharacterClass(
    pattern: String,
    start: Int,
): CharacterClassNormalization {
    val output = StringBuilder("[")
    var index = start
    if (pattern.getOrNull(index) == '^') {
        output.append('^')
        index += 1
    }
    var hasAtom = false
    while (index < pattern.length) {
        when (val character = pattern[index]) {
            ']' -> {
                if (!hasAtom) {
                    return CharacterClassNormalization.Invalid("The regular expression contains an empty character class.")
                }
                output.append(']')
                return CharacterClassNormalization.Ready(output.toString(), index)
            }

            '\\' -> {
                val escape = normalizeEscape(pattern, index + 1, inCharacterClass = true)
                when (escape) {
                    is EscapeNormalization.Ready -> {
                        output.append(escape.value)
                        index = escape.lastIndex
                        hasAtom = true
                    }

                    is EscapeNormalization.Invalid -> {
                        return CharacterClassNormalization.Invalid(escape.reason)
                    }

                    is EscapeNormalization.Unsupported -> {
                        return CharacterClassNormalization.Unsupported(escape.reason)
                    }
                }
            }

            '&' -> {
                if (pattern.getOrNull(index + 1) == '&') {
                    return CharacterClassNormalization.Unsupported(
                        "Character class intersection and subtraction are not supported.",
                    )
                }
                output.append(character)
                hasAtom = true
            }

            '-' -> {
                if (pattern.getOrNull(index + 1) == '-') {
                    return CharacterClassNormalization.Unsupported(
                        "Character class intersection and subtraction are not supported.",
                    )
                }
                output.append(character)
                hasAtom = true
            }

            '[' -> {
                return CharacterClassNormalization.Unsupported("Nested character classes are not supported.")
            }

            else -> {
                output.append(character)
                hasAtom = true
            }
        }
        index += 1
    }
    return CharacterClassNormalization.Invalid("The regular expression contains an unterminated character class.")
}

private const val MAX_REGEX_GROUP_DEPTH = 16
private const val MAX_REGEX_CAPTURE_GROUPS = 32
private const val MAX_REGEX_REPETITION = 1_000
private const val ASCII_DIGITS = "0-9"
private const val ASCII_WORD = "A-Za-z0-9_"
private const val PORTABLE_WHITESPACE =
    "\\x09-\\x0D\\x20\\x85\\xA0\\u1680\\u2000-\\u200A\\u2028\\u2029\\u202F\\u205F\\u3000\\uFEFF"
private const val PORTABLE_DOT = "[^\\n\\r\\u2028\\u2029]"
private const val PORTABLE_LITERAL_ESCAPES = "fnrt\\.*+?^${'$'}{}()|[]/-"

private enum class RegexAtom { None, Value, Group, Anchor }

private fun Char.isHexDigit(): Boolean = this in '0'..'9' || this in 'a'..'f' || this in 'A'..'F'
