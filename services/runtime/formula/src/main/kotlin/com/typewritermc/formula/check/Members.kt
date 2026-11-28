package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.syntax.Name
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.closedCases
import com.typewritermc.types.function
import com.typewritermc.types.isInstantiable
import com.typewritermc.types.isUnit
import com.typewritermc.types.memberName
import com.typewritermc.types.named
import com.typewritermc.types.use
import skirout.editor.v1.type_catalog.AppliedSchema
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResolvedField
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceMatch
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

// Members on a type: a record's fields, read through any number of references, then provider functions whose first
// context slot takes the type. A Var reads as its value wherever it sits in what a field holds.

/** How many references a field read follows before it gives up, so a reference loop cannot hang the checker. */
private const val MAX_REFERENCE_HOPS = 64

/** The resolved schema of [type], or null when the catalog cannot resolve it. */
internal fun Checker.schema(type: TypeUse): AppliedSchema? =
    schemas.getOrPut(type) { (environment.resolve(type) as? Resolution.Ready)?.value?.schema }

internal fun Checker.ancestors(type: TypeUse): List<NamedTypeUse> = schema(type)?.ancestors.orEmpty()

/** [type], or the error type when it names a content type that is gone. */
internal fun Checker.normalize(type: TypeUse): TypeUse = if (mentionsMissing(type)) ERROR else type

private fun Checker.mentionsMissing(type: TypeUse): Boolean =
    when (type) {
        is TypeUse.NamedWrapper -> {
            environment.isMissing(type.value.definition) || type.value.arguments.any { mentionsMissing(it) }
        }

        is TypeUse.NullableWrapper -> {
            mentionsMissing(type.value.value)
        }

        is TypeUse.FunctionWrapper -> {
            (type.value.context + type.value.parameters).any { mentionsMissing(it.type) } ||
                mentionsMissing(type.value.result)
        }

        else -> {
            false
        }
    }

/**
 * The record a value of [type] reads its fields from: the type itself, or what its references point at. A reference to
 * a definition or to every resource names no one record, so it reads from itself as an unreadable target does.
 */
internal fun Checker.recordBehind(type: TypeUse): TypeUse {
    var current = type
    repeat(MAX_REFERENCE_HOPS) {
        val link = schema(current)?.representation as? ResolvedRepresentation.LinkWrapper ?: return current
        val target = link.value.target as? ResourceMatch.TypeWrapper ?: return current
        current = normalize(target.value.use)
    }
    return current
}

/**
 * The type of field [name] on a value of [type], read through references; each `Var` in it reads as its value. A
 * reference to a definition reads the fields that need none of its arguments; a field that needs one is reported at
 * [at], since a formula has no type for an argument the reference leaves open.
 */
internal fun Checker.fieldType(
    type: TypeUse,
    name: String,
    at: TextSpan,
): TypeUse? {
    val record = recordBehind(type)
    if (record == ERROR) return ERROR
    definitionBehind(record)?.let { return openFieldType(it, name, at) }
    val field = schema(record)?.fields?.firstOrNull { it.key == name } ?: return null
    return normalize(readType(field.type))
}

/** The definition a reference of [type] names whatever its arguments, or null when [type] is no such reference. */
private fun Checker.definitionBehind(type: TypeUse): TypeDefinitionId? {
    val link = schema(type)?.representation as? ResolvedRepresentation.LinkWrapper ?: return null
    return (link.value.target as? ResourceMatch.DefinitionWrapper)?.value
}

private fun Checker.openFieldType(
    definition: TypeDefinitionId,
    name: String,
    at: TextSpan,
): TypeUse? {
    val type = (environment.unappliedType(definition) as? Resolution.Ready)?.value ?: return null
    type.knownFields.firstOrNull { it.key == name }?.let { return normalize(readType(it.type)) }
    val waiting = (type as? ResourceType.Partial)?.schema?.dependentFields.orEmpty()
    if (waiting.none { it.owner.name == name }) return null
    report(at, "formula_open_member", "`$name` depends on a type argument this reference leaves open")
    return ERROR
}

/**
 * What a stored value of [type] reads as: every `Var` reads as its value wherever it sits, at the top, in a list, a set
 * or a map, or in another Var, so `List<Var<Int>>` reads as `List<Int>`. A record keeps its type; its Vars read as their
 * values when its fields are read.
 */
fun readType(type: TypeUse): TypeUse =
    when (type) {
        is TypeUse.NullableWrapper -> {
            readType(type.value.value).orNull()
        }

        is TypeUse.NamedWrapper -> {
            val named = type.value
            when {
                named.definition == VarDefinition.id && named.arguments.isNotEmpty() -> readType(named.arguments.first())
                named.definition in COLLECTIONS -> named.definition.use(named.arguments.map(::readType))
                else -> type
            }
        }

        else -> {
            type
        }
    }

private val COLLECTIONS = setOf(StandardTypes.list, StandardTypes.set, StandardTypes.map)

/** The case of [expected]'s closed record named [name]. */
internal fun Checker.caseNamed(
    name: String,
    expected: TypeUse?,
): TypeUse? {
    val owner = expected?.nonNull()?.takeUnless { it == ERROR } ?: return null
    val cases = schema(owner)?.representation?.closedCases() ?: return null
    val named = environment.catalogTypeNamed(name).map { it.type }
    return cases.firstOrNull { it.definition.memberName == name || it.use in named }?.use
}

/** The cases of a closed record, or null for any other type. */
internal fun Checker.closedCasesOf(type: TypeUse): List<TypeUse>? = schema(type)?.representation?.closedCases()?.map { it.use }

/** `target.name` as a value: a field, or a provider function called with the target as its first context slot. */
internal fun Checker.member(
    target: CheckedExpression,
    name: Name,
    safe: Boolean,
    expected: TypeUse?,
    scope: Scope,
    span: TextSpan,
): CheckedExpression {
    if (target.type == ERROR) return Invalid(ERROR, span)
    if (target.type.isNullable && !safe) {
        report(target.span, "formula_nullable_read", "This may be null; use `?.` or `?:`")
        return Invalid(ERROR, span)
    }
    val field = fieldType(target.type.nonNull(), name.text, name.span)
    if (field != null) {
        val type = if (safe && target.type.isNullable) field.orNull() else field
        val read = FieldRead(target, name.text, safe, type, span)
        val function = field.function
        if (function != null &&
            expected?.nonNull()?.function == null
        ) {
            return invoke(read, function, CallSite(emptyList(), expected, span, scope))
        }
        return read
    }
    val functions = environment.functions(name.text)
    if (functions.isEmpty()) {
        report(name.span, "formula_unknown_member", "${shown(recordBehind(target.type.nonNull()))} has no member `${name.text}`")
        return Invalid(ERROR, span)
    }
    return callFunctions(functions, target, CallSite(emptyList(), expected, span, scope, safe))
}

/** A record of [type] built from [arguments]: by field name, or positionally in field order. */
internal fun Checker.construct(
    type: TypeUse,
    arguments: List<CallArgument>,
    span: TextSpan,
    scope: Scope,
): CheckedExpression {
    if (type == ERROR) {
        arguments.filterIsInstance<CallArgument.Written>().forEach { infer(it.value, null, scope) }
        return Invalid(ERROR, span)
    }
    val fields = constructorFields(type, span) ?: return Invalid(ERROR, span)
    val built = mutableMapOf<String, CheckedExpression>()
    var broken = false
    arguments.forEachIndexed { position, argument ->
        val field = fieldFor(argument, position, fields, type)
        if (field == null) {
            broken = true
            return@forEachIndexed
        }
        val wanted = normalize(readType(field.type))
        val value =
            when (argument) {
                is CallArgument.Written -> infer(argument.value, wanted, scope)
                is CallArgument.Given -> argument.node
            }
        expect(value, wanted)
        built[field.key] = value
    }
    for (field in fields.filterNot { it.key in built || it.hasConstructorDefault }) {
        report(span, "formula_missing_argument", "`${field.key}` is missing")
        broken = true
    }
    return if (broken) Invalid(ERROR, span) else Construct(built, type, span)
}

/** The fields a constructor of [type] takes, or null when no value of [type] can be built directly. */
private fun Checker.constructorFields(
    type: TypeUse,
    span: TextSpan,
): List<ResolvedField>? {
    val schema = schema(type)
    val representation = schema?.representation
    if (schema == null || representation == null || !representation.isInstantiable() ||
        representation is ResolvedRepresentation.LinkWrapper
    ) {
        report(span, "formula_not_constructible", "${shown(type)} cannot be built here; build one of its cases")
        return null
    }
    return if (representation.isUnit) emptyList() else schema.fields
}

/** The field [argument] gives: its named field, or the field at its position. */
private fun Checker.fieldFor(
    argument: CallArgument,
    position: Int,
    fields: List<ResolvedField>,
    type: TypeUse,
): ResolvedField? {
    val name = argument.name
    if (name == null) {
        return fields.getOrNull(position)
            ?: null.also { report(argument.span, "formula_too_many_arguments", "${shown(type)} has no more fields") }
    }
    return fields.firstOrNull { it.key == name.text }
        ?: null.also { report(name.span, "formula_unknown_parameter", "${shown(type)} has no field `${name.text}`") }
}
