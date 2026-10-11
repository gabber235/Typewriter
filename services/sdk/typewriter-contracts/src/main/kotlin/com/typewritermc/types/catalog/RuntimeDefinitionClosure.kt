package com.typewritermc.types.catalog

import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse

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
        is TypeUse.Named -> setOf(definition) + arguments.flatMap(TypeUse::referencedDefinitions)
        is TypeUse.Nullable -> value.referencedDefinitions()
        is TypeUse.Scalar -> emptySet()
    }

private fun TypeTemplate.referencedDefinitions(): Set<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.Parameter -> emptySet()
        is TypeTemplate.Named -> setOf(definition) + arguments.flatMap(TypeTemplate::referencedDefinitions)
        is TypeTemplate.Nullable -> value.referencedDefinitions()
        is TypeTemplate.Scalar -> emptySet()
    }

private fun TypeDefinition.referencedDefinitions(): Set<TypeDefinitionId> {
    val roots =
        parents +
            parameters.flatMap { parameter -> parameter.bounds } +
            when (val represented = representation) {
                is RepresentationTemplate.Record -> represented.fields.map { field -> field.type }

                is RepresentationTemplate.Sequence -> listOf(represented.item)

                is RepresentationTemplate.Mapping -> listOf(represented.key, represented.value)

                is RepresentationTemplate.Link -> listOf(represented.target)

                is RepresentationTemplate.Scalar,
                is RepresentationTemplate.Enumeration,
                -> emptyList()
            }
    return roots.flatMapTo(linkedSetOf(), TypeTemplate::referencedDefinitions)
}
