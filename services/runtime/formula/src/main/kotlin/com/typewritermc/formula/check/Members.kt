package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.VarDefinition
import com.typewritermc.formula.syntax.Name
import com.typewritermc.types.catalog.Resolution
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
import skirout.editor.v1.type_catalog.TypeUse

// Members on a type: a record's fields, read through any number of references, then provider functions whose first
// context slot takes the type. A Var field reads as its value.

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

/** The record a value of [type] reads its fields from: the type itself, or what its references point at. */
internal fun Checker.recordBehind(type: TypeUse): TypeUse {
    var current = type
    repeat(MAX_REFERENCE_HOPS) {
        val link = schema(current)?.representation as? ResolvedRepresentation.LinkWrapper ?: return current
        current = normalize(link.value.target)
    }
    return current
}

/** The type of field [name] on a value of [type], read through references; a `Var` field reads as its value. */
internal fun Checker.fieldType(
    type: TypeUse,
    name: String,
): TypeUse? {
    val record = recordBehind(type)
    if (record == ERROR) return ERROR
    val field = schema(record)?.fields?.firstOrNull { it.key == name } ?: return null
    return normalize(valueOf(field.type))
}

/** What a field of [type] gives when read: a `Var`'s value type, or the type itself. */
internal fun valueOf(type: TypeUse): TypeUse {
    val named = type.named ?: return type
    return if (named.definition == VarDefinition.id && named.arguments.isNotEmpty()) named.arguments.first() else type
}

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
    val field = fieldType(target.type.nonNull(), name.text)
    if (field != null) {
        val type = if (safe && target.type.isNullable) field.orNull() else field
        val read = FieldRead(target, name.text, safe, type, span)
        val function = field.function
        if (function != null &&
            expected?.nonNull()?.function == null
        ) {
            return invoke(read, function, emptyList(), expected, false, span, scope)
        }
        return read
    }
    val functions = environment.functions(name.text)
    if (functions.isEmpty()) {
        report(name.span, "formula_unknown_member", "${shown(recordBehind(target.type.nonNull()))} has no member `${name.text}`")
        return Invalid(ERROR, span)
    }
    return callFunctions(functions, target, emptyList(), expected, safe, span, scope)
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
        val wanted = normalize(valueOf(field.type))
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
