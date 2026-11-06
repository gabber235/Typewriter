package com.typewritermc.formula.syntax

import com.typewritermc.formula.TextSpan

/**
 * The syntax tree of a formula or a written type. Every node has a [span] in UTF-16 units of the source. A part
 * that does not parse is an [Error] or [ErrorType] node with a [SyntaxProblem] at its span, so the rest of the
 * text keeps its structure while an author is still typing. The tree says nothing about what a name means; the
 * checker decides that.
 */
sealed interface FormulaNode {
    val span: TextSpan
}

/** The text that reads one line of a block: an expression, a `let` or a local function. */
sealed interface Line : FormulaNode

/** What an `if` or a `when` subject tests: a plain expression or a `let` binding. */
sealed interface Condition : FormulaNode

sealed interface Expression :
    Line,
    Condition

/** A name as written. A backticked name holds its text without the backticks; the span covers them. */
data class Name(
    val text: String,
    override val span: TextSpan,
) : Expression

data class Literal(
    val value: LiteralValue,
    override val span: TextSpan,
) : Expression

sealed interface LiteralValue {
    data class Integer(
        val value: Long,
    ) : LiteralValue

    data class Decimal(
        val value: Double,
    ) : LiteralValue

    data class Text(
        val value: String,
    ) : LiteralValue

    data class Bool(
        val value: Boolean,
    ) : LiteralValue

    data object Null : LiteralValue
}

/** A string with holes: `"Total: ${total:#,###}"`. A string without holes is a [Literal]. */
data class StringTemplate(
    val parts: List<TemplatePart>,
    override val span: TextSpan,
) : Expression

sealed interface TemplatePart : FormulaNode {
    data class Text(
        val text: String,
        override val span: TextSpan,
    ) : TemplatePart

    /** `$name` or `${value}`, with the text after a top level `:` as [format]. */
    data class Hole(
        val value: Expression,
        val format: String?,
        override val span: TextSpan,
    ) : TemplatePart
}

/** `target.name`, or `target?.name` when [safe]. */
data class Member(
    val target: Expression,
    val name: Name,
    val safe: Boolean,
    override val span: TextSpan,
) : Expression

/** `target[index]`. */
data class Index(
    val target: Expression,
    val index: Expression,
    override val span: TextSpan,
) : Expression

data class Call(
    val callee: Expression,
    val arguments: List<Argument>,
    val trailing: Lambda?,
    override val span: TextSpan,
) : Expression

/** One argument of a call, with its [name] when written as `name = value`. */
data class Argument(
    val name: Name?,
    val value: Expression,
    override val span: TextSpan,
) : FormulaNode

data class Binary(
    val operator: BinaryOperator,
    val left: Expression,
    val right: Expression,
    override val span: TextSpan,
) : Expression

/** Two or more comparisons in a row, `0 < x < 10`, meaning each neighbouring pair holds. */
data class ChainedComparison(
    val first: Expression,
    val rest: List<Pair<BinaryOperator, Expression>>,
    override val span: TextSpan,
) : Expression

data class Unary(
    val operator: UnaryOperator,
    val value: Expression,
    override val span: TextSpan,
) : Expression

/** `value is type`, or `value !is type` when [negated]. */
data class TypeTest(
    val value: Expression,
    val type: TypeNode,
    val negated: Boolean,
    override val span: TextSpan,
) : Expression

/** `value as? type`. */
data class SafeCast(
    val value: Expression,
    val type: TypeNode,
    override val span: TextSpan,
) : Expression

/** `if (c) a else b`, `c ? a : b` and `if let x = value { a } else { b }`. */
data class If(
    val condition: Condition,
    val then: Expression,
    val otherwise: Expression?,
    override val span: TextSpan,
) : Expression

/** The `let` of `if let` and `when (let x = value)`. */
data class LetCondition(
    val binding: Binding,
    val value: Expression,
    override val span: TextSpan,
) : Condition

data class When(
    val subject: Condition?,
    val arms: List<WhenArm>,
    override val span: TextSpan,
) : Expression

data class WhenArm(
    val patterns: List<WhenPattern>,
    val guard: Expression?,
    val body: Expression,
    override val span: TextSpan,
) : FormulaNode

sealed interface WhenPattern : FormulaNode {
    /** `is Type`, or `is Case(a, b)` with [bindings] for the case's fields. */
    data class Is(
        val type: TypeNode,
        val bindings: List<Binding>?,
        override val span: TextSpan,
    ) : WhenPattern

    data class In(
        val value: Expression,
        override val span: TextSpan,
    ) : WhenPattern

    /** A value the subject equals, or a condition when the `when` has no subject. */
    data class Value(
        val value: Expression,
        override val span: TextSpan,
    ) : WhenPattern

    data class Else(
        override val span: TextSpan,
    ) : WhenPattern
}

/** Lines whose value is the last one's. A formula of several lines is a block without braces. */
data class Block(
    val lines: List<Line>,
    override val span: TextSpan,
) : Expression

data class Lambda(
    val parameters: List<Binding>,
    val body: Block,
    override val span: TextSpan,
) : Expression

data class ListLiteral(
    val items: List<Expression>,
    override val span: TextSpan,
) : Expression

data class MapLiteral(
    val entries: List<Pair<Expression, Expression>>,
    override val span: TextSpan,
) : Expression

/** `.is_veteran`: a function of one value that reads the path from it. */
data class Shorthand(
    val path: List<Name>,
    override val span: TextSpan,
) : Expression

data class Error(
    val message: String,
    override val span: TextSpan,
) : Expression

/** `let binding = value`, or `let binding = value else { ... }` when the value may not match. */
data class Let(
    val binding: Binding,
    val value: Expression,
    val otherwise: Expression?,
    override val span: TextSpan,
) : Line

/** `let name(parameters): result = body`. */
data class LocalFunction(
    val name: Name,
    val parameters: List<ParameterNode>,
    val result: TypeNode?,
    val body: Expression,
    override val span: TextSpan,
) : Line

/** What a `let` or a lambda parameter introduces: one name, or a destructuring of several. */
sealed interface Binding : FormulaNode

data class NameBinding(
    val name: Name,
    val type: TypeNode?,
    override val span: TextSpan,
) : Binding

data class Destructuring(
    val parts: List<Binding>,
    override val span: TextSpan,
) : Binding

enum class BinaryOperator(
    val symbol: String,
) {
    Plus("+"),
    Minus("-"),
    Times("*"),
    Divide("/"),
    Remainder("%"),
    Less("<"),
    LessOrEqual("<="),
    Greater(">"),
    GreaterOrEqual(">="),
    Equal("=="),
    NotEqual("!="),
    And("and"),
    Or("or"),
    Elvis("?:"),
    Range(".."),
    In("in"),
    NotIn("!in"),
}

enum class UnaryOperator(
    val symbol: String,
) {
    Negate("-"),
    Not("not"),
}

sealed interface TypeNode : FormulaNode

/** `Name`, `module.Name` or `Name<Arguments>`. */
data class NamedType(
    val name: List<Name>,
    val arguments: List<TypeNode>,
    override val span: TextSpan,
) : TypeNode

data class NullableType(
    val value: TypeNode,
    override val span: TextSpan,
) : TypeNode

/** `context(c: C) (p: P) -> R`. */
data class FunctionType(
    val context: List<ParameterNode>,
    val parameters: List<ParameterNode>,
    val result: TypeNode,
    override val span: TextSpan,
) : TypeNode

data class RecordType(
    val fields: List<ParameterNode>,
    override val span: TextSpan,
) : TypeNode

/** `union { shared: Int, Case(field: Type), Other }`. */
data class UnionType(
    val fields: List<ParameterNode>,
    val cases: List<CaseNode>,
    override val span: TextSpan,
) : TypeNode

data class ErrorType(
    val message: String,
    override val span: TextSpan,
) : TypeNode

/** `name: Type`, as a function parameter or a record field. */
data class ParameterNode(
    val name: Name,
    val type: TypeNode,
    override val span: TextSpan,
) : FormulaNode

data class CaseNode(
    val name: Name,
    val fields: List<ParameterNode>,
    override val span: TextSpan,
) : FormulaNode

data class SyntaxProblem(
    val span: TextSpan,
    val message: String,
)

data class Parsed<T : FormulaNode>(
    val root: T,
    val problems: List<SyntaxProblem>,
)

/** Parses a formula. Never throws: what does not parse becomes an [Error] node and a problem. */
fun parseExpression(source: String): Parsed<Expression> = parse(source) { parseFormula() }

/** Parses a written type, such as a parameter's or a Definition's. Never throws. */
fun parseType(source: String): Parsed<TypeNode> = parse(source) { parseWholeType() }

private fun <T : FormulaNode> parse(
    source: String,
    grammar: FormulaParser.() -> T,
): Parsed<T> {
    val lexer = Lexer(source)
    val parser = FormulaParser(lexer.tokens(), mutableListOf())
    val root = parser.grammar()
    parser.finish(lexer.problems)
    return Parsed(root, parser.problems.toList())
}
