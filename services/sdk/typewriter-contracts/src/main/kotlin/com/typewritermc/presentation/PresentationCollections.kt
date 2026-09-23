package com.typewritermc.presentation

import com.typewritermc.types.Color
import kotlin.reflect.KClass
import kotlin.reflect.KProperty1

/** Typed schema for one Realm supplied collection used by authored presentations. */
class PresentationCollection<Row : Any>
    @PublishedApi
    internal constructor(
        val sourceId: String,
        internal val rowType: KClass<Row>,
        internal val key: KProperty1<Row, *>,
        internal val selectability: KProperty1<Row, Boolean>,
        internal val relations: List<PresentationCollectionRelation<Row>>,
    ) {
        init {
            require(sourceId.isNotBlank()) { "Collection source ids must not be blank." }
            require(relations.map(PresentationCollectionRelation<Row>::id).distinct().size == relations.size) {
                "Collection relation ids must be unique."
            }
        }
    }

/** Typed relation whose targets are read from each collection row. */
class PresentationCollectionRelation<Row : Any> internal constructor(
    val id: String,
    internal val targets: KProperty1<Row, *>,
) {
    init {
        require(id.isNotBlank()) { "Collection relation ids must not be blank." }
    }
}

/** Declares a typed collection relation without fixing its concrete collection identity. */
fun <Row : Any> collectionRelation(
    id: String,
    targets: KProperty1<Row, *>,
): PresentationCollectionRelation<Row> = PresentationCollectionRelation(id, targets)

/** Declares the authoritative row schema and binding expressions for a Realm supplied collection. */
inline fun <reified Row : Any> presentationCollection(
    sourceId: String,
    key: KProperty1<Row, *>,
    selectability: KProperty1<Row, Boolean>,
    vararg relations: PresentationCollectionRelation<Row>,
): PresentationCollection<Row> = PresentationCollection(sourceId, Row::class, key, selectability, relations.toList())

/** Renders one collection key with a typed row label and color. */
fun <T : Any, Row : Any> PresentationBuilder<T>.collectionLookup(
    collection: PresentationCollection<Row>,
    key: PresentationValue<*>,
    label: KProperty1<Row, String>,
    color: KProperty1<Row, Color>,
    missingLabel: String,
) {
    require(missingLabel.isNotBlank()) { "Missing collection labels must not be blank." }
    append(AuthoredCollectionNode.Lookup(collection, key, label, color, missingLabel))
}

/** Renders the effective graph reached from [roots] through [relation]. */
fun <T : Any, Row : Any> PresentationBuilder<T>.collectionGraph(
    collection: PresentationCollection<Row>,
    roots: PresentationValue<*>,
    relation: PresentationCollectionRelation<Row>,
    label: KProperty1<Row, String>,
    color: KProperty1<Row, Color>,
    maximumDepth: Int? = null,
) {
    require(relation in collection.relations) { "Collection graph relations must belong to the declared collection." }
    require(maximumDepth == null || maximumDepth > 0) { "Collection graph maximum depth must be positive." }
    append(AuthoredCollectionNode.Graph(collection, roots, relation, label, color, maximumDepth))
}

/** Applies a typed background color while preserving inherited foreground contrast in the renderer. */
fun <T : Any> PresentationBuilder<T>.surface(
    backgroundColor: PresentationExpression<Color>,
    block: PresentationBuilder<T>.() -> Unit,
) {
    append(
        AuthoredCollectionNode.Surface(
            backgroundColor,
            PresentationBuilder(target, context, inputs).apply(block).column(),
        ),
    )
}

internal sealed interface AuthoredCollectionNode : AuthoredPresentationNode {
    data class Lookup<Row : Any>(
        val collection: PresentationCollection<Row>,
        val key: PresentationValue<*>,
        val label: KProperty1<Row, String>,
        val color: KProperty1<Row, Color>,
        val missingLabel: String,
    ) : AuthoredCollectionNode

    data class Graph<Row : Any>(
        val collection: PresentationCollection<Row>,
        val roots: PresentationValue<*>,
        val relation: PresentationCollectionRelation<Row>,
        val label: KProperty1<Row, String>,
        val color: KProperty1<Row, Color>,
        val maximumDepth: Int?,
    ) : AuthoredCollectionNode

    data class Surface(
        val backgroundColor: PresentationExpression<Color>,
        val child: AuthoredPresentationNode,
    ) : AuthoredCollectionNode
}
