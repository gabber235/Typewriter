package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan

internal enum class TokenKind {
    Identifier,
    Integer,
    Decimal,
    Text,
    Newline,
    End,
    Unknown,

    LeftParen,
    RightParen,
    LeftBracket,
    RightBracket,
    LeftBrace,
    RightBrace,
    Comma,
    Colon,
    Semicolon,
    Dot,
    SafeDot,
    Elvis,
    Question,
    Range,
    Arrow,
    Plus,
    Minus,
    Star,
    Slash,
    Percent,
    Less,
    LessOrEqual,
    Greater,
    GreaterOrEqual,
    EqualEqual,
    NotEqual,
    Bang,
    AndAnd,
    OrOr,
    Assign,
    PlusAssign,
    MinusAssign,
    TimesAssign,
    DivideAssign,
    QuestionAssign,
    NotIn,
    NotIs,
    SafeAs,

    Let,
    If,
    Else,
    When,
    Is,
    In,
    As,
    And,
    Or,
    Not,
    True,
    False,
    Null,
}

/**
 * One token. [text] is a name without its backticks or a number without its underscores. A string's [pieces] hold
 * its text and its holes, each hole with its own tokens. [problem] is reported when the parser consumes the token.
 */
internal data class Token(
    val kind: TokenKind,
    val start: Int,
    val end: Int,
    val text: String = "",
    val pieces: List<StringPiece> = emptyList(),
    val problem: String? = null,
) {
    val span: TextSpan get() = TextSpan(start, end)
}

internal sealed interface StringPiece {
    data class Chars(
        val text: String,
        val span: TextSpan,
    ) : StringPiece

    /** `$name` or `${...}`. [tokens] end with an End token where the hole closes. */
    data class Hole(
        val tokens: List<Token>,
        val format: String?,
        val span: TextSpan,
    ) : StringPiece
}

internal val keywords =
    mapOf(
        "let" to TokenKind.Let,
        "if" to TokenKind.If,
        "else" to TokenKind.Else,
        "when" to TokenKind.When,
        "is" to TokenKind.Is,
        "in" to TokenKind.In,
        "as" to TokenKind.As,
        "and" to TokenKind.And,
        "or" to TokenKind.Or,
        "not" to TokenKind.Not,
        "true" to TokenKind.True,
        "false" to TokenKind.False,
        "null" to TokenKind.Null,
    )

/** Longest first, so `?.` wins over `?`. */
private val symbols =
    listOf(
        "?." to TokenKind.SafeDot,
        "?:" to TokenKind.Elvis,
        "?=" to TokenKind.QuestionAssign,
        ".." to TokenKind.Range,
        "->" to TokenKind.Arrow,
        "<=" to TokenKind.LessOrEqual,
        ">=" to TokenKind.GreaterOrEqual,
        "==" to TokenKind.EqualEqual,
        "!=" to TokenKind.NotEqual,
        "&&" to TokenKind.AndAnd,
        "||" to TokenKind.OrOr,
        "+=" to TokenKind.PlusAssign,
        "-=" to TokenKind.MinusAssign,
        "*=" to TokenKind.TimesAssign,
        "/=" to TokenKind.DivideAssign,
        "(" to TokenKind.LeftParen,
        ")" to TokenKind.RightParen,
        "[" to TokenKind.LeftBracket,
        "]" to TokenKind.RightBracket,
        "{" to TokenKind.LeftBrace,
        "}" to TokenKind.RightBrace,
        "," to TokenKind.Comma,
        ":" to TokenKind.Colon,
        ";" to TokenKind.Semicolon,
        "." to TokenKind.Dot,
        "?" to TokenKind.Question,
        "+" to TokenKind.Plus,
        "-" to TokenKind.Minus,
        "*" to TokenKind.Star,
        "/" to TokenKind.Slash,
        "%" to TokenKind.Percent,
        "<" to TokenKind.Less,
        ">" to TokenKind.Greater,
        "!" to TokenKind.Bang,
        "=" to TokenKind.Assign,
    )

private val openers = setOf(TokenKind.LeftParen, TokenKind.LeftBracket, TokenKind.LeftBrace)
private val closers = setOf(TokenKind.RightParen, TokenKind.RightBracket, TokenKind.RightBrace)

/** Holes nest no deeper than this, so a string of a hundred thousand `${` stays a problem and not a crash. */
private const val MAX_HOLE_DEPTH = 64

/** Splits formula text into tokens. Never throws: what does not lex is a token with a problem. */
internal class Lexer(
    private val source: String,
) {
    private var position = 0
    private var holeDepth = 0

    /** Problems that belong to no token, such as an unclosed comment. */
    val problems = mutableListOf<SyntaxProblem>()

    fun tokens(): List<Token> {
        val tokens = mutableListOf<Token>()
        while (true) {
            val token = next()
            tokens += token
            if (token.kind == TokenKind.End) return tokens
        }
    }

    private fun next(): Token {
        skipSpaceAndComments()
        val start = position
        if (position >= source.length) return Token(TokenKind.End, start, start)
        val char = source[position]
        return when {
            char == '\n' -> Token(TokenKind.Newline, start, ++position)
            char == '"' -> string()
            char == '`' -> quotedName()
            char.isDigit() -> number()
            isNameStart(source.codePointAt(position)) -> word()
            else -> negatedWord() ?: symbol()
        }
    }

    private fun skipSpaceAndComments() {
        while (position < source.length) {
            when {
                source[position] == ' ' || source[position] == '\t' || source[position] == '\r' -> position++
                source.startsWith("//", position) -> skipLineComment()
                source.startsWith("/*", position) -> skipBlockComment()
                else -> return
            }
        }
    }

    private fun skipLineComment() {
        while (position < source.length && source[position] != '\n') position++
    }

    /** Block comments nest, as in Kotlin. */
    private fun skipBlockComment() {
        val start = position
        var depth = 0
        while (position < source.length) {
            when {
                source.startsWith("/*", position) -> depth++.also { position += 2 }
                source.startsWith("*/", position) -> depth--.also { position += 2 }
                else -> position++
            }
            if (depth == 0) return
        }
        problems += SyntaxProblem(TextSpan(start, position), "This comment is never closed with */")
    }

    private fun symbol(): Token {
        val start = position
        val match = symbols.firstOrNull { source.startsWith(it.first, position) }
        if (match == null) {
            position += Character.charCount(source.codePointAt(position))
            return Token(TokenKind.Unknown, start, position, problem = "`${source.substring(start, position)}` is not part of a formula")
        }
        position += match.first.length
        return Token(match.second, start, position, match.first)
    }

    /** `!in` and `!is` are single tokens when the word ends there. */
    private fun negatedWord(): Token? {
        val kind =
            when {
                source.startsWith("!in", position) -> TokenKind.NotIn
                source.startsWith("!is", position) -> TokenKind.NotIs
                else -> return null
            }
        val end = position + 3
        if (end < source.length && isNamePart(source.codePointAt(end))) return null
        val start = position
        position = end
        return Token(kind, start, end, source.substring(start, end))
    }

    private fun word(): Token {
        val start = position
        while (position < source.length && isNamePart(source.codePointAt(position))) {
            position += Character.charCount(source.codePointAt(position))
        }
        val text = source.substring(start, position)
        if (text == "as" && source.startsWith("?", position) && !source.startsWith("?.", position) && !source.startsWith("?:", position)) {
            position++
            return Token(TokenKind.SafeAs, start, position, text = "as?")
        }
        return Token(keywords[text] ?: TokenKind.Identifier, start, position, text)
    }

    private fun quotedName(): Token {
        val start = position++
        while (position < source.length && source[position] != '`' && source[position] != '\n') position++
        val text = source.substring(start + 1, position)
        if (position >= source.length || source[position] != '`') {
            return Token(TokenKind.Identifier, start, position, text, problem = "This name is never closed with `")
        }
        position++
        val problem = if (text.isEmpty()) "A name between backticks needs at least one character" else null
        return Token(TokenKind.Identifier, start, position, text, problem = problem)
    }

    private fun number(): Token {
        val start = position
        digits()
        val fraction = fraction()
        val decimal = exponent() || fraction
        val text = source.substring(start, position).replace("_", "")
        val kind = if (decimal) TokenKind.Decimal else TokenKind.Integer
        val problem = if (!decimal && text.toLongOrNull() == null) "This number is too large" else null
        return Token(kind, start, position, text, problem = problem)
    }

    /** `.5` after the digits; `1..5` and `5.seconds` keep their dot. */
    private fun fraction(): Boolean {
        if (!source.startsWith(".", position) || source.getOrNull(position + 1)?.isDigit() != true) return false
        position++
        digits()
        return true
    }

    private fun exponent(): Boolean {
        if (source.getOrNull(position)?.lowercaseChar() != 'e' || !exponentFollows()) return false
        position++
        if (source[position] == '+' || source[position] == '-') position++
        digits()
        return true
    }

    private fun digits() {
        while (position < source.length && (source[position].isDigit() || source[position] == '_')) position++
    }

    private fun exponentFollows(): Boolean {
        val next = position + 1
        val digit = if (next < source.length && (source[next] == '+' || source[next] == '-')) next + 1 else next
        return digit < source.length && source[digit].isDigit()
    }

    private fun string(): Token = if (source.startsWith("\"\"\"", position)) rawString() else templateString()

    /** `"""..."""` holds its text as written: no escapes and no holes. */
    private fun rawString(): Token {
        val start = position
        position += 3
        val close = source.indexOf("\"\"\"", position)
        if (close < 0) {
            val text = source.substring(position)
            position = source.length
            return Token(
                TokenKind.Text,
                start,
                position,
                pieces = listOf(StringPiece.Chars(text, TextSpan(start + 3, position))),
                problem = UNCLOSED_TEXT,
            )
        }
        val piece = StringPiece.Chars(source.substring(position, close), TextSpan(position, close))
        position = close + 3
        return Token(TokenKind.Text, start, position, pieces = listOf(piece))
    }

    private fun templateString(): Token {
        val text = TemplateText(position++)
        while (true) {
            val char = source.getOrNull(position)
            when {
                char == null || char == '\n' -> {
                    return text.token(text.problem ?: UNCLOSED_TEXT)
                }

                char == '"' -> {
                    position++
                    return text.token(text.problem)
                }

                char == '\\' -> {
                    text.problem = escape(text.chars) ?: text.problem
                }

                char == '$' && holeFollows() -> {
                    holeInto(text)?.let { return text.token(it) }
                }

                else -> {
                    text.chars.append(char)
                    position++
                }
            }
        }
    }

    /** The pieces of a string read so far. */
    private inner class TemplateText(
        val start: Int,
    ) {
        val pieces = mutableListOf<StringPiece>()
        val chars = StringBuilder()
        var charsStart = start + 1
        var problem: String? = null

        fun flush() {
            if (chars.isNotEmpty()) pieces += StringPiece.Chars(chars.toString(), TextSpan(charsStart, position))
            chars.clear()
        }

        fun token(problem: String?): Token {
            flush()
            return Token(TokenKind.Text, start, position, pieces = pieces, problem = problem)
        }
    }

    /** Adds the hole at `$` to [text] and returns a problem that ends the string, if any. */
    private fun holeInto(text: TemplateText): String? {
        text.flush()
        val (hole, problem) = hole()
        text.pieces += hole
        text.charsStart = position
        return problem
    }

    private fun holeFollows(): Boolean {
        val next = position + 1
        return next < source.length && (source[next] == '{' || isNameStart(source.codePointAt(next)))
    }

    /** Appends one escape to [chars] and returns its problem, if any. */
    private fun escape(chars: StringBuilder): String? {
        val next = source.getOrNull(position + 1)
        val simple = next?.let { escapes[it] }
        if (simple != null) {
            chars.append(simple)
            position += 2
            return null
        }
        if (next == 'u') {
            val digits = source.substring(position + 2, minOf(position + 6, source.length))
            val code = digits.takeIf { it.length == 4 && it.all(::isHexDigit) }?.toInt(16)
            if (code != null) {
                chars.append(code.toChar())
                position += 6
                return null
            }
        }
        chars.append('\\')
        position++
        return "Unknown escape; write \\\\ for a backslash"
    }

    /** Lexes `$name` or `${...}` from the `$`; the second value is a problem that ends the string. */
    private fun hole(): Pair<StringPiece.Hole, String?> {
        val start = position++
        if (source[position] != '{') {
            val name = word()
            return StringPiece.Hole(listOf(name, Token(TokenKind.End, position, position)), null, TextSpan(start, position)) to null
        }
        position++
        if (holeDepth >= MAX_HOLE_DEPTH) {
            position = source.length
            return StringPiece.Hole(listOf(Token(TokenKind.End, position, position)), null, TextSpan(start, position)) to
                "Text holes nest too deeply"
        }
        holeDepth++
        try {
            return holeBody(start)
        } finally {
            holeDepth--
        }
    }

    private fun holeBody(start: Int): Pair<StringPiece.Hole, String?> {
        val tokens = mutableListOf<Token>()
        val nesting = HoleNesting()
        while (true) {
            skipSpaceAndComments()
            val char = source.getOrNull(position)
            when {
                char == null || char == '\n' -> {
                    tokens += Token(TokenKind.End, position, position)
                    return StringPiece.Hole(tokens, null, TextSpan(start, position)) to UNCLOSED_HOLE
                }

                char == '}' && nesting.atTop -> {
                    tokens += Token(TokenKind.End, position, position)
                    position++
                    return StringPiece.Hole(tokens, null, TextSpan(start, position)) to null
                }

                char == ':' && nesting.atFormat -> {
                    return formatHole(start, tokens)
                }

                else -> {
                    tokens += next().also { nesting.track(it.kind) }
                }
            }
        }
    }

    /** Brackets and open ternaries in a hole, so the hole's `}` and its format's `:` are told apart from inner ones. */
    private class HoleNesting {
        private var depth = 0
        private var ternaries = 0
        val atTop get() = depth == 0
        val atFormat get() = depth == 0 && ternaries == 0

        fun track(kind: TokenKind) {
            when {
                kind in openers -> depth++
                kind in closers -> depth = maxOf(0, depth - 1)
                depth == 0 && kind == TokenKind.Question -> ternaries++
                depth == 0 && kind == TokenKind.Colon -> ternaries--
            }
        }
    }

    /** The text after a top level `:` in a hole is a format, kept as written up to the closing `}`. */
    private fun formatHole(
        start: Int,
        tokens: MutableList<Token>,
    ): Pair<StringPiece.Hole, String?> {
        tokens += Token(TokenKind.End, position, position)
        val formatStart = ++position
        while (position < source.length && source[position] != '}' && source[position] != '\n' && source[position] != '"') position++
        val format = source.substring(formatStart, position)
        if (position >= source.length || source[position] != '}') {
            return StringPiece.Hole(tokens, format, TextSpan(start, position)) to UNCLOSED_HOLE
        }
        position++
        return StringPiece.Hole(tokens, format, TextSpan(start, position)) to null
    }

    private fun isNameStart(codePoint: Int) = Character.isLetter(codePoint) || codePoint == '_'.code

    private fun isNamePart(codePoint: Int) = Character.isLetterOrDigit(codePoint) || codePoint == '_'.code

    private fun isHexDigit(char: Char) = char in '0'..'9' || char in 'a'..'f' || char in 'A'..'F'
}

private const val UNCLOSED_TEXT = "This text is never closed with \""
private const val UNCLOSED_HOLE = "This hole is never closed with }"

private val escapes =
    mapOf('n' to '\n', 't' to '\t', 'r' to '\r', 'b' to '\b', '"' to '"', '\'' to '\'', '\\' to '\\', '$' to '$')

/** [name] as formula source writes it: bare when it reads back as one identifier, between backticks otherwise. */
fun writtenName(name: String): String {
    val codePoints = name.codePoints().toArray()
    val bare =
        codePoints.isNotEmpty() &&
            name !in keywords &&
            (Character.isLetter(codePoints[0]) || codePoints[0] == '_'.code) &&
            codePoints.all { Character.isLetterOrDigit(it) || it == '_'.code }
    return if (bare) name else "`$name`"
}
