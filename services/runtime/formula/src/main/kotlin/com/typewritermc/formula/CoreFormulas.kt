package com.typewritermc.formula

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.integerScalar
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

/**
 * Functions that work on evaluation values themselves, so no provider can write them. They sit beside the provider
 * functions, so the checker resolves them like any other, and a more specific provider of the same name wins by
 * overload ranking.
 */
object CoreFormulas {
    private val value = ParameterKey(owner = TypeDefinitionId.qualified("formula", "CoreFormulas.interpolate"), index = 0)

    /** How any value enters a string template: as creator text. */
    val interpolate: FormulaFunction =
        FormulaFunction(
            name = "interpolate",
            typeParameters = listOf(TypeParameter(key = value, name = "T", bounds = emptyList())),
            signature =
                FunctionTypeTemplate(
                    context = listOf(FunctionParameterTemplate(name = "this", type = TypeTemplate.ParameterWrapper(value))),
                    parameters = emptyList(),
                    result = ScalarKind.TEXT.template,
                ),
            defaulted = emptySet(),
        ) { arguments -> display(arguments[0]) }

    private val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template

    /**
     * `1..4` is every Int from the receiver to the last, both included; empty when the last is smaller. Each item costs
     * a step, so a range longer than the steps the evaluation has left fails with StepLimit before it is built.
     */
    val rangeTo: FormulaFunction =
        FormulaFunction(
            name = "rangeTo",
            typeParameters = emptyList(),
            signature =
                FunctionTypeTemplate(
                    context = listOf(FunctionParameterTemplate(name = "this", type = int)),
                    parameters = listOf(FunctionParameterTemplate(name = "last", type = int)),
                    result = StandardTypes.list.template(listOf(int)),
                ),
            defaulted = emptySet(),
        ) { arguments ->
            val first = arguments[0] as Int
            val last = arguments[1] as Int
            if (last.toLong() - first >= remainingSteps) throw FormulaFailureException(FormulaFailure.StepLimit)
            (first..last).toList()
        }

    val functions: List<FormulaFunction> = listOf(interpolate, rangeTo)
}
