package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan

// The expression grammar: a Pratt parser for operators, recursive descent for everything else.

private const val TERNARY = 1
private const val OR = 2
private const val AND = 3
private const val EQUALITY = 4
private const val COMPARISON = 5
private const val NAMED_CHECK = 6
private const val ELVIS = 7
private const val RANGE = 8
private const val ADDITIVE = 9
private const val MULTIPLICATIVE = 10
private const val CAST = 11

private class InfixRule(
    val precedence: Int,
    val parse: FormulaParser.(left: Expression, start: Int) -> Expression,
)

private fun binary(
    operator: BinaryOperator,
    precedence: Int,
    rightAssociative: Boolean = false,
) = InfixRule(precedence) { left, start ->
    advance()
    skipNewlines()
    val right = parseBinary(if (rightAssociative) precedence else precedence + 1)
    Binary(operator, left, right, spanFrom(start, right))
}

private val comparisons =
    mapOf(
        TokenKind.Less to BinaryOperator.Less,
        TokenKind.LessOrEqual to BinaryOperator.LessOrEqual,
        TokenKind.Greater to BinaryOperator.Greater,
        TokenKind.GreaterOrEqual to BinaryOperator.GreaterOrEqual,
    )

/** `0 < x < 10` is one chain, not `(0 < x) < 10`. */
private val comparison =
    InfixRule(COMPARISON) { left, start ->
        val rest = mutableListOf<Pair<BinaryOperator, Expression>>()
        while (peek().kind in comparisons) {
            val operator = comparisons.getValue(advance().kind)
            skipNewlines()
            rest += operator to parseBinary(COMPARISON + 1)
        }
        val (operator, right) = rest.first()
        if (rest.size == 1) {
            Binary(operator, left, right, spanFrom(start, right))
        } else {
            ChainedComparison(left, rest, spanFrom(start, rest.last().second))
        }
    }

private val ternary =
    InfixRule(TERNARY) { condition, start ->
        advance()
        skipNewlines()
        val then = accepting(setOf(TokenKind.Colon)) { parseBinary(TERNARY) }
        expect(TokenKind.Colon, "`:` and the value when the condition is false")
        skipNewlines()
        val otherwise = parseBinary(TERNARY)
        If(condition, then, otherwise, spanFrom(start, otherwise))
    }

private fun typeTest(negated: Boolean) =
    InfixRule(NAMED_CHECK) { value, start ->
        advance()
        val type = parseType()
        TypeTest(value, type, negated, spanFrom(start, type))
    }

private val safeCast =
    InfixRule(CAST) { value, start ->
        advance()
        val type = parseType()
        SafeCast(value, type, spanFrom(start, type))
    }

private val infixRules: Map<TokenKind, InfixRule> =
    mapOf(
        TokenKind.Question to ternary,
        TokenKind.OrOr to binary(BinaryOperator.Or, OR),
        TokenKind.Or to binary(BinaryOperator.Or, OR),
        TokenKind.AndAnd to binary(BinaryOperator.And, AND),
        TokenKind.And to binary(BinaryOperator.And, AND),
        TokenKind.EqualEqual to binary(BinaryOperator.Equal, EQUALITY),
        TokenKind.NotEqual to binary(BinaryOperator.NotEqual, EQUALITY),
        TokenKind.In to binary(BinaryOperator.In, NAMED_CHECK),
        TokenKind.NotIn to binary(BinaryOperator.NotIn, NAMED_CHECK),
        TokenKind.Is to typeTest(negated = false),
        TokenKind.NotIs to typeTest(negated = true),
        TokenKind.Elvis to binary(BinaryOperator.Elvis, ELVIS, rightAssociative = true),
        TokenKind.Range to binary(BinaryOperator.Range, RANGE),
        TokenKind.Plus to binary(BinaryOperator.Plus, ADDITIVE),
        TokenKind.Minus to binary(BinaryOperator.Minus, ADDITIVE),
        TokenKind.Star to binary(BinaryOperator.Times, MULTIPLICATIVE),
        TokenKind.Slash to binary(BinaryOperator.Divide, MULTIPLICATIVE),
        TokenKind.Percent to binary(BinaryOperator.Remainder, MULTIPLICATIVE),
        TokenKind.SafeAs to safeCast,
    ) + comparisons.keys.associateWith { comparison }

/** Operators that continue the line before them when they start the next one, as in Kotlin. */
private val lineContinuations = setOf(TokenKind.Elvis, TokenKind.AndAnd, TokenKind.OrOr, TokenKind.And, TokenKind.Or)
private val memberContinuations = setOf(TokenKind.Dot, TokenKind.SafeDot)

private fun tooDeep(span: TextSpan) = Error("This part nests too deeply", span)

internal fun FormulaParser.parseExpression(): Expression = parseBinary(0)

/** Operators binding at least as tight as [minPrecedence], left to right. Each step deepens the tree by one. */
internal fun FormulaParser.parseBinary(minPrecedence: Int): Expression =
    nested(tooDeep = ::tooDeep) {
        val start = peek().start
        var left = parsePrefix()
        var steps = 0
        while (true) {
            continueLineBefore(lineContinuations)
            val rule = infixRules[peek().kind]?.takeIf { it.precedence >= minPrecedence } ?: break
            steps++
            val operand = left
            left = nested(steps, { tooDeep(TextSpan(start, it.end)) }) { rule.parse(this, operand, start) }
        }
        left
    }

private fun FormulaParser.parsePrefix(): Expression =
    nested(tooDeep = ::tooDeep) {
        val start = peek().start
        val operator =
            when (peek().kind) {
                TokenKind.Minus -> UnaryOperator.Negate
                TokenKind.Bang, TokenKind.Not -> UnaryOperator.Not
                else -> null
            }
        if (operator == null) {
            parsePostfix(start, parsePrimary())
        } else {
            advance()
            val value = parsePrefix()
            Unary(operator, value, spanFrom(start, value))
        }
    }

/** Members, calls, indexing and trailing lambdas after a value. A bracket must start on the value's line. */
private fun FormulaParser.parsePostfix(
    start: Int,
    first: Expression,
): Expression {
    var value = first
    var steps = 0
    while (true) {
        continueLineBefore(memberContinuations)
        val step = postfixStep() ?: return value
        steps++
        val target = value
        value = nested(steps, { tooDeep(TextSpan(start, it.end)) }) { step(target, start) }
    }
}

private fun FormulaParser.postfixStep(): (FormulaParser.(Expression, Int) -> Expression)? =
    when {
        at(TokenKind.Dot) || at(TokenKind.SafeDot) -> FormulaParser::parseMember
        peekRaw().kind == TokenKind.LeftParen -> FormulaParser::parseCall
        peekRaw().kind == TokenKind.LeftBracket -> FormulaParser::parseIndex
        peekRaw().kind == TokenKind.LeftBrace && trailingLambdas -> FormulaParser::parseTrailingLambda
        else -> null
    }

private fun FormulaParser.parseMember(
    target: Expression,
    start: Int,
): Expression {
    val safe = advance().kind == TokenKind.SafeDot
    skipNewlines()
    val name = expectName("a member name")
    return Member(target, name, safe, spanFrom(start, name))
}

private fun FormulaParser.parseCall(
    callee: Expression,
    start: Int,
): Expression {
    advance()
    val arguments =
        inside(TokenKind.RightParen, ignoreNewlines = true, accepted = setOf(TokenKind.Comma)) {
            val arguments = mutableListOf<Argument>()
            while (!at(TokenKind.RightParen) && !at(TokenKind.End)) {
                arguments += parseArgument()
                if (accept(TokenKind.Comma) == null) break
            }
            arguments
        }
    val trailing = if (peekRaw().kind == TokenKind.LeftBrace && trailingLambdas) parseLambda() else null
    return Call(callee, arguments, trailing, spanFrom(start, trailing ?: arguments.lastOrNull()))
}

private fun FormulaParser.parseArgument(): Argument {
    val start = peek().start
    val name =
        if (at(TokenKind.Identifier) && peekAt(1).kind == TokenKind.Assign) {
            name(advance()).also { advance() }
        } else {
            null
        }
    val value = parseExpression()
    return Argument(name, value, spanFrom(start, value))
}

private fun FormulaParser.parseIndex(
    target: Expression,
    start: Int,
): Expression {
    advance()
    val index = inside(TokenKind.RightBracket, ignoreNewlines = true, accepted = emptySet()) { parseExpression() }
    return Index(target, index, spanFrom(start, index))
}

private fun FormulaParser.parseTrailingLambda(
    callee: Expression,
    start: Int,
): Expression {
    val lambda = parseLambda()
    return if (callee is Call && callee.trailing == null) {
        callee.copy(trailing = lambda, span = spanFrom(start, lambda))
    } else {
        Call(callee, emptyList(), lambda, spanFrom(start, lambda))
    }
}

private val primaryRules: Map<TokenKind, FormulaParser.() -> Expression> =
    mapOf(
        TokenKind.Identifier to { name(advance()) },
        TokenKind.Integer to { parseInteger() },
        TokenKind.Decimal to { parseDecimal() },
        TokenKind.True to { Literal(LiteralValue.Bool(true), advance().span) },
        TokenKind.False to { Literal(LiteralValue.Bool(false), advance().span) },
        TokenKind.Null to { Literal(LiteralValue.Null, advance().span) },
        TokenKind.Text to { parseString() },
        TokenKind.LeftParen to { parseParenthesized() },
        TokenKind.LeftBracket to { parseCollection() },
        TokenKind.LeftBrace to { parseLambda() },
        TokenKind.If to { parseIf() },
        TokenKind.When to { parseWhen() },
        TokenKind.Dot to { parseShorthand() },
    )

/** The lexer reports a number too large for a whole number when the token is consumed. */
private fun FormulaParser.parseInteger(): Expression {
    val token = advance()
    val value = token.text.toLongOrNull() ?: return Error("This number is too large", token.span)
    return Literal(LiteralValue.Integer(value), token.span)
}

/** The lexer reports an exponent no Decimal can hold when the token is consumed. */
private fun FormulaParser.parseDecimal(): Expression {
    val token = advance()
    val value = token.text.toBigDecimalOrNull() ?: return Error("This exponent is too large", token.span)
    return Literal(LiteralValue.Decimal(value), token.span)
}

private fun FormulaParser.parsePrimary(): Expression {
    val rule = primaryRules[peek().kind]
    return when {
        rule != null -> rule()
        atStop() -> missingExpression()
        else -> unexpected("a value")
    }
}

private fun FormulaParser.parseParenthesized(): Expression {
    advance()
    val value = inside(TokenKind.RightParen, ignoreNewlines = true, accepted = emptySet()) { parseExpression() }
    return value
}

/** `[a, b]` is a list, `[a: 1]` a map, and `[:]` the empty map. */
private fun FormulaParser.parseCollection(): Expression {
    val start = advance().start
    val collection =
        inside(TokenKind.RightBracket, ignoreNewlines = true, accepted = setOf(TokenKind.Comma, TokenKind.Colon)) {
            when {
                accept(TokenKind.Colon) != null -> MapLiteral(emptyList(), spanFrom(start))
                at(TokenKind.RightBracket) -> ListLiteral(emptyList(), spanFrom(start))
                else -> parseItems(start, parseExpression())
            }
        }
    return when (collection) {
        is MapLiteral -> collection.copy(span = spanFrom(start, collection.entries.lastOrNull()?.second))
        is ListLiteral -> collection.copy(span = spanFrom(start, collection.items.lastOrNull()))
        else -> collection
    }
}

private fun FormulaParser.parseItems(
    start: Int,
    first: Expression,
): Expression {
    if (accept(TokenKind.Colon) == null) {
        val items = mutableListOf(first)
        while (accept(TokenKind.Comma) != null && !at(TokenKind.RightBracket)) items += parseExpression()
        return ListLiteral(items, spanFrom(start))
    }
    val entries = mutableListOf(first to parseExpression())
    while (accept(TokenKind.Comma) != null && !at(TokenKind.RightBracket)) {
        val key = parseExpression()
        expect(TokenKind.Colon, "`:` and the entry's value")
        entries += key to parseExpression()
    }
    return MapLiteral(entries, spanFrom(start))
}

/** `.is_veteran` or `.stats.coins`. */
private fun FormulaParser.parseShorthand(): Expression {
    val start = advance().start
    val path = mutableListOf(expectName("a member name"))
    while (at(TokenKind.Dot) && fits(path.size + 1)) {
        advance()
        path += expectName("a member name")
    }
    return Shorthand(path, spanFrom(start, path.last()))
}

private fun FormulaParser.parseString(): Expression {
    val token = advance()
    if (token.pieces.none { it is StringPiece.Hole }) {
        val text = token.pieces.joinToString("") { (it as StringPiece.Chars).text }
        return Literal(LiteralValue.Text(text), token.span)
    }
    val parts =
        token.pieces.map { piece ->
            when (piece) {
                is StringPiece.Chars -> TemplatePart.Text(piece.text, piece.span)
                is StringPiece.Hole -> TemplatePart.Hole(forHole(piece.tokens).parseHole(), piece.format, piece.span)
            }
        }
    return StringTemplate(parts, token.span)
}

private fun FormulaParser.parseHole(): Expression =
    inside(TokenKind.RightBrace, ignoreNewlines = true, accepted = emptySet(), closes = false) {
        val value = if (at(TokenKind.End)) missingExpression() else parseExpression()
        if (!at(TokenKind.End)) {
            val start = peek().start
            while (!at(TokenKind.End)) advance()
            report(spanFrom(start), "Expected `}` to close the hole")
        }
        value
    }

/** Tokens that may stand between `{` and `->` in a lambda's parameters. */
private val parameterTokens =
    setOf(
        TokenKind.Identifier,
        TokenKind.Comma,
        TokenKind.Colon,
        TokenKind.LeftParen,
        TokenKind.RightParen,
        TokenKind.Less,
        TokenKind.Greater,
        TokenKind.Question,
        TokenKind.Dot,
        TokenKind.Newline,
    )

internal fun FormulaParser.parseLambda(): Lambda {
    val start = advance().start
    val (parameters, body) =
        inside(TokenKind.RightBrace, ignoreNewlines = false, accepted = emptySet()) {
            val parameters = if (scanReaches(parameterTokens, TokenKind.Arrow)) parseLambdaParameters() else emptyList()
            val bodyStart = peek().start
            val lines = parseLines(TokenKind.RightBrace)
            parameters to Block(lines, spanFrom(bodyStart, lines.lastOrNull()))
        }
    return Lambda(parameters, body, spanFrom(start, body))
}

private fun FormulaParser.parseLambdaParameters(): List<Binding> {
    skipNewlines()
    val parameters = mutableListOf<Binding>()
    accepting(setOf(TokenKind.Comma, TokenKind.Arrow)) {
        if (!at(TokenKind.Arrow)) {
            do {
                parameters += parseBinding()
            } while (accept(TokenKind.Comma) != null)
        }
    }
    expect(TokenKind.Arrow, "`->` after the lambda's parameters")
    return parameters
}
