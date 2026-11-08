package com.typewritermc.types.catalog

import com.typewritermc.types.FORMULA_USE
import com.typewritermc.types.closedCases
import com.typewritermc.types.template
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.walk
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

/** Every declaration a runtime needs to read values of [seeds]: what they and the declarations they reach store. */
fun CheckedCatalog.runtimeDefinitions(seeds: Iterable<TypeUse>): List<TypeDefinition> {
    val pending = ArrayDeque<TypeDefinitionId>()
    pending.addAll(seeds.flatMap { it.storedDefinitions() })
    val found = linkedMapOf<TypeDefinitionId, TypeDefinition>()
    while (pending.isNotEmpty()) {
        val id = pending.removeFirst()
        if (id in found) continue
        val result = declaration(id)
        check(result is Resolution.Ready) { "A referenced runtime declaration is unavailable: $id" }
        found[id] = result.value
        pending.addAll(result.value.storedDefinitions().filterNot(found::containsKey))
    }
    return found.values.toList()
}

/*
 * Which definitions a type names. A type names the definitions it is written with: each named type's definition and
 * each parameter's owner. A function type is written as itself, so it names only what its context, parameters and
 * result name: generated code spells it as a function type and never refers to the Formula record, so a module that
 * declares a function field needs no Formula import, and type checks and content ids see only the written types.
 *
 * A value of a function type is stored as a Formula record ([com.typewritermc.types.storedUse]). The stored
 * definitions add that record for every function type, which is what a runtime needs declared to read the value and
 * what makes a declaration depend on Formula being available. This is the one place that decides it.
 */

/** The definitions this node names itself, not counting its parts; with [stored], a function type names Formula. */
private fun TypeUse.ownDefinitions(stored: Boolean): List<TypeDefinitionId> =
    when (this) {
        is TypeUse.NamedWrapper -> listOf(value.definition)
        is TypeUse.FunctionWrapper -> if (stored) listOf(FORMULA_USE.definition) else emptyList()
        is TypeUse.NullableWrapper, is TypeUse.ScalarWrapper -> emptyList()
        else -> unknownVariant(this)
    }

/** The definitions this node names itself, not counting its parts; with [stored], a function type names Formula. */
private fun TypeTemplate.ownDefinitions(stored: Boolean): List<TypeDefinitionId> =
    when (this) {
        is TypeTemplate.NamedWrapper -> listOf(value.definition)
        is TypeTemplate.ParameterWrapper -> listOf(value.owner)
        is TypeTemplate.FunctionWrapper -> if (stored) listOf(FORMULA_USE.definition) else emptyList()
        is TypeTemplate.NullableWrapper, is TypeTemplate.ScalarWrapper -> emptyList()
        else -> unknownVariant(this)
    }

/** Every definition this use is written with, outermost first. */
fun TypeUse.referencedDefinitions(): Set<TypeDefinitionId> = walk().flatMapTo(linkedSetOf()) { it.ownDefinitions(stored = false) }

/** Every definition a value of this use needs declared: those it is written with and the Formula record of each function type. */
fun TypeUse.storedDefinitions(): Set<TypeDefinitionId> = walk().flatMapTo(linkedSetOf()) { it.ownDefinitions(stored = true) }

/** Every definition this template is written with, outermost first, including the owners of its parameters. */
fun TypeTemplate.referencedDefinitions(): Set<TypeDefinitionId> = walk().flatMapTo(linkedSetOf()) { it.ownDefinitions(stored = false) }

/** Every definition a value of this template needs declared: those it is written with and the Formula record of each function type. */
fun TypeTemplate.storedDefinitions(): Set<TypeDefinitionId> = walk().flatMapTo(linkedSetOf()) { it.ownDefinitions(stored = true) }

/** Every definition this declaration is written with: its parents, bounds, field types and closed cases. */
fun TypeDefinition.referencedDefinitions(): Set<TypeDefinitionId> = templates().flatMapTo(linkedSetOf(), TypeTemplate::referencedDefinitions)

/** Every definition values of this declaration need declared: [referencedDefinitions] plus Formula for each function type. */
fun TypeDefinition.storedDefinitions(): Set<TypeDefinitionId> = templates().flatMapTo(linkedSetOf(), TypeTemplate::storedDefinitions)

/** Every template this declaration holds: parents, then parameter bounds, then its representation's. */
private fun TypeDefinition.templates(): List<TypeTemplate> =
    parents.map { TypeTemplate.NamedWrapper(it) } + parameters.flatMap { parameter -> parameter.bounds } + representation.templates()

/** The type templates a representation mentions directly: field types, items, keys, values and link targets. */
internal fun RepresentationTemplate.templates(): List<TypeTemplate> =
    when (this) {
        is RepresentationTemplate.RecordWrapper -> value.fields.map { field -> field.type } + closedCases().orEmpty().map { it.template }
        is RepresentationTemplate.SequenceWrapper -> listOf(value.item)
        is RepresentationTemplate.MappingWrapper -> listOf(value.key, value.value)
        is RepresentationTemplate.LinkWrapper -> listOf(value.target)
        is RepresentationTemplate.ScalarWrapper -> emptyList()
        else -> unknownVariant(this)
    }
