package com.typewritermc.presentation

import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.types.Resource
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate

/**
 * Declares a portable row view over authored resources using source paths and literal field values.
 * Resource identity stays with the collection row rather than being copied into its content. The builder checks
 * path ownership; catalog assembly checks source and target schemas before publishing collection dependencies.
 */
data class CollectionProjectionSpec(
    val sourceId: String,
    val root: NamedTypeTemplate,
    val rowType: TypeTemplate,
    val fields: List<CollectionProjectionFieldSpec>,
) {
    init {
        require(sourceId.isNotBlank()) { "Collection source id must not be blank." }
        require(fields.isNotEmpty()) { "Collection projection must declare at least one row field." }
        require(fields.map(CollectionProjectionFieldSpec::target).distinct().size == fields.size) {
            "Collection projection row fields must be unique."
        }
    }
}

data class CollectionProjectionFieldSpec(
    val target: ValuePath,
    val source: CollectionProjectionValueSpec,
)

sealed interface CollectionProjectionValueSpec {
    data class Content(
        val path: ValuePath,
    ) : CollectionProjectionValueSpec

    data class Literal(
        val value: DataValue,
    ) : CollectionProjectionValueSpec
}

data class CollectionProjection<Resource : com.typewritermc.types.Resource, Row, Expressions : Any>(
    val specification: CollectionProjectionSpec,
    val expressions: ExpressionFactory<Expressions>,
)

fun <Resource : com.typewritermc.types.Resource, Row, Expressions : Any> collectionProjection(
    sourceId: String,
    root: NamedTypeTemplate,
    rowType: TypeTemplate,
    expressions: ExpressionFactory<Expressions>,
    block: CollectionProjectionBuilder<Resource, Row>.() -> Unit,
): CollectionProjection<Resource, Row, Expressions> =
    CollectionProjection(
        specification = CollectionProjectionBuilder<Resource, Row>(root, rowType).apply(block).build(sourceId),
        expressions = expressions,
    )

class CollectionProjectionBuilder<Resource : com.typewritermc.types.Resource, Row> internal constructor(
    private val root: NamedTypeTemplate,
    private val rowType: TypeTemplate,
) {
    private val fields = mutableListOf<CollectionProjectionFieldSpec>()

    fun content(
        target: TypedPath<Row, *>,
        source: TypedPath<Resource, *>,
    ) {
        target.requireRowOwner(rowType)
        source.requireOwner(root.definition)
        fields += CollectionProjectionFieldSpec(target.path, CollectionProjectionValueSpec.Content(source.path))
    }

    fun content(source: TypedPath<Resource, *>) {
        source.requireOwner(root.definition)
        fields += CollectionProjectionFieldSpec(ValuePath(), CollectionProjectionValueSpec.Content(source.path))
    }

    fun literal(
        target: TypedPath<Row, *>,
        value: DataValue,
    ) {
        target.requireRowOwner(rowType)
        fields += CollectionProjectionFieldSpec(target.path, CollectionProjectionValueSpec.Literal(value))
    }

    fun literal(value: DataValue) {
        fields += CollectionProjectionFieldSpec(ValuePath(), CollectionProjectionValueSpec.Literal(value))
    }

    fun build(sourceId: String): CollectionProjectionSpec = CollectionProjectionSpec(sourceId, root, rowType, fields.toList())
}

private fun TypedPath<*, *>.requireRowOwner(rowType: TypeTemplate) {
    val named = rowType as? TypeTemplate.NamedWrapper ?: error("Nested projection targets require a named row type.")
    requireOwner(named.value.definition)
}

private fun TypedPath<*, *>.requireOwner(expected: TypeDefinitionId) {
    require(owner == expected) { "Collection projection path owner $owner does not match $expected." }
}
