package com.typewritermc.realm.search

import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.authoring.AuthoringSearchFacet
import com.typewritermc.authoring.AuthoringSearchSelector
import com.typewritermc.authoring.SearchSelectorId
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.realm.compiler.GraphReadRequirement
import com.typewritermc.realm.repository.AuthoringGraphResource
import com.typewritermc.realm.repository.AuthoringMutationPlan
import com.typewritermc.realm.repository.AuthoringWorkingGraph
import com.typewritermc.realm.repository.PolicyGraphSliceResult
import com.typewritermc.realm.repository.StoredResourceRelation
import com.typewritermc.realm.repository.StoredTypedResource
import com.typewritermc.realm.repository.sliceForPolicy
import com.typewritermc.realm.repository.utils.StructuredDatabaseCodec
import com.typewritermc.realm.repository.utils.unifiedSurrealId
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import java.security.MessageDigest

/** One Realm supplied searchable projection for one open resource definition. */
internal interface AuthoringSearchProjection {
    val definition: ResourceDefinitionId
    val graphRequirement: GraphReadRequirement
        get() = GraphReadRequirement()

    /** Projects the resource and the bounded graph needed by this policy into indexed scalar values. */
    fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringSearchGraph,
    ): AuthoringSearchDocument

    /** Returns resources whose document can change when this mutation is applied. */
    fun affectedResources(plan: AuthoringMutationPlan): Set<ResourceId> =
        buildSet {
            addAll(plan.changedResources)
            addAll(
                plan.changedEdges.flatMap { edgeId ->
                    listOfNotNull(plan.before.relations[edgeId], plan.proposed.relations[edgeId]).flatMap { relation ->
                        listOf(relation.source, relation.target)
                    }
                },
            )
        }
}

/** The bounded graph view supplied to a search projection. */
internal data class AuthoringSearchGraph(
    val resources: Map<ResourceId, AuthoringGraphResource>,
    val relations: List<StoredResourceRelation>,
)

/** Canonical values stored in the Realm search index. */
internal data class AuthoringSearchDocument(
    val resource: ResourceId,
    val definition: ResourceDefinitionId,
    val text: List<String>,
    val selectors: Map<String, Set<String>>,
    val ownerPath: List<ResourceId> = emptyList(),
)

/** Owns selector identity, facet mapping, and the normalization promised by catalog metadata. */
internal class AuthoringSearchMetadata(
    selectors: Collection<AuthoringSearchSelector>,
    facets: Collection<AuthoringSearchFacet>,
) {
    private val selectors = selectors.associateBy(AuthoringSearchSelector::id)
    private val facets = facets.associateBy(AuthoringSearchFacet::id)

    fun normalize(
        selector: String,
        value: String,
    ): String {
        val definition = requireNotNull(selectors[SearchSelectorId(selector)]) { "Search selector $selector is not registered." }
        return value.trim().let { if (definition.caseSensitive) it else it.lowercase() }
    }

    fun selectorForFacet(facet: String): String =
        requireNotNull(facets[facet]) { "Search facet $facet is not registered." }.selectorId.value
}

/** Validates the open projection set and resolves a projection without a definition switch. */
internal class AuthoringSearchProjectionRegistry(
    projections: Collection<AuthoringSearchProjection>,
) {
    private val byDefinition = projections.associateBy(AuthoringSearchProjection::definition)

    init {
        require(byDefinition.size == projections.size) {
            "Search projections must have unique resource definitions."
        }
    }

    fun forDefinition(definition: ResourceDefinitionId): AuthoringSearchProjection? = byDefinition[definition]

    fun all(): Collection<AuthoringSearchProjection> = byDefinition.values

    fun affectedResources(plan: AuthoringMutationPlan): Set<ResourceId> =
        byDefinition.values.flatMapTo(linkedSetOf()) { it.affectedResources(plan) }
}

/** Updates indexed search documents in the same transaction as the graph delta. */
internal class AuthoringSearchIndexer(
    private val projections: AuthoringSearchProjectionRegistry,
    private val metadata: AuthoringSearchMetadata,
) {
    fun apply(
        transaction: Transaction,
        plan: AuthoringMutationPlan,
    ) {
        val affected = projections.affectedResources(plan)
        if (affected.isEmpty()) return
        update(transaction, plan.proposed, affected)
    }

    fun rebuild(
        transaction: Transaction,
        graph: AuthoringWorkingGraph,
    ) {
        transaction.query("DELETE authoring_search;").take(0)
        transaction.query("DELETE authoring_search_selector;").take(0)
        update(transaction, graph, graph.resources.keys)
    }

    private fun update(
        transaction: Transaction,
        workingGraph: AuthoringWorkingGraph,
        affected: Set<ResourceId>,
    ) {
        val graph = workingGraph.toSearchGraph()
        affected.sortedBy(ResourceId::value).forEach { id ->
            val resource = graph.resources[id]
            val projection = resource?.let { projections.forDefinition(it.definition) }
            val projectionGraph =
                projection?.let {
                    when (val result = workingGraph.sliceForPolicy(setOf(id), it.graphRequirement)) {
                        is PolicyGraphSliceResult.Success -> {
                            result.graph.toSearchGraph()
                        }

                        is PolicyGraphSliceResult.LimitExceeded -> {
                            error(
                                "Search projection ${it.definition.value} exceeded its ${result.dimension} " +
                                    "limit ${result.limit}.",
                            )
                        }
                    }
                }
            val document = resource?.let { projection?.project(it, requireNotNull(projectionGraph)) }
            if (document == null) {
                delete(transaction, id)
            } else {
                replace(
                    transaction,
                    document,
                    (resource.content.rootType as? TypeExpression.Named)?.reference
                        ?: error("Searchable resources require a nominal root."),
                )
            }
        }
    }

    private fun replace(
        transaction: Transaction,
        document: AuthoringSearchDocument,
        root: ResolvedTypeRef,
    ) {
        delete(transaction, document.resource)
        transaction
            .query(
                "UPSERT ONLY \$search CONTENT { resource: \$resource, definition: \$definition, " +
                    "root: \$root, text: \$text, owner_path: \$owner_path };",
                mapOf(
                    "search" to searchId(document.resource),
                    "resource" to document.resource.unifiedSurrealId(),
                    "definition" to document.definition.value,
                    "root" to StructuredDatabaseCodec.encode(ResolvedTypeRef.serializer(), root),
                    "text" to document.text.joinToString(" "),
                    "owner_path" to document.ownerPath.map(ResourceId::value),
                ),
            ).take(0)
        document.selectors.forEach { (facet, values) ->
            values
                .groupBy { metadata.normalize(facet, it) }
                .toSortedMap()
                .forEach { (normalized, displays) ->
                    transaction
                        .query(
                            "UPSERT ONLY \$selector CONTENT { resource: \$resource, facet: \$facet, " +
                                "normalized: \$normalized, display: \$display };",
                            mapOf(
                                "selector" to selectorId(document.resource, facet, normalized),
                                "resource" to document.resource.unifiedSurrealId(),
                                "facet" to facet,
                                "normalized" to normalized,
                                "display" to displays.sorted().first(),
                            ),
                        ).take(0)
                }
        }
    }

    private fun delete(
        transaction: Transaction,
        resource: ResourceId,
    ) {
        transaction
            .query(
                "DELETE ONLY \$search;",
                mapOf("search" to searchId(resource)),
            ).take(0)
        transaction
            .query(
                "DELETE authoring_search_selector WHERE resource = \$resource;",
                mapOf("resource" to resource.unifiedSurrealId()),
            ).take(0)
    }
}

/** Generic projection that indexes the identity and every textual value without knowing the resource family. */
internal class TextualAuthoringSearchProjection(
    override val definition: ResourceDefinitionId,
    override val graphRequirement: GraphReadRequirement = GraphReadRequirement(),
    private val selectors: (AuthoringGraphResource, AuthoringSearchGraph) -> Map<String, Set<String>> = { _, _ -> emptyMap() },
    private val ownerPath: (AuthoringGraphResource, AuthoringSearchGraph) -> List<ResourceId> = { _, _ -> emptyList() },
    private val impact: ((AuthoringMutationPlan) -> Set<ResourceId>)? = null,
) : AuthoringSearchProjection {
    override fun affectedResources(plan: AuthoringMutationPlan): Set<ResourceId> = impact?.invoke(plan) ?: super.affectedResources(plan)

    override fun project(
        resource: AuthoringGraphResource,
        graph: AuthoringSearchGraph,
    ): AuthoringSearchDocument =
        AuthoringSearchDocument(
            resource = resource.id,
            definition = resource.definition,
            text =
                buildList {
                    add(resource.id.value)
                    add(resource.definition.value)
                    resource.content.rootValue.collectText(this)
                }.distinct(),
            selectors = selectors(resource, graph),
            ownerPath = ownerPath(resource, graph),
        )
}

private fun DataValue.collectText(target: MutableList<String>) {
    when (this) {
        is DataValue.StringValue -> target += value
        is DataValue.Record -> fields.values.forEach { it.collectText(target) }
        is DataValue.ListValue -> values.forEach { it.collectText(target) }
        is DataValue.MapValue -> entries.forEach { it.value.collectText(target) }
        is DataValue.Polymorphic -> value.collectText(target)
        else -> Unit
    }
}

private fun AuthoringWorkingGraph.toSearchGraph(): AuthoringSearchGraph =
    AuthoringSearchGraph(
        resources =
            resources.mapValues { (id, resource) ->
                AuthoringGraphResource(
                    id = id,
                    definition = resource.definition,
                    content = resource.toEnvelope(),
                )
            },
        relations = relations.values.toList(),
    )

private fun StoredTypedResource.toEnvelope(): com.typewritermc.types.TypedValueEnvelope =
    com.typewritermc.types.TypedValueEnvelope(root.asExpression(), valueWithSlots)

private fun com.typewritermc.types.ResolvedTypeRef.asExpression(): com.typewritermc.types.TypeExpression =
    com.typewritermc.types.TypeExpression
        .Named(this)

private fun searchId(resource: ResourceId): RecordId = RecordId("authoring_search", resource.value)

internal fun selectorId(
    resource: ResourceId,
    facet: String,
    normalized: String,
): RecordId {
    val digest =
        MessageDigest
            .getInstance("SHA-256")
            .digest(normalized.toByteArray())
            .joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
    return RecordId("authoring_search_selector", "${resource.value}_${facet}_$digest")
}
