package com.typewritermc.testkit

import com.typewritermc.types.template
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate

/**
 * A single record type [id] with the [fields] given, in place of a [CatalogDefinitions] block when a test needs one
 * definition. It is abstract when [abstract] and inherits the [parents].
 */
fun recordType(
    id: TypeDefinitionId,
    vararg fields: FieldDeclaration,
    abstract: Boolean = false,
    parents: List<NamedTypeTemplate> = emptyList(),
): TypeDefinition =
    TypeDefinition.partial(
        id = id,
        representation = RepresentationTemplate.createRecord(fields = fields.toList(), abstract_ = abstract),
        parents = parents,
    )

/** The field [name] of the record type [owner], declared with [type]. */
fun fieldDeclaration(
    owner: TypeDefinitionId,
    name: String,
    type: TypeTemplate,
): FieldDeclaration = FieldDeclaration.partial(owner = FieldOwner(definition = owner, name = name), type = type)

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

    /** A link type through [endpoint] whose target resource is [target]. */
    fun link(
        id: TypeDefinitionId,
        endpoint: EndpointId,
        target: TypeTemplate,
        parameters: List<TypeParameter> = emptyList(),
    ) {
        definitions +=
            TypeDefinition.partial(
                id = id,
                parameters = parameters,
                representation = RepresentationTemplate.createLink(endpoint = endpoint, target = target),
            )
    }

    /** A generic link [id] through [endpoint] whose target is its one type parameter `T`. */
    fun genericLink(
        id: TypeDefinitionId,
        endpoint: EndpointId,
    ) {
        val parameter = ParameterKey(owner = id, index = 0)
        link(id, endpoint, parameter.template, parameters = listOf(TypeParameter.partial(key = parameter, name = "T")))
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
