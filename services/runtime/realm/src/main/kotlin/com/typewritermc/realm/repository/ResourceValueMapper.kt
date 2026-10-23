package com.typewritermc.realm.repository

import com.typewritermc.authoring.definition
import com.typewritermc.authoring.descendants
import com.typewritermc.authoring.field
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.nullable
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId
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
    private val cache = ConcurrentHashMap<Pair<TypeUse, EndpointId>, Boolean>()

    fun contains(
        use: TypeUse,
        endpoint: EndpointId,
    ): Boolean = cache.computeIfAbsent(use to endpoint) { contains(it.first, it.second, emptySet(), 0) }

    private fun contains(
        use: TypeUse,
        endpoint: EndpointId,
        visited: Set<TypeUse>,
        depth: Int,
    ): Boolean {
        if (depth >= MAX_SCHEMA_CAPABILITY_DEPTH) return true
        val nonNull = if (use is TypeUse.NullableWrapper) use.value.value else use
        if (nonNull in visited) return false
        val resolved = catalog.resolve(nonNull) as? Resolution.Ready ?: return true
        val nextVisited = visited + nonNull
        return when (val representation = resolved.value.schema.representation) {
            is ResolvedRepresentation.LinkWrapper -> {
                representation.value.endpoint == endpoint
            }

            is ResolvedRepresentation.RecordWrapper -> {
                representation.value.abstract_ ||
                    representation.value.fields.any { contains(it.type, endpoint, nextVisited, depth + 1) }
            }

            is ResolvedRepresentation.SequenceWrapper -> {
                contains(representation.value.item, endpoint, nextVisited, depth + 1)
            }

            is ResolvedRepresentation.MappingWrapper -> {
                contains(representation.value.key, endpoint, nextVisited, depth + 1) ||
                    contains(representation.value.value, endpoint, nextVisited, depth + 1)
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

/**
 * Derives relation occurrences and canonical graph projections from authored resource fields.
 *
 * An occurrence identifies the exact endpoint and value location that authors can edit. Projection combines
 * agreeing opposite occurrences into one directed contract edge and reports invalid bindings as problems.
 * Stored edge rows and graph indexes are rebuildable views of those values, never independent authoring state.
 * Schema evidence also records unfilled locations and collection membership needed for conflict tracking.
 */
internal object ResourceValueMapper {
    fun discover(resources: Map<ResourceId, AuthoringRecord>): List<LinkOccurrence> =
        resources.flatMap { (source, record) ->
            DataValue
                .RecordWrapper(record.payload)
                .descendants()
                .mapNotNull { node ->
                    val link = node.value as? DataValue.LinkWrapper ?: return@mapNotNull null
                    val location = ValueLocation.of(source, node.path)
                    LinkOccurrence(
                        id = LinkOccurrenceId(endpoint = link.endpoint, location = location),
                        source = source,
                        target = link.value.target,
                    )
                }.toList()
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
                problems +=
                    ValueProblem(
                        location = occurrence.id.location,
                        code = if (candidates.isEmpty()) "unknown_endpoint" else "ambiguous_endpoint",
                    )
                return@forEach
            }
            if (occurrence.target.resource !in resources) {
                problems += ValueProblem(location = occurrence.id.location, code = "target_resource_missing")
                return@forEach
            }
            val (contract, slot) = candidates.single()
            if (catalog != null) {
                val sourceEndpoint = if (slot == EndpointSlot.FIRST) contract.first else contract.second
                val targetEndpoint = if (slot == EndpointSlot.FIRST) contract.second else contract.first
                if (!resources.getValue(occurrence.source).matches(sourceEndpoint.resource, catalog)) {
                    problems += ValueProblem(location = occurrence.id.location, code = "source_resource_type_mismatch")
                    return@forEach
                }
                if (!resources.getValue(occurrence.target.resource).matches(targetEndpoint.resource, catalog)) {
                    problems += ValueProblem(location = occurrence.id.location, code = "target_resource_type_mismatch")
                    return@forEach
                }
                val sourceRecord = resources.getValue(occurrence.source)
                val declared = sourceRecord.linkSlots(catalog).singleOrNull { it.location == occurrence.id.location.path }
                if (declared == null || declared.endpoint != occurrence.id.endpoint) {
                    problems += ValueProblem(location = occurrence.id.location, code = "endpoint_location_not_declared")
                    return@forEach
                }
                val expectsCollection = targetEndpoint.cardinality == EndpointCardinality.MANY
                if (declared.containsCollection != expectsCollection) {
                    problems += ValueProblem(location = occurrence.id.location, code = "endpoint_binding_cardinality_mismatch")
                    return@forEach
                }
                if (!resources.getValue(occurrence.target.resource).matches(declared.target, catalog)) {
                    problems += ValueProblem(location = occurrence.id.location, code = "binding_target_type_mismatch")
                    return@forEach
                }
            }
            val oppositeLocation = occurrence.target.opposite?.let { ValueLocation(resource = occurrence.target.resource, path = it) }
            val opposite = oppositeLocation?.let(byLocation::get)
            if (oppositeLocation != null) {
                val expected = if (slot == EndpointSlot.FIRST) contract.second.id else contract.first.id
                if (
                    opposite == null ||
                    opposite.id.endpoint != expected ||
                    opposite.target.resource != occurrence.source ||
                    opposite.target.opposite != occurrence.id.location.path
                ) {
                    problems += ValueProblem(location = occurrence.id.location, code = "opposite_occurrence_mismatch")
                    return@forEach
                }
            }
            val projection =
                if (slot == EndpointSlot.FIRST) {
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
        endpoint: EndpointId,
        resource: ResourceId,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): List<ValueLocation> = declaredEvidence(endpoint, resource, record, catalog).values

    fun declaredEvidence(
        endpoint: EndpointId,
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
                value = record.field(field.key) ?: DataValue.UNFILLED,
                path = ValuePath.root.field(field.key),
                endpoint = endpoint,
                catalog = catalog,
                capabilities = capabilities,
                values = values,
                memberships = memberships,
                forms = forms,
            )
        }
        return DeclaredLinkEvidence(
            values = values.sortedBy(ValuePath.serializer::toJsonCode).map { ValueLocation.of(resource, it) },
            memberships = memberships.sortedBy(ValuePath.serializer::toJsonCode).map { ValueLocation.of(resource, it) },
            forms = forms.sortedBy(ValuePath.serializer::toJsonCode).map { ValueLocation.of(resource, it) },
        )
    }

    fun counterpartBinding(
        endpoint: EndpointId,
        resource: ResourceId,
        record: AuthoringRecord,
        catalog: CheckedCatalog,
    ): CounterpartBinding {
        val slots = record.linkSlots(catalog).filter { it.endpoint == endpoint }
        val directCollections = slots.mapNotNull(LinkSchemaSlot::directCollection).distinct()
        val scalarLocations = slots.filterNot(LinkSchemaSlot::containsCollection).mapNotNull(LinkSchemaSlot::location).distinct()
        val choices =
            buildList {
                directCollections.forEach { add(CounterpartBinding.Collection(ValueLocation.of(resource, it))) }
                scalarLocations.forEach { add(CounterpartBinding.Scalar(ValueLocation.of(resource, it))) }
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
}

private data class LinkSchemaSlot(
    val endpoint: EndpointId,
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
            value = this.field(field.key) ?: DataValue.UNFILLED,
            path = ValuePath.root.field(field.key),
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
        is TypeSelection.CompleteWrapper -> {
            val resolved = catalog.resolve(selected.use.use) as? Resolution.Ready
            val record =
                resolved?.value?.schema?.representation as? ResolvedRepresentation.RecordWrapper
            record?.value?.fields.orEmpty()
        }

        is TypeSelection.PendingWrapper -> {
            val partial = catalog.resolvePartial(selected) as? Resolution.Ready
            partial?.value?.knownFields.orEmpty()
        }

        else -> {
            unknownVariant(selected)
        }
    }

private fun collectLinkEvidence(
    declared: TypeUse,
    value: DataValue,
    path: ValuePath,
    endpoint: EndpointId,
    catalog: CheckedCatalog,
    capabilities: LinkSchemaCapabilities,
    values: MutableSet<ValuePath>,
    memberships: MutableSet<ValuePath>,
    forms: MutableSet<ValuePath>,
) {
    val nonNull = if (declared is TypeUse.NullableWrapper) declared.value.value else declared
    if (declared is TypeUse.NullableWrapper && value == DataValue.NULL) {
        if (capabilities.contains(nonNull, endpoint)) forms += path
        return
    }
    val named = value as? DataValue.NamedWrapper
    val effective = named?.actualType?.use ?: nonNull
    if (named != null && !catalog.isReadableAs(named.actualType.use, nonNull)) {
        if (capabilities.contains(nonNull, endpoint)) forms += path
        return
    }
    val resolved = catalog.resolve(effective) as? Resolution.Ready ?: return
    val payload = named?.payload ?: value
    when (val representation = resolved.value.schema.representation) {
        is ResolvedRepresentation.LinkWrapper -> {
            if (representation.value.endpoint == endpoint) values += path
        }

        is ResolvedRepresentation.RecordWrapper -> {
            if (!capabilities.contains(effective, endpoint)) return
            forms += path
            val record = payload as? DataValue.RecordWrapper ?: return
            representation.value.fields.forEach { field ->
                collectLinkEvidence(
                    field.type,
                    record.field(field.key) ?: DataValue.UNFILLED,
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

        is ResolvedRepresentation.SequenceWrapper -> {
            if (!capabilities.contains(representation.value.item, endpoint)) return
            forms += path
            memberships += path
            val items =
                when (payload) {
                    is DataValue.ListValueWrapper -> payload.items
                    is DataValue.SetValueWrapper -> payload.items
                    else -> emptyList()
                }
            items.forEach { item ->
                collectLinkEvidence(
                    representation.value.item,
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

        is ResolvedRepresentation.MappingWrapper -> {
            val keyContains = capabilities.contains(representation.value.key, endpoint)
            val valueContains = capabilities.contains(representation.value.value, endpoint)
            if (!keyContains && !valueContains) return
            forms += path
            memberships += path
            val mapping = payload as? DataValue.MapValueWrapper ?: return
            mapping.rows.forEach { row ->
                if (keyContains) {
                    collectLinkEvidence(
                        representation.value.key,
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
                        representation.value.value,
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
    val nonNull = if (declared is TypeUse.NullableWrapper) declared.value.value else declared
    if (value == DataValue.NULL) return
    val named = value as? DataValue.NamedWrapper
    val effective =
        if (named == null) {
            nonNull
        } else {
            if (!catalog.isReadableAs(named.actualType.use, nonNull)) return
            named.actualType.use
        }
    val resolved = catalog.resolve(effective) as? Resolution.Ready ?: return
    val payload = named?.payload ?: value
    when (val representation = resolved.value.schema.representation) {
        is ResolvedRepresentation.LinkWrapper -> {
            slots +=
                LinkSchemaSlot(
                    endpoint = representation.value.endpoint,
                    target = representation.value.target,
                    location = path,
                    containsCollection = containsCollection,
                    directCollection = directCollection,
                )
        }

        is ResolvedRepresentation.RecordWrapper -> {
            val record = payload as? DataValue.RecordWrapper ?: return
            representation.value.fields.forEach { field ->
                val child = record.field(field.key) ?: DataValue.UNFILLED
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

        is ResolvedRepresentation.SequenceWrapper -> {
            val items =
                when (payload) {
                    is DataValue.ListValueWrapper -> payload.items
                    is DataValue.SetValueWrapper -> payload.items
                    else -> emptyList()
                }
            val itemRepresentation = catalog.resolve(representation.value.item) as? Resolution.Ready
            val directLink =
                itemRepresentation?.value?.schema?.representation
                    as? ResolvedRepresentation.LinkWrapper
            if (directLink != null) {
                val link = directLink
                slots += LinkSchemaSlot(link.value.endpoint, link.value.target, null, true, path)
            }
            items.forEach { item ->
                collectLinkSlots(
                    representation.value.item,
                    item.value,
                    path.item(item.id),
                    catalog,
                    containsCollection = true,
                    directCollection = path.takeIf { directLink != null },
                    slots = slots,
                )
            }
        }

        is ResolvedRepresentation.MappingWrapper -> {
            val mapping = payload as? DataValue.MapValueWrapper ?: return
            mapping.rows.forEach { row ->
                collectLinkSlots(
                    representation.value.key,
                    row.key,
                    path.item(row.id).mapKey(),
                    catalog,
                    containsCollection = true,
                    directCollection = null,
                    slots = slots,
                )
                collectLinkSlots(
                    representation.value.value,
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
        is TypeSelection.CompleteWrapper -> {
            catalog.isReadableAs(selected.use.use, expected)
        }

        is TypeSelection.PendingWrapper -> {
            catalog.knownApplications(selected).any { application -> catalog.isReadableAs(application.use, expected) }
        }

        else -> {
            unknownVariant(selected)
        }
    }

private fun AuthoringRecord.matches(
    expected: NamedTypeTemplate,
    catalog: CheckedCatalog,
): Boolean {
    val expectedUse = expected.template.toUseOrNull()
    return when (val selected = configuration) {
        is TypeSelection.CompleteWrapper -> {
            expectedUse?.let { catalog.isReadableAs(selected.use.use, it) }
                ?: catalog.isNominalSubtype(selected.use.definition, expected.definition)
        }

        is TypeSelection.PendingWrapper -> {
            expectedUse?.let { concrete ->
                catalog.knownApplications(selected).any { application -> catalog.isReadableAs(application.use, concrete) }
            } ?: catalog.isNominalSubtype(selected.definition, expected.definition)
        }

        else -> {
            unknownVariant(selected)
        }
    }
}

private fun TypeTemplate.toUseOrNull(): TypeUse? =
    when (this) {
        is TypeTemplate.ParameterWrapper -> {
            null
        }

        is TypeTemplate.NamedWrapper -> {
            val applied = value.arguments.map { it.toUseOrNull() ?: return null }
            value.definition.use(applied)
        }

        is TypeTemplate.NullableWrapper -> {
            value.value.toUseOrNull()?.nullable()
        }

        is TypeTemplate.ScalarWrapper -> {
            value.use
        }

        else -> {
            unknownVariant(this)
        }
    }

private fun occurrenceKey(value: LinkOccurrence): String =
    "${value.id.endpoint.value}:${value.source.value}:${ValuePath.serializer.toJsonCode(
        value.id.location.path,
    )}:${value.target.resource.value}"

private fun projectionKey(value: LinkProjection): String =
    "${value.contract.value}:${value.first.value}:${value.second.value}:" +
        "${value.firstLocation?.let(ValuePath.serializer::toJsonCode)}:${value.secondLocation?.let(ValuePath.serializer::toJsonCode)}"
