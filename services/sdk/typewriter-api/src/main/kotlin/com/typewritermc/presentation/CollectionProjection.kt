package com.typewritermc.presentation

import com.typewritermc.authoring.TypedPath
import com.typewritermc.authoring.ValuePath
import com.typewritermc.expression.ExpressionFactory
import com.typewritermc.types.DataValue
import com.typewritermc.types.Resource
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeTemplate

@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterCollectionProjection

data class CollectionProjectionSpec(
    val sourceId: String,
    val root: TypeTemplate.Named,
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
    root: TypeTemplate.Named,
    rowType: TypeTemplate,
    expressions: ExpressionFactory<Expressions>,
    block: CollectionProjectionBuilder<Resource, Row>.() -> Unit,
): CollectionProjection<Resource, Row, Expressions> =
    CollectionProjection(
        specification = CollectionProjectionBuilder<Resource, Row>(root, rowType).apply(block).build(sourceId),
        expressions = expressions,
    )

class CollectionProjectionBuilder<Resource : com.typewritermc.types.Resource, Row> internal constructor(
    private val root: TypeTemplate.Named,
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
    val named = rowType as? TypeTemplate.Named ?: error("Nested projection targets require a named row type.")
    requireOwner(named.definition)
}

private fun TypedPath<*, *>.requireOwner(expected: TypeDefinitionId) {
    require(owner == expected) { "Collection projection path owner $owner does not match $expected." }
}
