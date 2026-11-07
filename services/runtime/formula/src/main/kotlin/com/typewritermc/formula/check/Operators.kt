package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.syntax.Binary
import com.typewritermc.formula.syntax.BinaryOperator
import com.typewritermc.formula.syntax.ChainedComparison
import com.typewritermc.formula.syntax.Expression
import com.typewritermc.formula.syntax.Literal
import com.typewritermc.formula.syntax.LiteralValue
import com.typewritermc.formula.syntax.Unary
import com.typewritermc.formula.syntax.UnaryOperator
import skirout.editor.v1.type_catalog.TypeUse
import com.typewritermc.formula.syntax.SafeCast as SafeCastNode
import com.typewritermc.formula.syntax.TypeTest as TypeTestNode

// Operators. Arithmetic and comparison are provider functions (`plus`, `compareTo`); `and`, `or`, `not`, `==` and
// `?:` are the language's own.

private val operatorNames: Map<BinaryOperator, String> =
    mapOf(
        BinaryOperator.Plus to "plus",
        BinaryOperator.Minus to "minus",
        BinaryOperator.Times to "times",
        BinaryOperator.Divide to "div",
        BinaryOperator.Remainder to "rem",
        BinaryOperator.Range to "rangeTo",
    )

private val comparisons = setOf(BinaryOperator.Less, BinaryOperator.LessOrEqual, BinaryOperator.Greater, BinaryOperator.GreaterOrEqual)

internal fun Checker.binary(
    binary: Binary,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val operator = binary.operator
    return when {
        operator == BinaryOperator.And || operator == BinaryOperator.Or -> {
            Logic(operator, condition(binary.left, scope), condition(binary.right, scope), BOOLEAN, binary.span)
        }

        operator == BinaryOperator.Equal || operator == BinaryOperator.NotEqual -> {
            equality(binary.left, binary.right, operator == BinaryOperator.NotEqual, binary.span, scope)
        }

        operator == BinaryOperator.Elvis -> {
            elvis(binary, expected, scope)
        }

        operator in comparisons -> {
            compare(synthOnce(binary.left, scope), operator, binary.right, binary.span, scope)
        }

        operator == BinaryOperator.In || operator == BinaryOperator.NotIn -> {
            membership(binary, scope)
        }

        else -> {
            val name = operatorNames.getValue(operator)
            callNamed(
                name,
                synthOnce(binary.left, scope),
                listOf(written(binary.right)),
                expected,
                binary.span,
                scope,
                operator = operator.symbol,
            )
        }
    }
}

internal fun Checker.condition(
    expression: Expression,
    scope: Scope,
): CheckedExpression = infer(expression, BOOLEAN, scope).also { expect(it, BOOLEAN) }

/** `x in c` is `c.contains(x)`. */
private fun Checker.membership(
    binary: Binary,
    scope: Scope,
): CheckedExpression {
    val element = synthOnce(binary.left, scope)
    val contains =
        callNamed(
            "contains",
            synthOnce(binary.right, scope),
            listOf(CallArgument.Given(element)),
            BOOLEAN,
            binary.span,
            scope,
            operator = "in",
        )
    return if (binary.operator == BinaryOperator.NotIn) Not(contains, BOOLEAN, binary.span) else contains
}

private fun Checker.compare(
    left: CheckedExpression,
    operator: BinaryOperator,
    right: Expression,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    val comparison = callNamed("compareTo", left, listOf(written(right)), INT, span, scope, operator = operator.symbol)
    return if (comparison.type == ERROR) Invalid(ERROR, span) else Compare(comparison, operator, BOOLEAN, span)
}

/** `0 < x < 10`: each neighbouring pair holds, every operand checked once. */
internal fun Checker.chain(
    chain: ChainedComparison,
    scope: Scope,
): CheckedExpression {
    var left = synthOnce(chain.first, scope)
    var result: CheckedExpression? = null
    for ((operator, right) in chain.rest) {
        val span = TextSpan(left.span.start, right.span.end)
        val comparison = compare(left, operator, right, span, scope)
        result = result?.let { Logic(BinaryOperator.And, it, comparison, BOOLEAN, TextSpan(chain.span.start, span.end)) } ?: comparison
        left = synthOnce(right, scope)
    }
    return result ?: left
}

private fun Checker.equality(
    left: Expression,
    right: Expression,
    negated: Boolean,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    val first = synthOnce(left, scope)
    val second = infer(right, first.type.takeUnless { it == NULL }?.orNull(), scope)
    if (!comparable(first.type, second.type)) {
        report(span, "formula_type_mismatch", "A ${shown(first.type)} is never equal to a ${shown(second.type)}")
        return Invalid(ERROR, span)
    }
    return Equals(first, second, negated, BOOLEAN, span)
}

/** Whether a value of [a] can ever equal one of [b]: one fits the other, apart from null. */
internal fun Checker.comparable(
    a: TypeUse,
    b: TypeUse,
): Boolean = a == NULL || b == NULL || fits(a.nonNull(), b.nonNull()) || fits(b.nonNull(), a.nonNull())

private fun Checker.elvis(
    binary: Binary,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val left = infer(binary.left, expected?.orNull(), scope)
    val right = infer(binary.right, expected ?: left.type.nonNull().takeUnless { it == ERROR }, scope)
    val type = expected ?: join(left.type.nonNull(), right.type) ?: ERROR
    if (expected != null) expect(right, expected)
    return Elvis(left, right, type, binary.span)
}

internal fun Checker.unary(
    unary: Unary,
    expected: TypeUse?,
    scope: Scope,
): CheckedExpression {
    val value = unary.value
    return when {
        unary.operator == UnaryOperator.Not -> {
            Not(condition(value, scope), BOOLEAN, unary.span)
        }

        value is Literal && (value.value is LiteralValue.Integer || value.value is LiteralValue.Decimal) -> {
            literal(value.value, unary.span, expected, negative = true)
        }

        else -> {
            callNamed("unaryMinus", synthOnce(value, scope), emptyList(), expected, unary.span, scope, operator = "-")
        }
    }
}

internal fun Checker.typeTest(
    node: TypeTestNode,
    scope: Scope,
): CheckedExpression {
    val value = synthOnce(node.value, scope)
    val tested = lower(node.type, scope, value.type)
    typeTests[node] = tested
    return TypeTest(value, tested, node.negated, BOOLEAN, node.span)
}

internal fun Checker.safeCast(
    node: SafeCastNode,
    scope: Scope,
): CheckedExpression {
    val value = synthOnce(node.value, scope)
    val tested = lower(node.type, scope, value.type)
    return SafeCast(value, tested, if (tested == ERROR) ERROR else tested.orNull(), node.span)
}
