package com.typewritermc.presentation

import com.typewritermc.types.DataValue
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/** Registers a typed collection projection for generated Realm discovery. */
@Target(AnnotationTarget.FUNCTION)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterCollectionProjection

/** Builds a collection row from one resource type after deployment prototypes are available. */
interface CollectionProjectionProvider {
    val sourcePart: String
    val declarationName: String

    fun specification(context: PresentationBuildContext): CollectionProjectionSpec<*, *>
}

/** The authored mapping from a resource to a collection row. */
class CollectionProjectionSpec<Resource : Any, Row : Any> internal constructor(
    val sourceId: String,
    val resourceDefinitionId: String,
    val resourceType: KClass<Resource>,
    val rowType: KClass<Row>,
    val fields: List<CollectionProjectionFieldSpec>,
)

/** A single serialized row field and the value that supplies it. */
data class CollectionProjectionFieldSpec(
    val target: String,
    val source: CollectionProjectionValueSpec,
)

sealed interface CollectionProjectionValueSpec {
    data object ResourceId : CollectionProjectionValueSpec

    data class Content(
        val field: String,
    ) : CollectionProjectionValueSpec

    data class Literal(
        val value: DataValue,
    ) : CollectionProjectionValueSpec
}

/** Uses prototype serialization metadata for both row and source property paths. */
context(context: PresentationBuildContext)
inline fun <reified Resource : Any, reified Row : Any> collectionProjection(
    sourceId: String,
    resourceDefinitionId: String,
    block: CollectionProjectionBuilder<Resource, Row>.() -> Unit,
): CollectionProjectionSpec<Resource, Row> =
    CollectionProjectionBuilder(Resource::class, Row::class, context)
        .apply(block)
        .build(sourceId, resourceDefinitionId)

class CollectionProjectionBuilder<Resource : Any, Row : Any>
    @PublishedApi
    internal constructor(
        private val resourceType: KClass<Resource>,
        private val rowType: KClass<Row>,
        private val context: PresentationBuildContext,
    ) {
        private val fields = mutableListOf<CollectionProjectionFieldSpec>()

        fun resourceId(target: KProperty1<Row, *>) {
            fields +=
                CollectionProjectionFieldSpec(
                    context.field(rowType, target.name).serializedName,
                    CollectionProjectionValueSpec.ResourceId,
                )
        }

        fun content(
            target: KProperty1<Row, *>,
            source: KProperty1<Resource, *>,
        ) {
            fields +=
                CollectionProjectionFieldSpec(
                    context.field(rowType, target.name).serializedName,
                    CollectionProjectionValueSpec.Content(context.field(resourceType, source.name).serializedName),
                )
        }

        fun literal(
            target: KProperty1<Row, *>,
            value: DataValue,
        ) {
            fields +=
                CollectionProjectionFieldSpec(
                    context.field(rowType, target.name).serializedName,
                    CollectionProjectionValueSpec.Literal(value),
                )
        }

        fun build(
            sourceId: String,
            resourceDefinitionId: String,
        ): CollectionProjectionSpec<Resource, Row> {
            require(sourceId.isNotBlank()) { "Collection source id must not be blank." }
            require(resourceDefinitionId.isNotBlank()) { "Resource definition id must not be blank." }
            require(fields.isNotEmpty()) { "Collection projection must declare at least one row field." }
            require(fields.map(CollectionProjectionFieldSpec::target).distinct().size == fields.size) {
                "Collection projection row fields must be unique."
            }
            return CollectionProjectionSpec(sourceId, resourceDefinitionId, resourceType, rowType, fields.toList())
        }
    }
