package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan

// The type grammar: named and generic types, nullable types, function types with context, records and unions.

private const val FUNCTION_NEEDS_NAMES = "A function type names its parameters, as in `(level: Int) -> Int`"

/** A written type. `?` makes it nullable only when it touches the type, so `x is Open ? a : b` stays a ternary. */
internal fun FormulaParser.parseType(): TypeNode =
    nested(tooDeep = { ErrorType("This type nests too deeply", it) }) {
        val start = peek().start
        val type = parseTypePrimary()
        if (peekRaw().kind == TokenKind.Question && peekRaw().start == previousEnd) {
            while (peekRaw().kind == TokenKind.Question && peekRaw().start == previousEnd) advance()
            NullableType(type, spanFrom(start, type))
        } else {
            type
        }
    }

/** Words that start a type form when the bracket they need follows; otherwise they are ordinary type names. */
private val typeForms: Map<String, Pair<TokenKind, FormulaParser.() -> TypeNode>> =
    mapOf(
        "context" to (TokenKind.LeftParen to { parseContextFunctionType() }),
        "record" to (TokenKind.LeftBrace to { parseRecordType() }),
        "union" to (TokenKind.LeftBrace to { parseUnionType() }),
    )

private fun FormulaParser.parseTypePrimary(): TypeNode {
    val token = peek()
    val word = token.text.takeIf { token.kind == TokenKind.Identifier }
    val form = word?.let { typeForms[it] }?.takeIf { peekAt(1).kind == it.first }
    return when {
        token.kind == TokenKind.LeftParen -> parseFunctionType(token.start, context = emptyList())
        form != null -> form.second(this)
        word != null -> parseNamedType()
        atStop() -> ErrorType("Expected a type", TextSpan(token.start, token.start)).also { reportMissing(it.message) }
        else -> unexpected("a type").let { ErrorType(it.message, it.span) }
    }
}

private fun FormulaParser.parseNamedType(): NamedType {
    val start = peek().start
    val path = mutableListOf(name(advance()))
    while (at(TokenKind.Dot) && peekAt(1).kind == TokenKind.Identifier && fits(path.size)) {
        advance()
        path += name(advance())
    }
    if (peekRaw().kind != TokenKind.Less) return NamedType(path, emptyList(), spanFrom(start, path.last()))
    advance()
    val arguments =
        inside(TokenKind.Greater, ignoreNewlines = true, accepted = setOf(TokenKind.Comma)) {
            val arguments = mutableListOf<TypeNode>()
            while (!at(TokenKind.Greater) && !at(TokenKind.End)) {
                arguments += parseType()
                if (accept(TokenKind.Comma) == null) break
            }
            arguments
        }
    return NamedType(path, arguments, spanFrom(start, arguments.lastOrNull()))
}

private fun FormulaParser.parseContextFunctionType(): TypeNode {
    val start = advance().start
    val context = parseParameterList()
    if (!at(TokenKind.LeftParen)) {
        reportMissing("Expected the function's parameters, as in `context(c: C) () -> Int`")
        return ErrorType("Expected the function's parameters", spanFrom(start))
    }
    return parseFunctionType(start, context)
}

/** At `(`: a function type's parameters, or a type in brackets. */
private fun FormulaParser.parseFunctionType(
    start: Int,
    context: List<ParameterNode>,
): TypeNode {
    val parameters =
        if (peekAt(1).kind == TokenKind.RightParen || (peekAt(1).kind == TokenKind.Identifier && peekAt(2).kind == TokenKind.Colon)) {
            parseParameterList()
        } else {
            val inner = parseBracketedType()
            if (!at(TokenKind.Arrow)) return inner
            report(inner.span, FUNCTION_NEEDS_NAMES)
            emptyList()
        }
    expect(TokenKind.Arrow, "`->` and the function's result")
    val result = parseType()
    return FunctionType(context, parameters, result, spanFrom(start, result))
}

private fun FormulaParser.parseBracketedType(): TypeNode {
    advance()
    val inner = inside(TokenKind.RightParen, ignoreNewlines = true, accepted = emptySet()) { parseType() }
    return inner
}

/** `(name: Type, ...)` for a function's parameters or a union case's fields. */
internal fun FormulaParser.parseParameterList(): List<ParameterNode> {
    advance()
    val parameters =
        inside(TokenKind.RightParen, ignoreNewlines = true, accepted = setOf(TokenKind.Comma)) {
            val parameters = mutableListOf<ParameterNode>()
            while (!at(TokenKind.RightParen) && !at(TokenKind.End)) {
                parameters += parseParameter()
                if (accept(TokenKind.Comma) == null) break
            }
            parameters
        }
    return parameters
}

private fun FormulaParser.parseParameter(): ParameterNode {
    val start = peek().start
    val name = expectName("a name")
    val type =
        if (accept(TokenKind.Colon) != null) {
            parseType()
        } else {
            reportMissing("Expected `:` and a type")
            ErrorType("Expected `:` and a type", TextSpan(peek().start, peek().start))
        }
    return ParameterNode(name, type, spanFrom(start, type))
}

private fun FormulaParser.parseRecordType(): RecordType {
    val start = advance().start
    val fields = parseMembers { parseParameter() }
    return RecordType(fields, spanFrom(start, fields.lastOrNull()))
}

/** A union's members: a shared field is `name: Type`, a case is `Name` or `Name(field: Type)`. */
private fun FormulaParser.parseUnionType(): UnionType {
    val start = advance().start
    val members =
        parseMembers {
            if (at(TokenKind.Identifier) && peekAt(1).kind == TokenKind.Colon) parseParameter() else parseCase()
        }
    return UnionType(members.filterIsInstance<ParameterNode>(), members.filterIsInstance<CaseNode>(), spanFrom(start, members.lastOrNull()))
}

private fun FormulaParser.parseCase(): CaseNode {
    val start = peek().start
    val name = expectName("a case name")
    val fields = if (peekRaw().kind == TokenKind.LeftParen) parseParameterList() else emptyList()
    return CaseNode(name, fields, spanFrom(start, fields.lastOrNull() ?: name))
}

/** `{ member, member }` with commas or newlines between members. */
private fun <T : FormulaNode> FormulaParser.parseMembers(member: () -> T): List<T> {
    advance()
    val members =
        inside(TokenKind.RightBrace, ignoreNewlines = false, accepted = setOf(TokenKind.Comma)) {
            val members = mutableListOf<T>()
            while (true) {
                while (accept(TokenKind.Comma) != null || (atLineEnd() && !at(TokenKind.End))) skipLineEnds()
                if (at(TokenKind.RightBrace) || at(TokenKind.End)) break
                val before = position
                members += member()
                if (position == before) unexpected("a field")
            }
            members
        }
    return members
}

/** A whole written type, such as a Definition's. */
internal fun FormulaParser.parseWholeType(): TypeNode {
    skipLineEnds()
    return parseType()
}
