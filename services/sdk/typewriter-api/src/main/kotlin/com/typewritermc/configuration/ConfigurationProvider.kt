package com.typewritermc.configuration

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.checking.CheckRecipe
import com.typewritermc.checking.Diagnostic
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.types.TypeTemplate

data class CollectedConfiguration(
    val recipes: List<ConfigurationRecipe>,
    val checks: List<CheckRecipe>,
    val initialization: InitializationPreference? = null,
)

interface TypeConfigurationScope {
    fun initialization(preference: InitializationPreference)
}

data class NestedConfigurationScope(
    val representation: RepresentationKind,
    val expected: TypeTemplate,
    val scope: kotlin.reflect.KClass<*>,
    val expressions: ExpressionFactory<*> = GenericValueExpressionsFactory,
    val create: (ConfigurationCollectionScope) -> Any,
)

interface ConfigurationCollectionScope {
    fun initialization(preference: InitializationPreference)

    fun <S : Any> field(
        path: RelativeFieldPattern,
        representation: RepresentationKind,
        expected: TypeTemplate,
        scope: kotlin.reflect.KClass<S>,
    ): S = field(path, representation, expected, scope, emptyMap(), configurationExpressions(scope))

    fun <S : Any> field(
        path: RelativeFieldPattern,
        representation: RepresentationKind,
        expected: TypeTemplate,
        scope: kotlin.reflect.KClass<S>,
        nested: Map<FieldPatternSegment, NestedConfigurationScope>,
    ): S = field(path, representation, expected, scope, nested, configurationExpressions(scope))

    fun <S : Any> field(
        path: RelativeFieldPattern,
        representation: RepresentationKind,
        expected: TypeTemplate,
        scope: kotlin.reflect.KClass<S>,
        nested: Map<FieldPatternSegment, NestedConfigurationScope>,
        expressions: ExpressionFactory<*>,
    ): S

    fun nested(path: RelativeFieldPattern): ConfigurationCollectionScope

    fun collected(): CollectedConfiguration
}

interface ConfigurationProvider {
    fun collect(scope: ConfigurationCollectionScope): CollectedConfiguration
}

fun interface PortableConstantEncoder {
    fun encode(
        expected: TypeTemplate,
        value: Any?,
    ): com.typewritermc.types.DataValue
}

interface RuleEvaluator {
    context(reads: AuthoredReads)
    fun evaluate(
        rule: CheckedRule,
        subject: DraftBinding,
    ): RuleEvaluation
}

sealed interface RuleEvaluation {
    data object Passed : RuleEvaluation

    data class Violated(
        val findings: List<Diagnostic>,
    ) : RuleEvaluation

    data class Unavailable(
        val locations: List<ValueLocation>,
    ) : RuleEvaluation

    data class Failed(
        val diagnostic: EvaluationDiagnostic,
    ) : RuleEvaluation
}
