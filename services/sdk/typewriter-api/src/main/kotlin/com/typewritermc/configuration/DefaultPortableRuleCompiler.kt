package com.typewritermc.configuration

import com.typewritermc.types.bigInteger
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.of
import com.typewritermc.types.catalog.resolve
import com.typewritermc.types.payload
import com.typewritermc.types.requirePortable
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.use
import skirout.editor.v1.catalog.OwnedRule
import skirout.editor.v1.diagnostic.DeclarationDiagnostic
import skirout.editor.v1.expression.BoundDirection
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.SizeBoundMetric
import skirout.editor.v1.type_catalog.DataValue
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

/** Detects contradictory recognized numeric and size bounds, without proving satisfiability of arbitrary predicates. */
class DefaultPredicateReasoner : PredicateReasoner {
    override fun contradictions(rules: List<CheckedRule>): List<DeclarationDiagnostic> =
        rules
            .groupBy { it.subject.use }
            .values
            .mapNotNull(::contradiction)

    private fun contradiction(rules: List<CheckedRule>): DeclarationDiagnostic? {
        val constraints = rules.flatMap { constraints(it.rule.descriptor.predicate) }
        val numericLower = constraints.filterIsInstance<Constraint.NumericLower>().maxWithOrNull(NUMERIC_LOWER_ORDER)
        val numericUpper = constraints.filterIsInstance<Constraint.NumericUpper>().minWithOrNull(NUMERIC_UPPER_ORDER)
        val sizeLower = constraints.filterIsInstance<Constraint.SizeLower>().maxOfOrNull(Constraint.SizeLower::value)
        val sizeUpper = constraints.filterIsInstance<Constraint.SizeUpper>().minOfOrNull(Constraint.SizeUpper::value)
        val numericConflict =
            numericLower != null && numericUpper != null &&
                (
                    numericLower.value > numericUpper.value ||
                        (
                            numericLower.value == numericUpper.value &&
                                (!numericLower.inclusive || !numericUpper.inclusive)
                        )
                )
        val sizeConflict = sizeLower != null && sizeUpper != null && sizeLower > sizeUpper
        if (!numericConflict && !sizeConflict) return null
        return DeclarationDiagnostic.of(
            rules
                .first()
                .rule.id.origin.owner,
            "contradictory_configuration_rules",
        )
    }

    private fun constraints(expression: ExpressionNode): List<Constraint> {
        val predicate =
            if (expression is ExpressionNode.OrWrapper && expression.value.left is ExpressionNode.IsNullWrapper) {
                expression.value.right
            } else {
                expression
            }
        return when (predicate) {
            is ExpressionNode.RuleNumericBoundWrapper -> {
                val value =
                    predicate.value.bound
                        .literalValue()
                        .number() ?: return emptyList()
                val inclusive =
                    predicate.value.inclusive
                        .literalValue()
                        .booleanOrTrue()
                when (predicate.value.direction) {
                    BoundDirection.MINIMUM -> listOf(Constraint.NumericLower(value, inclusive))
                    BoundDirection.MAXIMUM -> listOf(Constraint.NumericUpper(value, inclusive))
                    else -> emptyList()
                }
            }

            is ExpressionNode.RuleNumericRangeWrapper -> {
                val minimum =
                    predicate.value.minimum
                        .literalValue()
                        .number()
                val maximum =
                    predicate.value.maximum
                        .literalValue()
                        .number()
                if (minimum == null || maximum == null) {
                    emptyList()
                } else {
                    listOf(Constraint.NumericLower(minimum, true), Constraint.NumericUpper(maximum, true))
                }
            }

            is ExpressionNode.RuleSizeBoundWrapper -> {
                if (predicate.value.metric !in setOf(SizeBoundMetric.TEXT_LENGTH, SizeBoundMetric.COLLECTION_ITEMS)) return emptyList()
                val value =
                    predicate.value.bound
                        .literalValue()
                        .integer() ?: return emptyList()
                when (predicate.value.direction) {
                    BoundDirection.MINIMUM -> listOf(Constraint.SizeLower(value))
                    BoundDirection.MAXIMUM -> listOf(Constraint.SizeUpper(value))
                    else -> emptyList()
                }
            }

            else -> {
                emptyList()
            }
        }
    }
}

private sealed interface Constraint {
    data class NumericLower(
        val value: BigDecimal,
        val inclusive: Boolean,
    ) : Constraint

    data class NumericUpper(
        val value: BigDecimal,
        val inclusive: Boolean,
    ) : Constraint

    data class SizeLower(
        val value: Int,
    ) : Constraint

    data class SizeUpper(
        val value: Int,
    ) : Constraint
}

private fun ExpressionNode.literalValue(): DataValue? = (this as? ExpressionNode.LiteralWrapper)?.value?.requirePortable()

private fun DataValue?.number(): BigDecimal? =
    when (this) {
        is DataValue.IntegerWrapper -> value.toBigDecimal()
        is DataValue.DecimalWrapper -> value.toBigDecimalOrNull()
        is DataValue.FloatWrapper -> BigDecimal.valueOf(value)
        is DataValue.NamedWrapper -> payload.number()
        else -> null
    }

private fun DataValue?.integer(): Int? =
    when (this) {
        is DataValue.IntegerWrapper -> runCatching { bigInteger.intValueExact() }.getOrNull()
        is DataValue.NamedWrapper -> payload.integer()
        else -> null
    }

private fun DataValue?.booleanOrTrue(): Boolean =
    when (this) {
        is DataValue.BooleanWrapper -> value
        is DataValue.NamedWrapper -> payload.booleanOrTrue()
        else -> true
    }

private val NUMERIC_LOWER_ORDER =
    compareBy<Constraint.NumericLower> { it.value }.thenBy { if (it.inclusive) 0 else 1 }

private val NUMERIC_UPPER_ORDER =
    compareBy<Constraint.NumericUpper> { it.value }.thenBy { if (it.inclusive) 1 else 0 }
