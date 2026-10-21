package com.typewritermc.configuration

import com.typewritermc.checking.CheckRecipe
import com.typewritermc.expression.ExpressionFactory
import skirout.editor.v1.catalog.ConfigurationRecipe
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.RelativeFieldPattern
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.ValueLocation

data class CollectedConfiguration(
    val recipes: List<ConfigurationRecipe>,
    val checks: List<CheckRecipe>,
)

data class NestedConfigurationScope(
    val representation: RepresentationKind,
    val expected: TypeTemplate,
    val scope: kotlin.reflect.KClass<*>,
    val expressions: ExpressionFactory<*> = GenericValueExpressionsFactory,
    val create: (ConfigurationCollectionScope) -> Any,
)

interface ConfigurationCollectionScope {
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
    ): skirout.editor.v1.type_catalog.DataValue
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
