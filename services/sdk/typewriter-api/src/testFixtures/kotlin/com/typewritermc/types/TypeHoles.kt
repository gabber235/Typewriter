package com.typewritermc.types

import io.kotest.property.Arb
import io.kotest.property.arbitrary.arbitrary
import skirout.editor.v1.type_catalog.FunctionParameterTemplate
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import kotlin.random.Random

/** A generated type with one hole: [plug] puts a type at the position the generator chose for it. */
fun interface TypeHole<T> {
    fun plug(type: T): T
}

/**
 * Templates with one hole up to [depth] levels down, as a named type's argument beside other arguments, a nullable's
 * value, or any context, parameter or result slot of a function type. The other parts are scalars, named types and
 * parameters, never the definitions the `marker` namespace holds.
 */
fun Arb.Companion.templateHole(depth: Int = 4): Arb<TypeHole<TypeTemplate>> = arbitrary { it.random.hole(depth, TemplateForms) }

/** Uses with one hole, generated as [templateHole] generates templates, without parameters. */
fun Arb.Companion.useHole(depth: Int = 4): Arb<TypeHole<TypeUse>> = arbitrary { it.random.hole(depth, UseForms) }

/** How one type algebra builds each form, so templates and uses share one generator. */
private interface TypeForms<T> {
    fun Random.leaf(): T

    fun named(
        definition: TypeDefinitionId,
        arguments: List<T>,
    ): T

    fun nullable(value: T): T

    fun function(
        context: List<T>,
        parameters: List<T>,
        result: T,
    ): T
}

private object TemplateForms : TypeForms<TypeTemplate> {
    override fun Random.leaf(): TypeTemplate =
        when (nextInt(3)) {
            0 -> ScalarKind.TEXT.template
            1 -> ParameterKey(owner = TypeDefinitionId.qualified("fixture", "owner${nextInt(3)}"), index = nextInt(2)).template
            else -> TypeDefinitionId.qualified("fixture", "leaf${nextInt(4)}").namedTemplate().template
        }

    override fun named(
        definition: TypeDefinitionId,
        arguments: List<TypeTemplate>,
    ) = definition.namedTemplate(arguments).template

    override fun nullable(value: TypeTemplate) = value.nullable()

    override fun function(
        context: List<TypeTemplate>,
        parameters: List<TypeTemplate>,
        result: TypeTemplate,
    ): TypeTemplate =
        TypeTemplate.createFunction(
            context = context.mapIndexed { index, type -> FunctionParameterTemplate(name = "context$index", type = type) },
            parameters = parameters.mapIndexed { index, type -> FunctionParameterTemplate(name = "parameter$index", type = type) },
            result = result,
        )
}

private object UseForms : TypeForms<TypeUse> {
    override fun Random.leaf(): TypeUse =
        if (nextBoolean()) ScalarKind.TEXT.use else TypeDefinitionId.qualified("fixture", "leaf${nextInt(4)}").use()

    override fun named(
        definition: TypeDefinitionId,
        arguments: List<TypeUse>,
    ) = definition.use(arguments)

    override fun nullable(value: TypeUse) = value.nullable()

    override fun function(
        context: List<TypeUse>,
        parameters: List<TypeUse>,
        result: TypeUse,
    ): TypeUse =
        TypeUse.createFunction(
            context = context.mapIndexed { index, type -> FunctionParameterUse(name = "context$index", type = type) },
            parameters = parameters.mapIndexed { index, type -> FunctionParameterUse(name = "parameter$index", type = type) },
            result = result,
        )
}

private fun <T> Random.hole(
    depth: Int,
    forms: TypeForms<T>,
): TypeHole<T> {
    if (depth == 0 || nextInt(4) == 0) return TypeHole { it }
    val inner = hole(depth - 1, forms)

    fun filled(): T = hole(depth - 1, forms).plug(with(forms) { leaf() })
    return when (nextInt(3)) {
        0 -> {
            val definition = TypeDefinitionId.qualified("fixture", "named${nextInt(3)}")
            val before = List(nextInt(3)) { filled() }
            val after = List(nextInt(3)) { filled() }
            TypeHole { forms.named(definition, before + inner.plug(it) + after) }
        }

        1 -> {
            TypeHole { forms.nullable(inner.plug(it)) }
        }

        else -> {
            val slots = MutableList(nextInt(3) + nextInt(3) + 1) { filled() }
            val context = nextInt(slots.size)
            val at = nextInt(slots.size)
            TypeHole { type ->
                val parts = slots.toMutableList().also { it[at] = inner.plug(type) }
                forms.function(parts.take(context), parts.subList(context, parts.size - 1), parts.last())
            }
        }
    }
}
