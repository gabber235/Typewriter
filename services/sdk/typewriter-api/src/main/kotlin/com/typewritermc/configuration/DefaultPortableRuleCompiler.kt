package com.typewritermc.configuration

import com.typewritermc.expression.operations.PortableOperation
import com.typewritermc.expression.operations.PortableOperationCatalog
import com.typewritermc.types.bigInteger
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.duration
import com.typewritermc.types.payload
import com.typewritermc.types.use
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.expression.CallExpression
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ValuePath
import java.math.BigDecimal

class DefaultPortableRuleCompiler : PortableRuleCompiler {
    override fun compile(
        rule: OwnedRule,
        subject: CheckedType,
    ): Resolution<CheckedRule> {
        val diagnostics =
            PortableExpressionChecker(
                subject::resolve,
                rule.id.origin.owner,
            ).checkRule(rule.descriptor.predicate, subject)
        return if (diagnostics.isEmpty()) Resolution.Ready(CheckedRule(subject.catalog, rule, subject)) else Resolution.Invalid(diagnostics)
    }

    internal fun validateStructure(rule: OwnedRule): List<DeclarationDiagnostic> =
        PortableExpressionChecker({
            error("Structural checking does not resolve types.")
        }, rule.id.origin.owner).checkRuleStructure(rule.descriptor.predicate)
}

/**
 * Detects rules on one subject whose bounds contradict each other, without proving satisfiability of arbitrary
 * predicates. It reads comparisons of a subject with a literal in the shapes the comparison shortcuts lower to
 * (CompareShortcuts.kt): value.compare(subject, literal) tested with value.equals against -1, 0 or 1, optionally
 * negated with boolean.not, and value.equals(subject, literal). Conjunctions contribute every bound, value.let binds its
 * value for the body, and a disjunction with value.is_null (a rule that skips null) contributes its other side. Bounds
 * meet when their subjects are the same expression after those bindings, so text.length and collection.size subjects
 * bound sizes, and numbers, durations and timestamps each compare within their own scale.
 */
class DefaultPredicateReasoner : PredicateReasoner {
    override fun contradictions(rules: List<CheckedRule>): List<DeclarationDiagnostic> =
        rules
            .groupBy { it.subject.use }
            .values
            .filter { group -> contradicts(group.map { it.rule.descriptor.predicate }) }
            .map { group -> DeclarationDiagnostic.of(group.first().rule.id.origin.owner, "contradictory_configuration_rules") }

    /** Whether the bounds that [predicates] all require leave no value for some subject. */
    internal fun contradicts(predicates: List<ExpressionNode>): Boolean =
        predicates
            .flatMap { bounds(it, emptyList()) }
            .groupBy { it.subject }
            .values
            .any(::conflicting)

    private fun conflicting(bounds: List<Bound>): Boolean {
        val lower = bounds.filter { it.side == Side.LOWER }.maxWithOrNull(LOWER_ORDER) ?: return false
        val upper = bounds.filter { it.side == Side.UPPER }.minWithOrNull(UPPER_ORDER) ?: return false
        val order = lower.limit.compareTo(upper.limit)
        return order > 0 || (order == 0 && (!lower.inclusive || !upper.inclusive))
    }

    /** The bounds [node] requires; [scope] holds the values of enclosing value.let locals, innermost first. */
    private fun bounds(
        node: ExpressionNode,
        scope: List<ExpressionNode>,
    ): List<Bound> =
        when (node) {
            is ExpressionNode.AndWrapper -> {
                bounds(node.value.left, scope) + bounds(node.value.right, scope)
            }

            is ExpressionNode.OrWrapper -> {
                if (node.value.left.call(PortableOperationCatalog.VALUE_IS_NULL) != null) bounds(node.value.right, scope) else emptyList()
            }

            is ExpressionNode.CallWrapper -> {
                val call = node.value
                when (call.operation) {
                    PortableOperationCatalog.VALUE_LET.id -> {
                        val body = (call.arguments.getOrNull(1) as? ExpressionNode.LambdaWrapper)?.value?.body
                        if (body == null) emptyList() else bounds(body, listOf(substitute(call.arguments[0], scope)) + scope)
                    }

                    PortableOperationCatalog.BOOLEAN_NOT.id -> {
                        comparison(call.arguments.single(), negated = true, scope)
                    }

                    else -> {
                        comparison(node, negated = false, scope)
                    }
                }
            }

            else -> {
                emptyList()
            }
        }

    private fun comparison(
        node: ExpressionNode,
        negated: Boolean,
        scope: List<ExpressionNode>,
    ): List<Bound> {
        val test = node.call(PortableOperationCatalog.VALUE_EQUALS) ?: return emptyList()
        val (first, second) = test.arguments
        val compared = first.call(PortableOperationCatalog.VALUE_COMPARE)?.let { it to second } ?: second.call(PortableOperationCatalog.VALUE_COMPARE)?.let { it to first }
        if (compared == null) {
            if (negated) return emptyList()
            val (subject, limit) = subjectAndLimit(first, second, scope) ?: return emptyList()
            return listOf(Bound(subject, limit.value, Side.LOWER, true), Bound(subject, limit.value, Side.UPPER, true))
        }
        val (comparison, outcome) = compared
        val sign = outcome.literal()?.integerOrNull() ?: return emptyList()
        val (left, right) = comparison.arguments
        val (subject, limit) = subjectAndLimit(left, right, scope) ?: return emptyList()
        // compare(limit, subject) orders the other way round.
        val order = if (limit.first) -sign else sign
        return when {
            order == 0 && !negated -> listOf(Bound(subject, limit.value, Side.LOWER, true), Bound(subject, limit.value, Side.UPPER, true))
            order == 0 -> emptyList()
            order < 0 && !negated -> listOf(Bound(subject, limit.value, Side.UPPER, false))
            order < 0 -> listOf(Bound(subject, limit.value, Side.LOWER, true))
            !negated -> listOf(Bound(subject, limit.value, Side.LOWER, false))
            else -> listOf(Bound(subject, limit.value, Side.UPPER, true))
        }
    }

    /** The subject and the literal limit of a comparison of [left] with [right], in either order. */
    private fun subjectAndLimit(
        left: ExpressionNode,
        right: ExpressionNode,
        scope: List<ExpressionNode>,
    ): Pair<Subject, Limit>? {
        val rightLimit = right.literal()?.ordered()
        val leftLimit = left.literal()?.ordered()
        return when {
            rightLimit != null && leftLimit == null -> {
                Subject(substitute(left, scope), rightLimit.first) to Limit(rightLimit.second, first = false)
            }

            leftLimit != null && rightLimit == null -> {
                Subject(substitute(right, scope), leftLimit.first) to Limit(leftLimit.second, first = true)
            }

            else -> {
                null
            }
        }
    }

    /** [node] with every local of an enclosing value.let replaced by its bound value. */
    private fun substitute(
        node: ExpressionNode,
        scope: List<ExpressionNode>,
        frames: Int = 0,
    ): ExpressionNode =
        if (scope.isEmpty()) {
            node
        } else {
            when (node) {
                is ExpressionNode.LocalWrapper -> {
                    val local = node.value
                    val bound = scope.getOrNull(local.depth - frames)?.takeIf { local.depth >= frames && local.slot == 0 }
                    bound?.project(local.path) ?: node
                }

                is ExpressionNode.FieldWrapper -> {
                    ExpressionNode.createField(source = substitute(node.value.source, scope, frames), path = node.value.path)
                }

                is ExpressionNode.AndWrapper -> {
                    ExpressionNode.createAnd(
                        left = substitute(node.value.left, scope, frames),
                        right = substitute(node.value.right, scope, frames),
                    )
                }

                is ExpressionNode.OrWrapper -> {
                    ExpressionNode.createOr(
                        left = substitute(node.value.left, scope, frames),
                        right = substitute(node.value.right, scope, frames),
                    )
                }

                is ExpressionNode.ConditionalWrapper -> {
                    ExpressionNode.createConditional(
                        test = substitute(node.value.test, scope, frames),
                        then = substitute(node.value.then, scope, frames),
                        otherwise = substitute(node.value.otherwise, scope, frames),
                    )
                }

                is ExpressionNode.OrElseWrapper -> {
                    ExpressionNode.createOrElse(
                        value = substitute(node.value.value, scope, frames),
                        fallback = substitute(node.value.fallback, scope, frames),
                    )
                }

                is ExpressionNode.CallWrapper -> {
                    ExpressionNode.CallWrapper(node.value.copy(arguments = node.value.arguments.map { substitute(it, scope, frames) }))
                }

                is ExpressionNode.LambdaWrapper -> {
                    ExpressionNode.createLambda(arity = node.value.arity, body = substitute(node.value.body, scope, frames + 1))
                }

                else -> {
                    node
                }
            }
        }
}

/** A value compared with a literal, on the scale of that literal. */
private data class Subject(
    val node: ExpressionNode,
    val scale: Scale,
)

/** The scale of a literal limit: numbers of any family, durations or timestamps, all measured as decimals. */
private enum class Scale { NUMBER, DURATION, TIMESTAMP }

private enum class Side { LOWER, UPPER }

private data class Bound(
    val subject: Subject,
    val limit: BigDecimal,
    val side: Side,
    val inclusive: Boolean,
)

/** A literal limit; [first] when it is the first operand of the comparison. */
private data class Limit(
    val value: BigDecimal,
    val first: Boolean,
)

private fun ExpressionNode.call(operation: PortableOperation): CallExpression? =
    (this as? ExpressionNode.CallWrapper)?.value?.takeIf { it.operation == operation.id }

private fun ExpressionNode.literal(): DataValue? = (this as? ExpressionNode.LiteralWrapper)?.value

/** [path] projected from this bound value, extending the path of an input, local or field. */
private fun ExpressionNode.project(path: ValuePath): ExpressionNode =
    when {
        path.segments.isEmpty() -> this
        this is ExpressionNode.InputWrapper -> ExpressionNode.InputWrapper(value.copy(path = ValuePath(segments = value.path.segments + path.segments)))
        this is ExpressionNode.FieldWrapper -> ExpressionNode.FieldWrapper(value.copy(path = ValuePath(segments = value.path.segments + path.segments)))
        else -> ExpressionNode.createField(source = this, path = path)
    }

/** The position of this literal on its scale, or null when it is not a number, duration or timestamp. */
private fun DataValue.ordered(): Pair<Scale, BigDecimal>? =
    when (this) {
        is DataValue.IntegerWrapper -> Scale.NUMBER to bigInteger.toBigDecimal()
        is DataValue.DecimalWrapper -> value.toBigDecimalOrNull()?.let { Scale.NUMBER to it }
        is DataValue.FloatWrapper -> value.takeIf { it.isFinite() }?.let { Scale.NUMBER to BigDecimal(it) }
        is DataValue.DurationWrapper -> Scale.DURATION to duration.inWholeMilliseconds.toBigDecimal()
        is DataValue.TimestampWrapper -> Scale.TIMESTAMP to value.toEpochMilli().toBigDecimal()
        is DataValue.NamedWrapper -> payload.ordered()
        else -> null
    }

private fun DataValue.integerOrNull(): Int? = (this as? DataValue.IntegerWrapper)?.let { runCatching { it.bigInteger.intValueExact() }.getOrNull() }

/** The tightest lower bound sorts last: the larger limit, and at equal limits the exclusive one. */
private val LOWER_ORDER = compareBy<Bound> { it.limit }.thenBy { if (it.inclusive) 0 else 1 }

/** The tightest upper bound sorts first: the smaller limit, and at equal limits the exclusive one. */
private val UPPER_ORDER = compareBy<Bound> { it.limit }.thenBy { if (it.inclusive) 1 else 0 }
