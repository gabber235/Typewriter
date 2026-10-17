package com.typewritermc.configuration

import com.typewritermc.expression.PortableOperationRegistry
import com.typewritermc.presentation.ExpressionNode
import com.typewritermc.types.DataValue
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.resolve
import java.math.BigDecimal

class DefaultPortableRuleCompiler(
    private val operations: PortableOperationRegistry = PortableOperationRegistry.Standard,
) : PortableRuleCompiler {
    override fun compile(
        rule: OwnedRule,
        subject: CheckedType,
    ): Resolution<CheckedRule> {
        val diagnostics =
            PortableExpressionChecker(
                subject::resolve,
                rule.id.origin.owner,
                operations,
            ).checkRule(rule.descriptor.predicate, subject)
        return if (diagnostics.isEmpty()) Resolution.Ready(CheckedRule(subject.catalog, rule, subject)) else Resolution.Invalid(diagnostics)
    }

    internal fun validateStructure(rule: OwnedRule): List<DeclarationDiagnostic> =
        PortableExpressionChecker({
            error("Structural checking does not resolve types.")
        }, rule.id.origin.owner, operations).checkRuleStructure(rule.descriptor.predicate)
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
        return DeclarationDiagnostic(
            rules
                .first()
                .rule.id.origin.owner,
            "contradictory_configuration_rules",
        )
    }

    private fun constraints(expression: ExpressionNode): List<Constraint> {
        val predicate =
            if (expression is ExpressionNode.Or && expression.left.isNullGuard()) expression.right else expression
        val call = predicate as? ExpressionNode.Call ?: return emptyList()
        val values = call.arguments.map { (it as? ExpressionNode.Literal)?.value }
        return when (call.operation.value) {
            "typewriter.rule.minimum" -> {
                values
                    .getOrNull(1)
                    ?.number()
                    ?.let {
                        listOf(Constraint.NumericLower(it, values.getOrNull(2).booleanOrTrue()))
                    }.orEmpty()
            }

            "typewriter.rule.maximum" -> {
                values
                    .getOrNull(1)
                    ?.number()
                    ?.let {
                        listOf(Constraint.NumericUpper(it, values.getOrNull(2).booleanOrTrue()))
                    }.orEmpty()
            }

            "typewriter.rule.between" -> {
                val minimum = values.getOrNull(1)?.number()
                val maximum = values.getOrNull(2)?.number()
                if (minimum == null || maximum == null) {
                    emptyList()
                } else {
                    listOf(Constraint.NumericLower(minimum, true), Constraint.NumericUpper(maximum, true))
                }
            }

            "typewriter.rule.minimumLength", "typewriter.rule.minimumItems" -> {
                values
                    .getOrNull(1)
                    ?.integer()
                    ?.let { listOf(Constraint.SizeLower(it)) }
                    .orEmpty()
            }

            "typewriter.rule.maximumLength", "typewriter.rule.maximumItems" -> {
                values
                    .getOrNull(1)
                    ?.integer()
                    ?.let { listOf(Constraint.SizeUpper(it)) }
                    .orEmpty()
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

private fun ExpressionNode.isNullGuard(): Boolean = this is ExpressionNode.Call && operation.value == "typewriter.value.is_null"

private fun DataValue?.number(): BigDecimal? =
    when (this) {
        is DataValue.Integer -> value.toBigDecimal()
        is DataValue.Decimal -> value.toBigDecimalOrNull()
        is DataValue.Float -> BigDecimal.valueOf(value)
        is DataValue.Named -> payload.number()
        else -> null
    }

private fun DataValue?.integer(): Int? =
    when (this) {
        is DataValue.Integer -> runCatching { value.intValueExact() }.getOrNull()
        is DataValue.Named -> payload.integer()
        else -> null
    }

private fun DataValue?.booleanOrTrue(): Boolean =
    when (this) {
        is DataValue.Boolean -> value
        is DataValue.Named -> payload.booleanOrTrue()
        else -> true
    }

private val NUMERIC_LOWER_ORDER =
    compareBy<Constraint.NumericLower> { it.value }.thenBy { if (it.inclusive) 0 else 1 }

private val NUMERIC_UPPER_ORDER =
    compareBy<Constraint.NumericUpper> { it.value }.thenBy { if (it.inclusive) 1 else 0 }
