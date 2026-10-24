package com.typewritermc.expression.shortcuts

import com.typewritermc.expression.Expr
import com.typewritermc.expression.MayBeMissing
import com.typewritermc.expression.MissingPolicy
import com.typewritermc.expression.field
import com.typewritermc.expression.find
import com.typewritermc.expression.findAll
import com.typewritermc.expression.get
import com.typewritermc.expression.isNull
import com.typewritermc.expression.length
import com.typewritermc.expression.let
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.map
import com.typewritermc.expression.not
import com.typewritermc.expression.operations.RegexMatch
import com.typewritermc.expression.operations.portableRegexValidationError
import com.typewritermc.expression.plus
import com.typewritermc.expression.replaceRegex
import com.typewritermc.expression.substring
import com.typewritermc.expression.zip

/*
 * Regular expression shortcuts over the portable subset of regex.find, regex.find_all and regex.replace. Patterns and
 * inputs have size limits (regex_limit) and the subset rejects host specific syntax (invalid_regex).
 */

/**
 * Whether the whole text matches [pattern], like Kotlin's matches. The pattern is validated alone when the expression
 * is built, so a pattern outside the portable subset (or one that only parses once anchored, such as `a)|(b`) throws
 * [IllegalArgumentException] instead of changing meaning inside the anchoring group.
 */
@JvmName("textMatches")
fun <M : MissingPolicy> Expr<String, M>.matches(pattern: String): Expr<Boolean, M> =
    find("^(${requirePortablePattern(pattern)})$").isNull().not()

/** Whether [pattern] matches somewhere in the text. Stops at the first match. */
fun <M : MissingPolicy> Expr<String, M>.containsMatchIn(pattern: Expr<String, M>): Expr<Boolean, M> = find(pattern).isNull().not()

/**
 * Whether [pattern] matches somewhere in the text. Stops at the first match. The pattern is validated when the
 * expression is built and throws [IllegalArgumentException] outside the portable subset.
 */
@JvmName("containsMatchInRaw")
fun <M : MissingPolicy> Expr<String, M>.containsMatchIn(pattern: String): Expr<Boolean, M> =
    find(requirePortablePattern(pattern)).isNull().not()

/**
 * The text of capture [group] of the first match of [pattern]: group 0 is the whole match, a group that did not take
 * part is null. Missing when nothing matches; fails with collection_key_absent when the pattern has no such group.
 */
fun <M : MissingPolicy> Expr<String, M>.capture(
    pattern: String,
    group: Int = 0,
): Expr<String?, MayBeMissing> {
    require(group >= 0) { "A capture group index is not negative." }
    val match: Expr<RegexMatch?, M> = find(pattern)
    return if (group == 0) match.field<String>("text").orNull() else match.field<List<String?>>("groups")[group - 1]
}

/** The parts of the text between the matches of [pattern], including empty ones. */
fun <M : MissingPolicy> Expr<String, M>.splitRegex(pattern: String): Expr<List<String>, MayBeMissing> =
    let(this) { text ->
        let(text.findAll(pattern)) { matches ->
            val starts = listExpr(literal(0)) + matches.map { field<Int>("end") }
            val ends = matches.map { field<Int>("start") } + listExpr(text.length)
            (starts zip ends).map { text.substring(entryKey, entryValue) }
        }
    }

/** This text with every regular expression metacharacter escaped, so that it matches itself as a pattern. */
fun <M : MissingPolicy> Expr<String, M>.escapeRegex(): Expr<String, M> = replaceRegex("""([\\.^$|?*+()\[\]{}])""", """\$1""")

/** [pattern] when it lies in the portable regex subset and its size limit; throws with the reason otherwise. */
private fun requirePortablePattern(pattern: String): String {
    pattern.portableRegexValidationError()?.let { reason -> throw IllegalArgumentException(reason) }
    return pattern
}
