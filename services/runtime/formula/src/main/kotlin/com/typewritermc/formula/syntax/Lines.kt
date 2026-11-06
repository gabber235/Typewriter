package com.typewritermc.formula.syntax

// Lines, blocks and the constructs that hold them: `let`, local functions, `if` and `when`.

private val changeOperators =
    setOf(
        TokenKind.Assign,
        TokenKind.PlusAssign,
        TokenKind.MinusAssign,
        TokenKind.TimesAssign,
        TokenKind.DivideAssign,
        TokenKind.QuestionAssign,
    )

private const val CHANGE_LINE = "A change line such as `x += 1` belongs in a change field; a formula only computes a value"

/** A whole formula: one expression, or a block of lines whose value is the last one's. */
internal fun FormulaParser.parseFormula(): Expression {
    val lines = parseLines(closer = null)
    val only = lines.singleOrNull()
    return when {
        lines.isEmpty() -> missingExpression()
        only is Expression -> only
        else -> Block(lines, spanFrom(lines.first().span.start, lines.last()))
    }
}

/** Lines separated by newlines or `;`, up to [closer] or the end. A line that does not end where it should keeps its parsed part. */
internal fun FormulaParser.parseLines(closer: TokenKind?): List<Line> {
    val lines = mutableListOf<Line>()
    while (true) {
        skipLineEnds()
        if (at(TokenKind.End) || (closer != null && at(closer))) return lines
        val before = position
        lines += parseLine()
        if (!atLineEnd() && !(closer != null && at(closer))) lines += parseRestOfLine()
        if (position == before && !at(TokenKind.End)) lines += unexpected("a line")
    }
}

private fun FormulaParser.parseLine(): Line = if (at(TokenKind.Let)) parseLet() else parseExpression()

private fun FormulaParser.parseRestOfLine(): Error {
    val start = peek().start
    val message = if (peek().kind in changeOperators) CHANGE_LINE else "Expected the end of the line"
    skipToStop()
    val span = spanFrom(start)
    report(span, message)
    return Error(message, span)
}

private fun FormulaParser.parseLet(): Line {
    val start = advance().start
    if (at(TokenKind.Identifier) && peekAt(1).kind == TokenKind.LeftParen) return parseLocalFunction(start)
    val binding = parseBinding()
    expect(TokenKind.Assign, "`=` and the value")
    val value = accepting(setOf(TokenKind.Else)) { parseExpression() }
    val otherwise = if (accept(TokenKind.Else) != null) parseBranch() else null
    return Let(binding, value, otherwise, spanFrom(start, otherwise ?: value))
}

private fun FormulaParser.parseLocalFunction(start: Int): LocalFunction {
    val name = name(advance())
    val parameters = parseParameterList()
    val result = if (accept(TokenKind.Colon) != null) parseType() else null
    expect(TokenKind.Assign, "`=` and the function's body")
    val body = parseExpression()
    return LocalFunction(name, parameters, result, body, spanFrom(start, body))
}

/** A name with an optional type, or `(a, b)` destructuring a record or a pair. */
internal fun FormulaParser.parseBinding(): Binding {
    val start = peek().start
    if (at(TokenKind.LeftParen)) {
        val parts = parseBindingList()
        return Destructuring(parts, spanFrom(start, parts.lastOrNull()))
    }
    val name = expectName("a name")
    val type = if (accept(TokenKind.Colon) != null) parseType() else null
    return NameBinding(name, type, spanFrom(start, type ?: name))
}

private fun FormulaParser.parseBindingList(): List<Binding> {
    advance()
    val parts =
        inside(TokenKind.RightParen, ignoreNewlines = true, accepted = setOf(TokenKind.Comma)) {
            val parts = mutableListOf<Binding>()
            while (!at(TokenKind.RightParen) && !at(TokenKind.End)) {
                parts += parseBinding()
                if (accept(TokenKind.Comma) == null) break
            }
            parts
        }
    return parts
}

/** `if (c) a else b`, and `if let x = value { a } else { b }`, whose value ends at the `{` of its branch. */
internal fun FormulaParser.parseIf(): Expression {
    val start = advance().start
    val condition = if (at(TokenKind.Let)) parseLetCondition(trailingLambdas = false) else parseParenthesizedCondition()
    val then = accepting(setOf(TokenKind.Else)) { parseBranch() }
    continueLineBefore(setOf(TokenKind.Else))
    val otherwise = if (accept(TokenKind.Else) != null) parseBranch() else null
    return If(condition, then, otherwise, spanFrom(start, otherwise ?: then))
}

private fun FormulaParser.parseParenthesizedCondition(): Expression {
    if (accept(TokenKind.LeftParen) == null) {
        reportMissing("Expected `(` and the condition")
        return withoutTrailingLambdas { parseExpression() }
    }
    val condition = inside(TokenKind.RightParen, ignoreNewlines = true, accepted = emptySet()) { parseExpression() }
    return condition
}

private fun FormulaParser.parseLetCondition(trailingLambdas: Boolean): LetCondition {
    val start = advance().start
    val binding = parseBinding()
    expect(TokenKind.Assign, "`=` and the value")
    val value = if (trailingLambdas) parseExpression() else withoutTrailingLambdas { parseExpression() }
    return LetCondition(binding, value, spanFrom(start, value))
}

/** A branch is a braced block or a single expression. */
private fun FormulaParser.parseBranch(): Expression = if (at(TokenKind.LeftBrace)) parseBraceBlock() else parseExpression()

private fun FormulaParser.parseBraceBlock(): Block {
    val start = advance().start
    val lines = inside(TokenKind.RightBrace, ignoreNewlines = false, accepted = emptySet()) { parseLines(TokenKind.RightBrace) }
    return Block(lines, spanFrom(start, lines.lastOrNull()))
}

internal fun FormulaParser.parseWhen(): Expression {
    val start = advance().start
    val subject = if (at(TokenKind.LeftParen)) parseSubject() else null
    if (expect(TokenKind.LeftBrace, "`{` and the arms of the when") == null) return When(subject, emptyList(), spanFrom(start, subject))
    val arms = inside(TokenKind.RightBrace, ignoreNewlines = false, accepted = emptySet()) { parseArms() }
    return When(subject, arms, spanFrom(start, arms.lastOrNull() ?: subject))
}

private fun FormulaParser.parseSubject(): Condition {
    advance()
    val subject =
        inside(TokenKind.RightParen, ignoreNewlines = true, accepted = emptySet()) {
            if (at(TokenKind.Let)) parseLetCondition(trailingLambdas = true) else parseExpression()
        }
    return subject
}

private fun FormulaParser.parseArms(): List<WhenArm> {
    val arms = mutableListOf<WhenArm>()
    while (true) {
        skipLineEnds()
        if (at(TokenKind.RightBrace) || at(TokenKind.End)) return arms
        val before = position
        arms += parseArm()
        if (!atLineEnd() && !at(TokenKind.RightBrace)) parseRestOfLine()
        if (position == before && !at(TokenKind.End)) unexpected("an arm")
    }
}

private val patternSeparators = setOf(TokenKind.Comma, TokenKind.Arrow, TokenKind.If)

private fun FormulaParser.parseArm(): WhenArm {
    val start = peek().start
    val patterns = mutableListOf<WhenPattern>()
    accepting(patternSeparators) {
        do {
            patterns += parsePattern()
        } while (accept(TokenKind.Comma) != null)
    }
    val guard = if (accept(TokenKind.If) != null) accepting(setOf(TokenKind.Arrow)) { parseExpression() } else null
    expect(TokenKind.Arrow, "`->` and the arm's value")
    val body = parseBranch()
    return WhenArm(patterns, guard, body, spanFrom(start, body))
}

private fun FormulaParser.parsePattern(): WhenPattern {
    val start = peek().start
    return when (peek().kind) {
        TokenKind.Else -> {
            WhenPattern.Else(advance().span)
        }

        TokenKind.Is -> {
            advance()
            val type = parseType()
            val bindings = if (peekRaw().kind == TokenKind.LeftParen) parseBindingList() else null
            WhenPattern.Is(type, bindings, spanFrom(start, bindings?.lastOrNull() ?: type))
        }

        TokenKind.In -> {
            advance()
            val value = parseExpression()
            WhenPattern.In(value, spanFrom(start, value))
        }

        else -> {
            parseExpression().let { WhenPattern.Value(it, spanFrom(start, it)) }
        }
    }
}
