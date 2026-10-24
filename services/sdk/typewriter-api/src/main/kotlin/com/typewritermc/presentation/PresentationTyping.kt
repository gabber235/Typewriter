package com.typewritermc.presentation

import com.typewritermc.configuration.ExpressionInference
import com.typewritermc.configuration.PortableExpressionChecker
import com.typewritermc.discovery.OpaqueParameters
import com.typewritermc.expression.nominalExpressionType
import com.typewritermc.expression.operations.CheckFailure
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.nullable
import com.typewritermc.types.template
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.expression.ExpressionType
import skirout.editor.v1.expression.ExpressionValueType
import skirout.editor.v1.expression.FailureId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/** A binding visible to presentation expressions: the type its reads see, and whether a read may find it missing. */
internal data class LexicalBinding(
    val type: TypeTemplate,
    val mayBeMissing: Boolean,
)

/** The inferred type of a presentation expression as a template of the material, or the failures of checking it. */
internal sealed interface TemplateInference {
    data class Typed(
        val type: TypeTemplate,
    ) : TemplateInference

    data class Failed(
        val failures: List<FailureId>,
    ) : TemplateInference
}

/**
 * Checks presentation expressions of one material with the generic expression checker.
 *
 * Templates may refer to the material's free type parameters; [opaque] closes them into opaque records that [resolve]
 * knows, so an expression is checked once for every argument and accepted only when it holds for all of them.
 */
internal class PresentationTyping(
    resolve: (TypeUse) -> Resolution<CheckedType>,
    private val opaque: OpaqueParameters,
) {
    private val checker = PortableExpressionChecker(resolve)

    /** The failures of [body] for a slot of [expected] type, which may itself be missing when [mayBeMissing]. */
    fun check(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, LexicalBinding>,
        expected: TypeTemplate,
        mayBeMissing: Boolean,
    ): List<FailureId> = checker.checkExpressionCodes(body, closed(bindings), nominalExpressionType(close(expected), mayBeMissing))

    /** The type [body] produces over [bindings], opened back into a template of the material. */
    fun infer(
        body: ExpressionNode,
        bindings: Map<ExpressionBindingId, LexicalBinding>,
    ): TemplateInference =
        when (val inference = checker.inferExpression(body, closed(bindings))) {
            is ExpressionInference.Typed -> {
                template(inference.type)?.let(TemplateInference::Typed)
                    ?: TemplateInference.Failed(listOf(CheckFailure.InvalidExpressionType))
            }

            is ExpressionInference.Failed -> {
                TemplateInference.Failed(inference.failures)
            }
        }

    private fun closed(bindings: Map<ExpressionBindingId, LexicalBinding>): Map<ExpressionBindingId, ExpressionType> =
        bindings.mapValues { (_, binding) -> nominalExpressionType(close(binding.type), binding.mayBeMissing) }

    private fun close(template: TypeTemplate): TypeUse =
        when (val applied = opaque.close(template).apply(emptyMap())) {
            is Resolution.Ready -> applied.value
            is Resolution.Invalid -> error("A closed presentation template has no free type parameters.")
        }

    /** The declared form of an expression type; entries and a bare null have none. */
    private fun template(type: ExpressionType): TypeTemplate? =
        when (val value = type.value) {
            is ExpressionValueType.NominalWrapper -> opaque.open(value.value)
            is ExpressionValueType.ListWrapper -> template(value.value)?.let { StandardTypes.list.template(listOf(it)) }
            is ExpressionValueType.MapWrapper -> mapTemplate(value.value.key, value.value.value)
            is ExpressionValueType.NullableWrapper -> template(value.value)?.nullable()
            else -> null
        }

    private fun mapTemplate(
        key: ExpressionType,
        value: ExpressionType,
    ): TypeTemplate? {
        val keyTemplate = template(key) ?: return null
        val valueTemplate = template(value) ?: return null
        return StandardTypes.map.template(listOf(keyTemplate, valueTemplate))
    }
}
