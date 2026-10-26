package com.typewritermc.testkit

import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

@DslMarker
annotation class CatalogDsl

/**
 * Type definitions for planner and checker cases that no real catalog declares, such as a set of a scalar or a link
 * whose endpoint is a type parameter. Content of real types is authored with setups instead.
 */
fun definitions(block: CatalogDefinitions.() -> Unit): List<TypeDefinition> = CatalogDefinitions().apply(block).definitions

@CatalogDsl
class CatalogDefinitions internal constructor() {
    internal val definitions = mutableListOf<TypeDefinition>()

    /** A record type whose fields [fields] declares in order. */
    fun record(
        id: TypeDefinitionId,
        abstract: Boolean = false,
        parameters: List<TypeParameter> = emptyList(),
        parents: List<NamedTypeTemplate> = emptyList(),
        fields: RecordFields.() -> Unit = {},
    ) {
        definitions +=
            TypeDefinition.partial(
                id = id,
                parameters = parameters,
                representation = RepresentationTemplate.createRecord(fields = RecordFields(id).apply(fields).fields, abstract_ = abstract),
                parents = parents,
            )
    }

    /** A collection type of [kind] whose items are [item]. */
    fun sequence(
        id: TypeDefinitionId,
        item: TypeTemplate,
        kind: CollectionKind,
        parameters: List<TypeParameter> = emptyList(),
    ) {
        definitions +=
            TypeDefinition.partial(
                id = id,
                parameters = parameters,
                representation = RepresentationTemplate.createSequence(item = item, kind = kind),
            )
    }
}

@CatalogDsl
class RecordFields internal constructor(
    private val owner: TypeDefinitionId,
) {
    internal val fields = mutableListOf<FieldDeclaration>()

    fun field(
        name: String,
        type: TypeTemplate,
    ) {
        fields += FieldDeclaration.partial(owner = FieldOwner(definition = owner, name = name), type = type)
    }
}
