package com.typewritermc.expression.operations

/**
 * Realm's kernel of the regular expression operations over the portable subset, matched by code point. Every machine
 * step and every copied code point charges one evaluation step.
 */
internal object PortableRegexKernel : RegexKernel {
    override fun find(
        value: String,
        pattern: String,
        meter: PortableMeter,
    ): RegexMatch? {
        val regex = compile(value, pattern)
        val codePoints = value.codePointArray()
        return regex.find(codePoints, 0, { meter.steps(1) })?.let { regex.describe(codePoints, it) }
    }

    override fun findAll(
        value: String,
        pattern: String,
        meter: PortableMeter,
    ): List<RegexMatch> {
        val regex = compile(value, pattern)
        val codePoints = value.codePointArray()
        return regex.findAll(codePoints, { meter.steps(1) }).map { regex.describe(codePoints, it) }
    }

    /** The replacement is parsed before matching, so a malformed one fails even when nothing matches. */
    override fun replace(
        value: String,
        pattern: String,
        replacement: String,
        meter: PortableMeter,
    ): String {
        val regex = compile(value, pattern)
        val template =
            try {
                PortableRegexReplacement.parse(replacement, regex.groupCount)
            } catch (failure: PortableRegexCompileFailure) {
                throw OperationFailure(KernelFailure.InvalidRegex, failure.message.orEmpty())
            }
        return regex.replace(value, template, { meter.steps(1) })
    }

    private fun compile(
        value: String,
        pattern: String,
    ): PortableRegexMatcher {
        if (pattern.length > MAX_REGEX_PATTERN_CODE_UNITS || value.length > MAX_REGEX_INPUT_CODE_UNITS) {
            throw OperationFailure(KernelFailure.RegexLimit, "The regular expression pattern or input exceeds its limit.")
        }
        return pattern.compiledPortableRegex().getOrElse { failure ->
            throw OperationFailure(KernelFailure.InvalidRegex, failure.message.orEmpty())
        }
    }

    private fun PortableRegexMatcher.describe(
        codePoints: IntArray,
        match: PortableRegexMatch,
    ): RegexMatch =
        RegexMatch(
            text = codePoints.codePointText(match.start, match.end),
            start = match.start,
            end = match.end,
            groups = (1..groupCount).map { group -> match.range(group)?.let { (from, to) -> codePoints.codePointText(from, to) } },
        )
}
