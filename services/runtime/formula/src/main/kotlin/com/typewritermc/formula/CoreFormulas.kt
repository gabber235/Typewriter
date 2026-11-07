package com.typewritermc.formula

import com.typewritermc.types.qualified
import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionTypeTemplate
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

    val functions: List<FormulaFunction> = listOf(interpolate)
}
