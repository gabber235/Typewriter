package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan

/**
 * How deep the tree may nest. Real formulas stay far below it; past it the rest of the nested part is one
 * problem, so neither this parser nor a walk over its tree can overflow the stack.
 */
private const val MAX_DEPTH = 160

/** Shared by a parser and the parsers of its text holes. */
internal class Nesting {
    var depth = 0
}

/**
 * The cursor of one parse: the tokens, what the enclosing constructs accept as their next token, and the problems
 * found so far. The grammar lives in extension functions beside it. Every loop in the grammar consumes a token or
 * stops, and every recursion goes through [nested], so no text loops forever or overflows the stack.
 */
internal class FormulaParser(
    private val tokens: List<Token>,
    val problems: MutableList<SyntaxProblem>,
    private val nesting: Nesting = Nesting(),
) {
    private var index = 0
    private var newlinesIgnored = false

    /** Whether `{` after a value starts a trailing lambda. Off in `if let`, where `{` starts the branch. */
    var trailingLambdas = true
        private set

    /** How many tokens have been consumed, so a loop can tell it made progress. */
    val position: Int get() = index

    /** Closing brackets some enclosing construct waits for, by kind. Inner brackets keep them. */
    private val closersAwaited = IntArray(TokenKind.entries.size)

    /** Separators the innermost construct accepts next, such as `,` in a call or `:` in a ternary. */
    private var separators: Set<TokenKind> = emptySet()

    /** The end of the last token consumed. */
    var previousEnd = 0
        private set

    /** The next token. Newlines are skipped inside brackets, where they end nothing. */
    fun peek(): Token = tokens[significantIndex(index)]

    /** The token [ahead] significant tokens after the next one. */
    fun peekAt(ahead: Int): Token {
        var at = significantIndex(index)
        repeat(ahead) { at = significantIndex(minOf(at + 1, tokens.lastIndex)) }
        return tokens[at]
    }

    fun at(kind: TokenKind) = peek().kind == kind

    fun advance(): Token {
        val at = significantIndex(index)
        val token = tokens[at]
        if (token.kind != TokenKind.End) index = at + 1
        previousEnd = token.end
        token.problem?.let { report(token.span, it) }
        return token
    }

    fun accept(kind: TokenKind): Token? = if (at(kind)) advance() else null

    /** Consumes [kind], or reports it as missing where the next token starts. */
    fun expect(
        kind: TokenKind,
        what: String,
    ): Token? = accept(kind) ?: null.also { reportMissing("Expected $what") }

    fun report(
        span: TextSpan,
        message: String,
    ) {
        // A cascade of problems at one place says nothing the first one did not.
        if (problems.lastOrNull()?.span?.start == span.start) return
        problems += SyntaxProblem(span, message)
    }

    fun reportMissing(message: String) = report(TextSpan(peek().start, peek().start), message)

    /** A span from [start] to the end of what has been consumed. */
    fun spanFrom(start: Int) = TextSpan(start, maxOf(start, previousEnd))

    /** A span from [start] that also covers [last], which may be an empty error after the consumed text. */
    fun spanFrom(
        start: Int,
        last: FormulaNode?,
    ) = TextSpan(start, maxOf(start, previousEnd, last?.span?.end ?: 0))

    /** Whether the next token ends what is being parsed, so a missing part is reported before it. */
    fun atStop(): Boolean {
        val kind = peek().kind
        return kind == TokenKind.End ||
            kind == TokenKind.Newline ||
            kind == TokenKind.Semicolon ||
            closersAwaited[kind.ordinal] > 0 ||
            kind in separators
    }

    /** Whether newlines and `;` are next, without skipping them. */
    fun atLineEnd(): Boolean {
        val kind = tokens[index].kind
        return kind == TokenKind.Newline || kind == TokenKind.Semicolon || kind == TokenKind.End
    }

    /** The raw next token, a newline included even inside brackets. */
    fun peekRaw(): Token = tokens[index]

    fun skipLineEnds() {
        while (tokens[index].kind == TokenKind.Newline || tokens[index].kind == TokenKind.Semicolon) index++
    }

    /** Skips newlines when the first token after them is one of [kinds], so a line can continue there. */
    fun continueLineBefore(kinds: Set<TokenKind>) {
        if (newlinesIgnored || tokens[index].kind != TokenKind.Newline) return
        var at = index
        while (tokens[at].kind == TokenKind.Newline) at++
        if (tokens[at].kind in kinds) index = at
    }

    /**
     * Parses inside a bracket that closes with [closer], then consumes the closer when [closes]: newlines follow
     * [ignoreNewlines], and [accepted] separate.
     */
    fun <T> inside(
        closer: TokenKind,
        ignoreNewlines: Boolean,
        accepted: Set<TokenKind>,
        closes: Boolean = true,
        body: () -> T,
    ): T {
        val outerNewlines = newlinesIgnored
        val outerSeparators = separators
        val outerTrailing = trailingLambdas
        newlinesIgnored = ignoreNewlines
        separators = accepted
        trailingLambdas = true
        closersAwaited[closer.ordinal]++
        try {
            return body().also { if (closes) expect(closer, "`${closerText.getValue(closer)}`") }
        } finally {
            closersAwaited[closer.ordinal]--
            trailingLambdas = outerTrailing
            separators = outerSeparators
            newlinesIgnored = outerNewlines
        }
    }

    /** Parses with [extra] accepted as separators too, such as `else` after the branch of an `if`. */
    fun <T> accepting(
        extra: Set<TokenKind>,
        body: () -> T,
    ): T {
        val outer = separators
        separators = outer + extra
        try {
            return body()
        } finally {
            separators = outer
        }
    }

    /** Parses with `{` ending the value instead of starting a trailing lambda. */
    fun <T> withoutTrailingLambdas(body: () -> T): T {
        val outer = trailingLambdas
        trailingLambdas = false
        try {
            return body()
        } finally {
            trailingLambdas = outer
        }
    }

    /** Skips newlines, as after an operator, whose operand may start on the next line. */
    fun skipNewlines() {
        while (tokens[index].kind == TokenKind.Newline) index++
    }

    /**
     * Whether the raw tokens from the next one, newlines skipped, are all of [allowed] up to [target]. Used to tell
     * a lambda's parameters from its body before parsing either.
     */
    fun scanReaches(
        allowed: Set<TokenKind>,
        target: TokenKind,
    ): Boolean {
        var at = index
        while (tokens[at].kind == TokenKind.Newline) at++
        while (tokens[at].kind in allowed) at++
        return tokens[at].kind == target
    }

    /**
     * Runs [body] one level deeper. Past the limit, [tooDeep] gets the span of the rest of the nested part, which
     * is skipped and reported once.
     */
    fun <T> nested(
        levels: Int = 1,
        tooDeep: (TextSpan) -> T,
        body: () -> T,
    ): T {
        if (nesting.depth + levels > MAX_DEPTH) {
            val start = peek().start
            skipToStop()
            val span = spanFrom(start)
            report(span, "This part nests too deeply")
            return tooDeep(span)
        }
        nesting.depth += levels
        try {
            return body()
        } finally {
            nesting.depth -= levels
        }
    }

    /** Whether [levels] more levels still fit, for loops that deepen a tree without recursing. */
    fun fits(levels: Int) = nesting.depth + levels <= MAX_DEPTH

    /**
     * Skips tokens, brackets as a whole, until a token that ends the enclosing construct. A closing bracket nothing
     * waits for is skipped too. Iterative.
     */
    fun skipToStop() {
        var open = 0
        while (true) {
            val kind = peek().kind
            if (kind == TokenKind.End || (open == 0 && atStop())) return
            if (kind in openingKinds) open++
            if (kind in closingKinds && open > 0) open--
            advance()
        }
    }

    /** A parser for the tokens of a text hole, sharing this parse's problems and depth. */
    fun forHole(tokens: List<Token>) = FormulaParser(tokens, problems, nesting)

    /** An empty error where a value is missing, before a token that ends the enclosing construct. */
    fun missingExpression(): Error {
        val at = peek().start
        reportMissing("Expected a value")
        return Error("Expected a value", TextSpan(at, at))
    }

    /** Consumes a token that cannot start what is expected, as an error spanning it. */
    fun unexpected(what: String): Error {
        val token = advance()
        val message = "Expected $what, found `${token.text.ifEmpty { token.kind.name }}`"
        if (token.problem == null) report(token.span, message)
        return Error(message, token.span)
    }

    fun name(token: Token) = Name(token.text, token.span)

    /** The name at the next token, or an empty name there with a problem, so a half typed `a.` keeps its shape. */
    fun expectName(what: String): Name {
        if (at(TokenKind.Identifier)) return name(advance())
        reportMissing("Expected $what")
        return Name("", TextSpan(peek().start, peek().start))
    }

    fun finish(lexerProblems: List<SyntaxProblem>) {
        skipLineEnds()
        if (!at(TokenKind.End)) {
            val start = peek().start
            skipToEnd()
            report(spanFrom(start), "Expected the end of the text")
        }
        problems += lexerProblems
        problems.sortBy { it.span.start }
    }

    private fun skipToEnd() {
        while (!at(TokenKind.End)) advance()
    }

    private fun significantIndex(from: Int): Int {
        var at = from
        if (newlinesIgnored) {
            while (tokens[at].kind == TokenKind.Newline) at++
        }
        return at
    }
}

private val openingKinds = setOf(TokenKind.LeftParen, TokenKind.LeftBracket, TokenKind.LeftBrace)
private val closingKinds = setOf(TokenKind.RightParen, TokenKind.RightBracket, TokenKind.RightBrace)
private val closerText =
    mapOf(TokenKind.RightParen to ")", TokenKind.RightBracket to "]", TokenKind.RightBrace to "}", TokenKind.Greater to ">")
