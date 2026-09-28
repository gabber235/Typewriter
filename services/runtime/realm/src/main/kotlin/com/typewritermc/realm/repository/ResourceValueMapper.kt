package com.typewritermc.realm.repository

import com.typewritermc.elements.ReferenceAssembler
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.StoredReference
import com.typewritermc.realm.ResourceDefinitionId
import com.typewritermc.types.DataPath
import com.typewritermc.types.DataPathSegment
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationCardinality
import com.typewritermc.types.RelationDefinition
import com.typewritermc.types.RelationEndpointDefinition
import com.typewritermc.types.RelationEndpointSide
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypePrototypeRegistry
import com.typewritermc.types.TypedValueEnvelope
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.effectiveRelationField
import java.security.MessageDigest

/** Canonical scalar state stored on one resource row. */
@kotlinx.serialization.Serializable
data class StoredTypedResource(
    val id: ResourceId,
    val definition: ResourceDefinitionId,
    val root: ResolvedTypeRef,
    val valueWithSlots: DataValue,
)

/** One normalized edge stored independently from resource scalar state. */
@kotlinx.serialization.Serializable
data class StoredResourceRelation(
    val id: String,
    val source: ResourceId,
    val target: ResourceId,
    val origin: ResourceRelationOrigin,
)

@kotlinx.serialization.Serializable
sealed interface ResourceRelationOrigin {
    @kotlinx.serialization.Serializable
    data class Reference(
        val slot: ReferenceSlotId,
        val sourcePath: DataPath,
        val expectedTarget: TypeExpression,
    ) : ResourceRelationOrigin

    @kotlinx.serialization.Serializable
    data class Declared(
        val relationId: RelationId,
        val sourceIndex: Int? = null,
        val targetIndex: Int? = null,
    ) : ResourceRelationOrigin
}

internal data class DecomposedResourceValue(
    val resource: StoredTypedResource,
    val relations: List<StoredResourceRelation>,
)

/**
 * Converts hydrated typed values to canonical resource rows plus normalized edges and back.
 *
 * Declared relation endpoints are removed as complete fields before ordinary reference projection. They therefore
 * need no occurrence slots. Ordinary nested references retain slots and structured source paths.
 */
internal class ResourceValueMapper(
    private val prototypes: TypePrototypeRegistry,
    relationDefinitions: Collection<RelationDefinition>,
    private val decomposer: ReferenceDecomposer = ReferenceDecomposer(),
    private val assembler: ReferenceAssembler = ReferenceAssembler(),
) {
    fun declaredRelation(
        relation: RelationId,
        source: ResourceId,
        target: ResourceId,
    ): StoredResourceRelation =
        StoredResourceRelation(
            id = edgeId(source, target, "declared:${relation.value}"),
            source = source,
            target = target,
            origin = ResourceRelationOrigin.Declared(relation),
        )

    private val relations = relationDefinitions.associateBy(RelationDefinition::id)

    fun graph(root: TypeExpression): com.typewritermc.types.TypeGraph = prototypes.graph(root)

    fun validate(value: TypedValueEnvelope) {
        prototypes.decode(value)
    }

    fun ownedRelationEndpoints(root: ResolvedTypeRef): List<Pair<RelationId, RelationEndpointSide>> =
        endpoints(root).map { (definition, endpoint) -> definition.id to endpoint.side }

    fun decompose(
        id: ResourceId,
        definition: ResourceDefinitionId,
        value: TypedValueEnvelope,
    ): DecomposedResourceValue {
        val root = value.requireNamedRoot()
        val graph = prototypes.graph(root)
        val endpoints = endpoints(root)
        val declared = endpoints.flatMap { (definition, endpoint) -> declaredEdges(id, value.rootValue, definition, endpoint) }
        val overrides = endpoints.associate { (_, endpoint) -> endpoint.path to endpoint.placeholder() }
        val stored = decomposer.decompose(graph, value.rootValue, overrides)
        val ordinary =
            stored.references.map { reference ->
                StoredResourceRelation(
                    id = edgeId(id, reference.target, "reference:${reference.slot.value}"),
                    source = id,
                    target = reference.target,
                    origin =
                        ResourceRelationOrigin.Reference(
                            reference.slot,
                            reference.sourcePath,
                            reference.expectedType,
                        ),
                )
            }
        return DecomposedResourceValue(
            StoredTypedResource(id, definition, root, stored.valueWithSlots),
            (declared + ordinary).sortedBy(StoredResourceRelation::id),
        )
    }

    fun hydrate(
        resource: StoredTypedResource,
        allRelations: Collection<StoredResourceRelation>,
    ): TypedValueEnvelope {
        val endpoints = endpoints(resource.root)
        val overrides =
            endpoints.associate { (definition, endpoint) ->
                endpoint.path to hydratedEndpoint(resource.id, definition, endpoint, allRelations)
            }
        val ordinary =
            allRelations.mapNotNull { relation ->
                val origin = relation.origin as? ResourceRelationOrigin.Reference ?: return@mapNotNull null
                if (relation.source != resource.id) return@mapNotNull null
                StoredReference(origin.slot, relation.target, origin.expectedTarget, origin.sourcePath)
            }
        val assembled =
            assembler.assemble(
                prototypes.graph(resource.root),
                StoredElementValue(resource.valueWithSlots, ordinary),
                overrides,
            )
        require(assembled is com.typewritermc.elements.ReferenceAssemblyResult.Success) {
            "Resource ${resource.id} contains inconsistent normalized reference state."
        }
        return TypedValueEnvelope(TypeExpression.Named(resource.root), assembled.value)
    }

    private fun endpoints(root: ResolvedTypeRef): List<Pair<RelationDefinition, RelationEndpointDefinition>> {
        val catalog = TypeCatalog(prototypes.graph(TypeExpression.Named(root)).definitions)
        return relations.values
            .flatMap { definition ->
                listOfNotNull(
                    definition.sourceEndpoint?.takeIf {
                        catalog.effectiveRelationField(root, definition, RelationEndpointSide.SOURCE) != null
                    }?.let { definition to it },
                    definition.targetEndpoint?.takeIf {
                        catalog.effectiveRelationField(root, definition, RelationEndpointSide.TARGET) != null
                    }?.let { definition to it },
                )
            }.sortedBy { (_, endpoint) -> endpoint.path.toString() }
    }

    private fun declaredEdges(
        owner: ResourceId,
        value: DataValue,
        definition: RelationDefinition,
        endpoint: RelationEndpointDefinition,
    ): List<StoredResourceRelation> {
        val references = value.at(endpoint.path).references(endpoint.cardinality)
        return references.mapIndexed { index, target ->
            val sourceId = if (endpoint.side == RelationEndpointSide.SOURCE) owner else target
            val targetId = if (endpoint.side == RelationEndpointSide.SOURCE) target else owner
            StoredResourceRelation(
                id = edgeId(sourceId, targetId, "declared:${definition.id.value}"),
                source = sourceId,
                target = targetId,
                origin =
                    ResourceRelationOrigin.Declared(
                        definition.id,
                        sourceIndex = index.takeIf { endpoint.side == RelationEndpointSide.SOURCE && endpoint.cardinality == RelationCardinality.MANY },
                        targetIndex = index.takeIf { endpoint.side == RelationEndpointSide.TARGET && endpoint.cardinality == RelationCardinality.MANY },
                    ),
            )
        }
    }

    private fun hydratedEndpoint(
        owner: ResourceId,
        definition: RelationDefinition,
        endpoint: RelationEndpointDefinition,
        allRelations: Collection<StoredResourceRelation>,
    ): DataValue {
        val targets =
            allRelations
                .asSequence()
                .filter { (it.origin as? ResourceRelationOrigin.Declared)?.relationId == definition.id }
                .mapNotNull { relation ->
                    val target =
                        when (endpoint.side) {
                            RelationEndpointSide.SOURCE -> relation.target.takeIf { relation.source == owner }
                            RelationEndpointSide.TARGET -> relation.source.takeIf { relation.target == owner }
                        } ?: return@mapNotNull null
                    val origin = relation.origin as ResourceRelationOrigin.Declared
                    val index = when (endpoint.side) {
                        RelationEndpointSide.SOURCE -> origin.sourceIndex
                        RelationEndpointSide.TARGET -> origin.targetIndex
                    }
                    target to index
                }.distinctBy { it.first }
                .sortedWith(compareBy<Pair<ResourceId, Int?>>({ it.second ?: Int.MAX_VALUE }, { it.first.value }))
                .map { it.first }
                .toList()
        return when (endpoint.cardinality) {
            RelationCardinality.ONE -> {
                require(targets.size == 1) { "Relation ${definition.id.value} requires exactly one endpoint for $owner." }
                DataValue.Reference(targets.single())
            }

            RelationCardinality.MANY -> {
                DataValue.ListValue(targets.map(DataValue::Reference))
            }
        }
    }
}

private fun TypedValueEnvelope.requireNamedRoot(): ResolvedTypeRef =
    (rootType as? TypeExpression.Named)?.reference
        ?: error("Stored authored resources require named root types.")

private fun RelationEndpointDefinition.placeholder(): DataValue =
    when (cardinality) {
        RelationCardinality.ONE -> DataValue.Unit
        RelationCardinality.MANY -> DataValue.ListValue(emptyList())
    }

private fun DataValue.references(cardinality: RelationCardinality): List<ResourceId> =
    when (cardinality) {
        RelationCardinality.ONE -> listOf((this as DataValue.Reference).id)
        RelationCardinality.MANY -> {
            val ids = (this as DataValue.ListValue).values.map { (it as DataValue.Reference).id }
            require(ids.distinct().size == ids.size) { "A ToMany field cannot repeat a target resource." }
            ids
        }
    }

private fun DataValue.at(path: DataPath): DataValue =
    path.segments.fold(this) { value, segment ->
        when (segment) {
            is DataPathSegment.Field -> {
                (value as DataValue.Record).fields.getValue(segment.name)
            }

            is DataPathSegment.Index -> {
                (value as DataValue.ListValue).values[segment.index]
            }

            is DataPathSegment.MapKey -> {
                (value as DataValue.MapValue).entries.single { it.key == segment.key }.value
            }
        }
    }

private fun edgeId(
    source: ResourceId,
    target: ResourceId,
    origin: String,
): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest("${source.value}\u0000${target.value}\u0000$origin".toByteArray())
        .joinToString("") { byte -> "%02x".format(byte) }
