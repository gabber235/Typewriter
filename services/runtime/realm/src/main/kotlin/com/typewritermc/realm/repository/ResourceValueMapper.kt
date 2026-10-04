package com.typewritermc.realm.repository

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import java.util.concurrent.ConcurrentHashMap

internal data class StoredDeclaredEdge(
    val physicalId: String,
    val relation: RelationId,
    val source: ResourceId,
    val target: ResourceId,
    val sourceLocation: ValuePath?,
    val targetLocation: ValuePath?,
)

internal data class ProjectionResult(
    val projections: List<LinkProjection>,
    val problems: List<ValueProblem>,
)

internal data class DeclaredLinkEvidence(
    val values: List<ValueLocation>,
    val memberships: List<ValueLocation>,
    val forms: List<ValueLocation>,
)

internal class LinkSchemaCapabilities(
    private val catalog: CheckedCatalog,
) {
    private val cache = ConcurrentHashMap<Pair<TypeUse, com.typewritermc.types.EndpointId>, Boolean>()

    fun contains(
        use: TypeUse,
        endpoint: com.typewritermc.types.EndpointId,
    ): Boolean = cache.computeIfAbsent(use to endpoint) { contains(it.first, it.second, emptySet(), 0) }

    private fun contains(
        use: TypeUse,
        endpoint: com.typewritermc.types.EndpointId,
        visited: Set<TypeUse>,
        depth: Int,
    ): Boolean {
        if (depth >= MAX_SCHEMA_CAPABILITY_DEPTH) return true
        val nonNull = if (use is TypeUse.Nullable) use.value else use
        if (nonNull in visited) return false
        val resolved = catalog.resolve(nonNull) as? Resolution.Ready ?: return true
        val nextVisited = visited + nonNull
        return when (val representation = resolved.value.schema.representation) {
            is com.typewritermc.types.catalog.ResolvedRepresentation.Link -> {
                representation.endpoint == endpoint
            }

            is com.typewritermc.types.catalog.ResolvedRepresentation.Record -> {
                representation.abstract ||
                    representation.fields.any { contains(it.type, endpoint, nextVisited, depth + 1) }
            }

            is com.typewritermc.types.catalog.ResolvedRepresentation.Sequence -> {
                contains(representation.item, endpoint, nextVisited, depth + 1)
            }

            is com.typewritermc.types.catalog.ResolvedRepresentation.Mapping -> {
                contains(representation.key, endpoint, nextVisited, depth + 1) ||
                    contains(representation.value, endpoint, nextVisited, depth + 1)
            }

            else -> {
                false
            }
        }
    }
}

internal sealed interface CounterpartBinding {
    data class Scalar(
        val location: ValueLocation,
    ) : CounterpartBinding

    data class Collection(
        val location: ValueLocation,
    ) : CounterpartBinding

    data object ExplicitChoice : CounterpartBinding

    data object Missing : CounterpartBinding
}

/** Derives exact authored occurrences and rebuildable declared graph projections. */
internal object ResourceValueMapper {
    fun discover(resources: Map<ResourceId, AuthoringRecord>): List<LinkOccurrence> =
        buildList {
            resources.forEach { (resource, record) ->
                record.fields.forEach { (name, value) ->
                    collect(resource, value, ValueLocation(resource, ValuePath(listOf(PathSegment.Field(name)))), this)
                }
            }
        }

    fun project(
        occurrences: Collection<LinkOccurrence>,
        resources: Map<ResourceId, AuthoringRecord>,
        contracts: List<RelationContract>,
        catalog: CheckedCatalog? = null,
    ): ProjectionResult {
        val problems = mutableListOf<ValueProblem>()
        val byEndpoint =
            contracts
                .flatMap { contract ->
                    listOf(contract.first.id to (contract to contract.first.slot), contract.second.id to (contract to contract.second.slot))
                }.groupBy({ it.first }, { it.second })
        val byLocation = occurrences.associateBy { it.id.location }
        val projected = linkedSetOf<LinkProjection>()

        occurrences.sortedBy { occurrenceKey(it) }.forEach { occurrence ->
            val candidates = byEndpoint[occurrence.id.endpoint].orEmpty()
            if (candidates.size != 1) {
                problems += ValueProblem(occurrence.id.location, if (candidates.isEmpty()) "unknown_endpoint" else "ambiguous_endpoint")
                return@forEach
            }
            if (occurrence.target.resource !in resources) {
                problems += ValueProblem(occurrence.id.location, "target_resource_missing")
                return@forEach
            }
            val (contract, slot) = candidates.single()
            if (catalog != null) {
                val sourceEndpoint = if (slot == EndpointSlot.First) contract.first else contract.second
                val targetEndpoint = if (slot == EndpointSlot.First) contract.second else contract.first
                if (!resources.getValue(occurrence.source).matches(sourceEndpoint.resource, catalog)) {
                    problems += ValueProblem(occurrence.id.location, "source_resource_type_mismatch")
                    return@forEach
                }
                if (!resources.getValue(occurrence.target.resource).matches(targetEndpoint.resource, catalog)) {
                    problems += ValueProblem(occurrence.id.location, "target_resource_type_mismatch")
                    return@forEach
                }
                val sourceRecord = resources.getValue(occurrence.source)
                val declared = sourceRecord.linkSlots(catalog).singleOrNull { it.location == occurrence.id.location.path }
                if (declared == null || declared.endpoint != occurrence.id.endpoint) {
                    problems += ValueProblem(occurrence.id.location, "endpoint_location_not_declared")
                    return@forEach
                }
                val expectsCollection = targetEndpoint.cardinality == EndpointCardinality.Many
                if (declared.containsCollection != expectsCollection) {
                    problems += ValueProblem(occurrence.id.location, "endpoint_binding_cardinality_mismatch")
                    return@forEach
                }
                if (!resources.getValue(occurrence.target.resource).matches(declared.target, catalog)) {
                    problems += ValueProblem(occurrence.id.location, "binding_target_type_mismatch")
                    return@forEach
                }
            }
            val oppositeLocation = occurrence.target.opposite?.let { ValueLocation(occurrence.target.resource, it) }
            val opposite = oppositeLocation?.let(byLocation::get)
            if (oppositeLocation != null) {
                val expected = if (slot == EndpointSlot.First) contract.second.id else contract.first.id
                if (
                    opposite == null ||
                    opposite.id.endpoint != expected ||
                    opposite.target.resource != occurrence.source ||
                    opposite.target.opposite != occurrence.id.location.path
                ) {
                    problems += ValueProblem(occurrence.id.location, "opposite_occurrence_mismatch")
                    return@forEach
                }
            }
            val projection =
                if (slot == EndpointSlot.First) {
                    LinkProjection(
                        contract = contract.id,
                        first = occurrence.source,
                        second = occurrence.target.resource,
                        firstLocation = occurrence.id.location.path,
                        secondLocation = opposite?.id?.location?.path,
                    )
                } else {
                    LinkProjection(
                        contract = contract.id,
                        first = occurrence.target.resource,
                        second = occurrence.source,
                        firstLocation = opposite?.id?.location?.path,
                        secondLocation = occurrence.id.location.path,
                    )
                }
            projected += projection
        }
        return ProjectionResult(projected.sortedBy(::projectionKey), problems.distinct())
    }

    fun declaredLocations(
        endpoint: com.typewritermc.types.EndpointId,
        resource: ResourceId,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): List<ValueLocation> = declaredEvidence(endpoint, resource, record, catalog).values

    fun declaredEvidence(
        endpoint: com.typewritermc.types.EndpointId,
        resource: ResourceId,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
        capabilities: LinkSchemaCapabilities = LinkSchemaCapabilities(catalog),
    ): DeclaredLinkEvidence {
        val values = linkedSetOf<ValuePath>()
        val memberships = linkedSetOf<ValuePath>()
        val forms = linkedSetOf<ValuePath>()
        val fields = record.resolvedFields(catalog)
        fields.forEach { field ->
            collectLinkEvidence(
                declared = field.type,
                value = record.fields[field.key] ?: DataValue.Unfilled,
                path = ValuePath(listOf(PathSegment.Field(field.key))),
                endpoint = endpoint,
                catalog = catalog,
                capabilities = capabilities,
                values = values,
                memberships = memberships,
                forms = forms,
            )
        }
        return DeclaredLinkEvidence(
            values = values.sortedBy { it.toString() }.map { ValueLocation(resource, it) },
            memberships = memberships.sortedBy { it.toString() }.map { ValueLocation(resource, it) },
            forms = forms.sortedBy { it.toString() }.map { ValueLocation(resource, it) },
        )
    }

    fun counterpartBinding(
        endpoint: com.typewritermc.types.EndpointId,
        resource: ResourceId,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): CounterpartBinding {
        val slots = record.linkSlots(catalog).filter { it.endpoint == endpoint }
        val directCollections = slots.mapNotNull(LinkSchemaSlot::directCollection).distinct()
        val scalarLocations = slots.filterNot(LinkSchemaSlot::containsCollection).mapNotNull(LinkSchemaSlot::location).distinct()
        val choices =
            buildList {
                directCollections.forEach { add(CounterpartBinding.Collection(ValueLocation(resource, it))) }
                scalarLocations.forEach { add(CounterpartBinding.Scalar(ValueLocation(resource, it))) }
            }.distinct()
        return when (choices.size) {
            0 -> if (slots.isEmpty()) CounterpartBinding.Missing else CounterpartBinding.ExplicitChoice
            1 -> choices.single()
            else -> CounterpartBinding.ExplicitChoice
        }
    }

    fun expectedTarget(
        occurrence: LinkOccurrence,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): TypeUse? =
        record
            .linkSlots(catalog)
            .singleOrNull { it.location == occurrence.id.location.path && it.endpoint == occurrence.id.endpoint }
            ?.target

    private fun collect(
        source: ResourceId,
        value: DataValue,
        location: ValueLocation,
        target: MutableList<LinkOccurrence>,
    ) {
        when (value) {
            is DataValue.Link -> {
                val id = LinkOccurrenceId(value.endpoint, location)
                target += LinkOccurrence(id, source, LinkTarget(value.target.resource, value.target.opposite))
            }

            is DataValue.Named -> {
                collect(source, value.payload, location, target)
            }

            is DataValue.Record -> {
                value.fields.forEach { (name, field) -> collect(source, field, location.field(name), target) }
            }

            is DataValue.ListValue -> {
                value.items.forEach { collect(source, it.value, location.item(it.id), target) }
            }

            is DataValue.SetValue -> {
                value.items.forEach { collect(source, it.value, location.item(it.id), target) }
            }

            is DataValue.MapValue -> {
                value.rows.forEach { row ->
                    collect(source, row.key, location.item(row.id).mapKey(), target)
                    collect(source, row.value, location.item(row.id).mapValue(), target)
                }
            }

            else -> {
            }
        }
    }
}

private data class LinkSchemaSlot(
    val endpoint: com.typewritermc.types.EndpointId,
    val target: TypeUse,
    val location: ValuePath?,
    val containsCollection: Boolean,
    val directCollection: ValuePath?,
)

private fun AuthoringRecord.linkSlots(catalog: CheckedCatalog): List<LinkSchemaSlot> {
    val slots = mutableListOf<LinkSchemaSlot>()
    resolvedFields(catalog).forEach { field ->
        collectLinkSlots(
            declared = field.type,
            value = fields[field.key] ?: DataValue.Unfilled,
            path = ValuePath(listOf(PathSegment.Field(field.key))),
            catalog = catalog,
            containsCollection = false,
            directCollection = null,
            slots = slots,
        )
    }
    return slots.distinct()
}

private fun AuthoringRecord.resolvedFields(catalog: CheckedCatalog) =
    when (val selected = configuration) {
        is com.typewritermc.authoring.TypeSelection.Complete -> {
            val resolved = catalog.resolve(selected.use) as? Resolution.Ready
            val record =
                resolved?.value?.schema?.representation as? com.typewritermc.types.catalog.ResolvedRepresentation.Record
            record?.fields.orEmpty()
        }

        is com.typewritermc.authoring.TypeSelection.Pending -> {
            val partial = catalog.resolvePartial(selected) as? Resolution.Ready
            partial?.value?.knownFields.orEmpty()
        }
    }

private fun collectLinkEvidence(
    declared: TypeUse,
    value: DataValue,
    path: ValuePath,
    endpoint: com.typewritermc.types.EndpointId,
    catalog: CheckedCatalog,
    capabilities: LinkSchemaCapabilities,
    values: MutableSet<ValuePath>,
    memberships: MutableSet<ValuePath>,
    forms: MutableSet<ValuePath>,
) {
    val nonNull = if (declared is TypeUse.Nullable) declared.value else declared
    if (declared is TypeUse.Nullable && value == DataValue.Null) {
        if (capabilities.contains(nonNull, endpoint)) forms += path
        return
    }
    val named = value as? DataValue.Named
    val effective = named?.actualType ?: nonNull
    if (named != null && !catalog.isReadableAs(named.actualType, nonNull)) {
        if (capabilities.contains(nonNull, endpoint)) forms += path
        return
    }
    val resolved = catalog.resolve(effective) as? Resolution.Ready ?: return
    val payload = named?.payload ?: value
    when (val representation = resolved.value.schema.representation) {
        is com.typewritermc.types.catalog.ResolvedRepresentation.Link -> {
            if (representation.endpoint == endpoint) values += path
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Record -> {
            if (!capabilities.contains(effective, endpoint)) return
            forms += path
            val record = payload as? DataValue.Record ?: return
            representation.fields.forEach { field ->
                collectLinkEvidence(
                    field.type,
                    record.fields[field.key] ?: DataValue.Unfilled,
                    path.field(field.key),
                    endpoint,
                    catalog,
                    capabilities,
                    values,
                    memberships,
                    forms,
                )
            }
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Sequence -> {
            if (!capabilities.contains(representation.item, endpoint)) return
            forms += path
            memberships += path
            val items =
                when (payload) {
                    is DataValue.ListValue -> payload.items
                    is DataValue.SetValue -> payload.items
                    else -> emptyList()
                }
            items.forEach { item ->
                collectLinkEvidence(
                    representation.item,
                    item.value,
                    path.item(item.id),
                    endpoint,
                    catalog,
                    capabilities,
                    values,
                    memberships,
                    forms,
                )
            }
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Mapping -> {
            val keyContains = capabilities.contains(representation.key, endpoint)
            val valueContains = capabilities.contains(representation.value, endpoint)
            if (!keyContains && !valueContains) return
            forms += path
            memberships += path
            val mapping = payload as? DataValue.MapValue ?: return
            mapping.rows.forEach { row ->
                if (keyContains) {
                    collectLinkEvidence(
                        representation.key,
                        row.key,
                        path.item(row.id).mapKey(),
                        endpoint,
                        catalog,
                        capabilities,
                        values,
                        memberships,
                        forms,
                    )
                }
                if (valueContains) {
                    collectLinkEvidence(
                        representation.value,
                        row.value,
                        path.item(row.id).mapValue(),
                        endpoint,
                        catalog,
                        capabilities,
                        values,
                        memberships,
                        forms,
                    )
                }
            }
        }

        else -> {}
    }
}

private const val MAX_SCHEMA_CAPABILITY_DEPTH = 64

private fun collectLinkSlots(
    declared: TypeUse,
    value: DataValue,
    path: ValuePath,
    catalog: CheckedCatalog,
    containsCollection: Boolean,
    directCollection: ValuePath?,
    slots: MutableList<LinkSchemaSlot>,
) {
    val nonNull = if (declared is TypeUse.Nullable) declared.value else declared
    if (value == DataValue.Null) return
    val named = value as? DataValue.Named
    val effective =
        if (named == null) {
            nonNull
        } else {
            if (!catalog.isReadableAs(named.actualType, nonNull)) return
            named.actualType
        }
    val resolved = catalog.resolve(effective) as? Resolution.Ready ?: return
    val payload = named?.payload ?: value
    when (val representation = resolved.value.schema.representation) {
        is com.typewritermc.types.catalog.ResolvedRepresentation.Link -> {
            slots +=
                LinkSchemaSlot(
                    endpoint = representation.endpoint,
                    target = representation.target,
                    location = path,
                    containsCollection = containsCollection,
                    directCollection = directCollection,
                )
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Record -> {
            val record = payload as? DataValue.Record ?: return
            representation.fields.forEach { field ->
                val child = record.fields[field.key] ?: DataValue.Unfilled
                collectLinkSlots(
                    field.type,
                    child,
                    path.field(field.key),
                    catalog,
                    containsCollection,
                    directCollection,
                    slots,
                )
            }
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Sequence -> {
            val items =
                when (payload) {
                    is DataValue.ListValue -> payload.items
                    is DataValue.SetValue -> payload.items
                    else -> emptyList()
                }
            val itemRepresentation = catalog.resolve(representation.item) as? Resolution.Ready
            val directLink =
                itemRepresentation?.value?.schema?.representation
                    as? com.typewritermc.types.catalog.ResolvedRepresentation.Link
            if (directLink != null) {
                val link = directLink
                slots += LinkSchemaSlot(link.endpoint, link.target, null, true, path)
            }
            items.forEach { item ->
                collectLinkSlots(
                    representation.item,
                    item.value,
                    path.item(item.id),
                    catalog,
                    containsCollection = true,
                    directCollection = path.takeIf { directLink != null },
                    slots = slots,
                )
            }
        }

        is com.typewritermc.types.catalog.ResolvedRepresentation.Mapping -> {
            val mapping = payload as? DataValue.MapValue ?: return
            mapping.rows.forEach { row ->
                collectLinkSlots(
                    representation.key,
                    row.key,
                    path.item(row.id).mapKey(),
                    catalog,
                    containsCollection = true,
                    directCollection = null,
                    slots = slots,
                )
                collectLinkSlots(
                    representation.value,
                    row.value,
                    path.item(row.id).mapValue(),
                    catalog,
                    containsCollection = true,
                    directCollection = null,
                    slots = slots,
                )
            }
        }

        else -> {
        }
    }
}

private fun AuthoringRecord.matches(
    expected: TypeUse,
    catalog: CheckedCatalog,
): Boolean =
    when (val selected = configuration) {
        is com.typewritermc.authoring.TypeSelection.Complete -> {
            catalog.isReadableAs(selected.use, expected)
        }

        is com.typewritermc.authoring.TypeSelection.Pending -> {
            catalog.knownApplications(selected).any { application -> catalog.isReadableAs(application, expected) }
        }
    }

private fun AuthoringRecord.matches(
    expected: TypeTemplate.Named,
    catalog: CheckedCatalog,
): Boolean {
    val expectedUse = expected.toUseOrNull()
    return when (val selected = configuration) {
        is com.typewritermc.authoring.TypeSelection.Complete -> {
            expectedUse?.let { catalog.isReadableAs(selected.use, it) }
                ?: catalog.isNominalSubtype(selected.use.definition, expected.definition)
        }

        is com.typewritermc.authoring.TypeSelection.Pending -> {
            expectedUse?.let { concrete ->
                catalog.knownApplications(selected).any { application -> catalog.isReadableAs(application, concrete) }
            } ?: catalog.isNominalSubtype(selected.definition, expected.definition)
        }
    }
}

private fun TypeTemplate.toUseOrNull(): TypeUse? =
    when (this) {
        is TypeTemplate.Parameter -> {
            null
        }

        is TypeTemplate.Named -> {
            val applied = arguments.map { it.toUseOrNull() ?: return null }
            TypeUse.Named(definition, applied)
        }

        is TypeTemplate.Nullable -> {
            value.toUseOrNull()?.let(TypeUse::Nullable)
        }

        is TypeTemplate.Scalar -> {
            TypeUse.Scalar(kind)
        }
    }

private fun occurrenceKey(value: LinkOccurrence): String =
    "${value.id.endpoint.value}:${value.source.value}:${value.id.location.path}:${value.target.resource.value}"

private fun projectionKey(value: LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:${value.firstLocation}:${value.secondLocation}"

private fun ValueLocation.field(name: String) = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: com.typewritermc.authoring.ItemId) = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey() = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue() = copy(path = ValuePath(path.segments + PathSegment.MapValue))

private fun ValuePath.field(name: String) = ValuePath(segments + PathSegment.Field(name))

private fun ValuePath.item(id: com.typewritermc.authoring.ItemId) = ValuePath(segments + PathSegment.Item(id))

private fun ValuePath.mapKey() = ValuePath(segments + PathSegment.MapKey)

private fun ValuePath.mapValue() = ValuePath(segments + PathSegment.MapValue)
