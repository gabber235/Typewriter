package com.typewritermc.types.catalog

import com.typewritermc.types.unknownVariant
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

fun CheckedCatalog.runtimeDefinitions(seeds: Iterable<TypeUse>): List<TypeDefinition> {
    val pending = ArrayDeque<TypeDefinitionId>()
    pending.addAll(seeds.flatMap(TypeUse::referencedDefinitions))
    val found = linkedMapOf<TypeDefinitionId, TypeDefinition>()
    while (pending.isNotEmpty()) {
        val id = pending.removeFirst()
        if (id in found) continue
        val result = declaration(id)
        check(result is Resolution.Ready) { "A referenced runtime declaration is unavailable: $id" }
        found[id] = result.value
        pending.addAll(result.value.referencedDefinitions().filterNot(found::containsKey))
    }
    return found.values.toList()
}

private fun TypeUse.referencedDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is TypeUse.NamedWrapper -> setOf(value.definition) + value.arguments.flatMap(TypeUse::referencedDefinitions)
        is TypeUse.NullableWrapper -> value.value.referencedDefinitions()
        is TypeUse.ScalarWrapper -> emptySet()
        else -> unknownVariant(this)
    }

private fun TypeTemplate.referencedDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.ParameterWrapper -> emptySet()
        is TypeTemplate.NamedWrapper -> setOf(value.definition) + value.arguments.flatMap(TypeTemplate::referencedDefinitions)
        is TypeTemplate.NullableWrapper -> value.value.referencedDefinitions()
        is TypeTemplate.ScalarWrapper -> emptySet()
        else -> unknownVariant(this)
    }

internal fun TypeDefinition.referencedDefinitions(): Set<TypeDefinitionId> {
    val roots =
        parents.map { TypeTemplate.NamedWrapper(it) } + parameters.flatMap { parameter -> parameter.bounds } + representation.templates()
    return roots.flatMapTo(linkedSetOf(), TypeTemplate::referencedDefinitions)
}

/** The type templates a representation mentions directly: field types, items, keys, values and link targets. */
internal fun RepresentationTemplate.templates(): List<TypeTemplate> =
    when (this) {
        is RepresentationTemplate.RecordWrapper -> value.fields.map { field -> field.type }
        is RepresentationTemplate.SequenceWrapper -> listOf(value.item)
        is RepresentationTemplate.MappingWrapper -> listOf(value.key, value.value)
        is RepresentationTemplate.LinkWrapper -> listOf(value.target)
        is RepresentationTemplate.ScalarWrapper, is RepresentationTemplate.EnumerationWrapper -> emptyList()
        else -> unknownVariant(this)
    }
