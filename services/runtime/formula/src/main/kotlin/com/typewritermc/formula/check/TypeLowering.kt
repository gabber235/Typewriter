package com.typewritermc.formula.check

import com.typewritermc.formula.ContentReferences
import com.typewritermc.formula.syntax.ErrorType
import com.typewritermc.formula.syntax.FunctionType
import com.typewritermc.formula.syntax.Name
import com.typewritermc.formula.syntax.NamedType
import com.typewritermc.formula.syntax.NullableType
import com.typewritermc.formula.syntax.ParameterNode
import com.typewritermc.formula.syntax.RecordType
import com.typewritermc.formula.syntax.TypeNode
import com.typewritermc.formula.syntax.UnionType
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import com.typewritermc.types.named
import com.typewritermc.types.nullable
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.FunctionParameterUse
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

// Written types: scalars by their Kotlin names, the standard collections, `Ref<T>`, catalog types by source name,
// and content types through the Definition a stored reference names. Formula text names types; it cannot declare one.

private val scalars: Map<String, TypeUse> =
    mapOf(
        "Int" to integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use,
        "Long" to integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR).use,
        "Float" to floatScalar(FloatWidth.THIRTY_TWO).use,
        "Double" to floatScalar(FloatWidth.SIXTY_FOUR).use,
        "Decimal" to ScalarKind.DECIMAL.use,
        "String" to ScalarKind.TEXT.use,
        "Boolean" to ScalarKind.BOOLEAN.use,
        "Instant" to ScalarKind.TIMESTAMP.use,
        "Duration" to ScalarKind.DURATION.use,
        "Unit" to ScalarKind.UNIT.use,
        "Type" to ScalarKind.TYPE.use,
    )

/** Generic types every formula can name, with their argument count. */
private val generics: Map<String, Pair<TypeDefinitionId, Int>> =
    mapOf(
        "List" to (StandardTypes.list to 1),
        "Set" to (StandardTypes.set to 1),
        "Map" to (StandardTypes.map to 2),
        "Ref" to (ContentReferences.Source.Definition.id to 1),
    )

/** A scalar named by its Kotlin name. */
internal fun builtinType(name: String): TypeUse? = scalars[name]

/** The type [node] writes. [cases] is a type whose cases a bare name may name first, as a `when` subject's. */
internal fun Checker.lower(
    node: TypeNode,
    scope: Scope,
    cases: TypeUse? = null,
): TypeUse =
    when (node) {
        is NamedType -> lowerNamed(node, scope, cases)
        is NullableType -> lower(node.value, scope, cases).let { if (it == ERROR) it else it.nullable() }
        is FunctionType -> lowerFunction(node, scope)
        is RecordType, is UnionType -> inlineType(node)
        is ErrorType -> ERROR
    }

private fun Checker.inlineType(node: TypeNode): TypeUse {
    report(node.span, "formula_inline_type", "A formula names types and cannot declare one; declare it in a Definition")
    return ERROR
}

private fun Checker.lowerFunction(
    node: FunctionType,
    scope: Scope,
): TypeUse {
    fun slots(parameters: List<ParameterNode>) = parameters.map { FunctionParameterUse(name = it.name.text, type = lower(it.type, scope)) }
    val context = slots(node.context)
    val parameters = slots(node.parameters)
    val result = lower(node.result, scope)
    return TypeUse.createFunction(context = context, parameters = parameters, result = result)
}

private fun Checker.lowerNamed(
    node: NamedType,
    scope: Scope,
    cases: TypeUse?,
): TypeUse {
    val arguments = node.arguments.map { lower(it, scope) }
    if (node.name.size > 1) return lowerQualified(node, arguments)
    val name = node.name.single()
    caseNamed(name.text, cases)?.let { case ->
        answer(name, NameMeaning.Case, emptyList())
        return case
    }
    referenceAt[name.span]?.let { stored ->
        return stored.target?.let { lowerStored(node, name, it, arguments) }
            ?: emptied(name).let { ERROR }
    }
    return lowerByText(node, name, arguments)
}

/** `citizens.Npc`: a catalog type qualified by its extension. */
private fun Checker.lowerQualified(
    node: NamedType,
    arguments: List<TypeUse>,
): TypeUse {
    val text = node.name.joinToString(".") { it.text }
    val types = environment.catalogTypeNamed(text)
    return when (types.size) {
        1 -> applyArguments(node, types.single(), arguments)
        0 -> unknownType(node, text)
        else -> ambiguousType(node, text)
    }
}

/** A type name with a stored reference: the type its `Definition<Type>` holds. */
private fun Checker.lowerStored(
    node: NamedType,
    name: Name,
    target: ResourceId,
    arguments: List<TypeUse>,
): TypeUse {
    answer(name, NameMeaning.Resource(target), emptyList())
    val naming = environment.reference(target) ?: return ERROR
    if (naming != TYPE_VALUE) {
        report(name.span, "formula_not_a_type", "`${name.text}` is not a type")
        return ERROR
    }
    val held = environment.typeValue(target)?.let(::normalize)
    if (held == null) {
        report(name.span, "formula_type_not_plain", "`${name.text}` holds a formula, not a plain type, so it cannot be used as a type")
        return ERROR
    }
    return applyArguments(node, held, arguments)
}

/** A type name with no stored reference: a scalar, a standard generic, or a catalog type by its source name. */
private fun Checker.lowerByText(
    node: NamedType,
    name: Name,
    arguments: List<TypeUse>,
): TypeUse {
    val candidates = environment.inScope(name.text)
    val builtin = scalars[name.text] ?: generics[name.text]?.let { (id, count) -> generic(node, id, count, arguments) }
    if (builtin != null) {
        answer(name, NameMeaning.CatalogType, candidates)
        return builtin
    }
    val types = environment.catalogTypeNamed(name.text)
    answer(name, if (types.isEmpty()) NameMeaning.Unknown else NameMeaning.CatalogType, candidates)
    return when {
        types.size == 1 -> applyArguments(node, types.single(), arguments)
        types.size > 1 -> ambiguousType(node, name.text)
        candidates.size > 1 -> unknown(name, candidates).let { ERROR }
        else -> unknownType(node, name.text)
    }
}

private fun Checker.generic(
    node: NamedType,
    id: TypeDefinitionId,
    count: Int,
    arguments: List<TypeUse>,
): TypeUse {
    if (arguments.size != count) {
        report(node.span, "formula_type_arguments", "`${node.name.single().text}` takes $count type argument${if (count == 1) "" else "s"}")
        return ERROR
    }
    return id.use(arguments)
}

/** [type] with the written [arguments], checked against the catalog. */
private fun Checker.applyArguments(
    node: NamedType,
    type: TypeUse,
    arguments: List<TypeUse>,
): TypeUse {
    if (arguments.isEmpty() || type == ERROR) return type
    val named = type.named
    if (named == null || named.arguments.isNotEmpty()) {
        report(node.span, "formula_type_arguments", "This type takes no type arguments")
        return ERROR
    }
    val applied = named.definition.use(arguments)
    if (arguments.any { it == ERROR }) return ERROR
    if (environment.resolve(applied) is Resolution.Invalid) {
        report(node.span, "formula_type_arguments", "These type arguments do not fit this type")
        return ERROR
    }
    return applied
}

private fun Checker.unknownType(
    node: NamedType,
    text: String,
): TypeUse {
    report(node.span, "formula_unknown_type", "There is no type `$text`")
    return ERROR
}

private fun Checker.ambiguousType(
    node: NamedType,
    text: String,
): TypeUse {
    report(node.span, "formula_ambiguous_type", "Several types are named `$text`; qualify it by its extension")
    return ERROR
}
