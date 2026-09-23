package com.typewritermc.engine.runtime

import com.typewritermc.elements.Cue
import com.typewritermc.elements.Element
import com.typewritermc.elements.ReferenceAssembler
import com.typewritermc.elements.ReferenceAssemblyResult
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.StoredReference
import com.typewritermc.engine.CompiledEdge
import com.typewritermc.engine.CompiledEdgeOrigin
import com.typewritermc.engine.CompiledPageShard
import com.typewritermc.engine.CompiledResource
import com.typewritermc.engine.CompiledResourceKey
import com.typewritermc.library.Page
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.effectiveRelationField

/** Hydrated resource roles and the compiled links between them. */
class CompiledResourceGraph private constructor(
    val resources: Map<CompiledResourceKey, Any>,
    val edges: List<CompiledEdge>,
    private val ownershipRelations: Set<com.typewritermc.types.RelationId>,
) {
    val elements: Map<CompiledResourceKey, Element> = resources.mapNotNull { (key, value) ->
        (value as? Element)?.let { key to it }
    }.toMap()

    val cues: Map<CompiledResourceKey, Cue> = resources.mapNotNull { (key, value) ->
        (value as? Cue)?.let { key to it }
    }.toMap()

    fun immediateOwner(key: CompiledResourceKey): CompiledResourceKey? =
        edges.singleOrNull { edge ->
            edge.target == key &&
                (edge.origin as? CompiledEdgeOrigin.Declared)?.relation in ownershipRelations
        }?.source

    fun pageOf(key: CompiledResourceKey): CompiledResourceKey? {
        val visited = hashSetOf<CompiledResourceKey>()
        var current: CompiledResourceKey? = key
        while (current != null && visited.add(current)) {
            if (resources[current] is Page) return current
            current = immediateOwner(current)
        }
        return null
    }

    companion object {
        fun assemble(
            shards: List<CompiledPageShard>,
            relations: Collection<RelationDefinition>,
            prototypes: TypePrototypeRegistry,
        ): CompiledResourceGraph {
            val records = linkedMapOf<CompiledResourceKey, CompiledResource>()
            val edges = linkedSetOf<CompiledEdge>()
            shards.forEach { shard ->
                require(shard.resources.any { it.key == shard.root }) {
                    "Compiled Page root is absent from its shard."
                }
                shard.resources.forEach { record ->
                    require(records.putIfAbsent(record.key, record) == null) {
                        "Compiled resource ${record.key} appears in more than one shard."
                    }
                }
                edges.addAll(shard.edges)
            }
            val definitions = relations.associateBy(RelationDefinition::id)
            val assembler = ReferenceAssembler()
            val decoded = records.mapValues { (key, record) ->
                val catalog = TypeCatalog(prototypes.graph(TypeExpression.Named(record.rootType)).definitions)
                val overrides = buildMap {
                    relations.forEach { relation ->
                        listOfNotNull(relation.sourceEndpoint, relation.targetEndpoint).forEach { endpoint ->
                            if (catalog.effectiveRelationField(record.rootType, relation, endpoint.side) != null) {
                                put(endpoint.path, hydratedEndpoint(key, relation, endpoint, edges))
                            }
                        }
                    }
                }
                val ordinary = edges.mapNotNull { edge ->
                    val origin = edge.origin as? CompiledEdgeOrigin.Reference ?: return@mapNotNull null
                    if (edge.source != key) return@mapNotNull null
                    StoredReference(origin.slot, edge.target.source, origin.expectedType, origin.path)
                }
                val assembled = assembler.assemble(
                    prototypes.graph(TypeExpression.Named(record.rootType)),
                    StoredElementValue(record.valueWithSlots, ordinary),
                    overrides,
                )
                require(assembled is ReferenceAssemblyResult.Success) {
                    "Compiled resource $key has inconsistent reference edges."
                }
                prototypes.decode(TypedValueEnvelope(TypeExpression.Named(record.rootType), assembled.value))
            }
            val ownership = definitions.values.filter {
                RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in it.families
            }.mapTo(linkedSetOf(), RelationDefinition::id)
            return CompiledResourceGraph(decoded, edges.toList(), ownership)
        }
    }
}

private fun hydratedEndpoint(
    owner: CompiledResourceKey,
    relation: RelationDefinition,
    endpoint: RelationEndpointDefinition,
    edges: Collection<CompiledEdge>,
): DataValue {
    val targets = edges.mapNotNull { edge ->
        val origin = edge.origin as? CompiledEdgeOrigin.Declared ?: return@mapNotNull null
        if (origin.relation != relation.id) return@mapNotNull null
        val target = when (endpoint.side) {
            RelationEndpointSide.SOURCE -> edge.target.takeIf { edge.source == owner }
            RelationEndpointSide.TARGET -> edge.source.takeIf { edge.target == owner }
        } ?: return@mapNotNull null
        val index = when (endpoint.side) {
            RelationEndpointSide.SOURCE -> origin.sourceIndex
            RelationEndpointSide.TARGET -> origin.targetIndex
        }
        target to index
    }.distinctBy { it.first }
        .sortedWith(compareBy({ it.second ?: Int.MAX_VALUE }, { it.first.source.value }))
        .map { it.first.source }
    return when (endpoint.cardinality) {
        RelationCardinality.ONE -> {
            require(targets.size == 1) { "Relation ${relation.id.value} requires one endpoint for $owner." }
            DataValue.Reference(targets.single())
        }
        RelationCardinality.MANY -> DataValue.ListValue(targets.map(DataValue::Reference))
    }
}
