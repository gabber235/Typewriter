package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.requiredExpectations
import com.typewritermc.realm.repository.sameFact
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation

internal data class TypeArgumentChangePreview(
    val resource: ResourceId,
    val next: TypeSelection,
    val edit: PreparedEdit,
    val linkRepairs: List<LinkRepairIntent>,
    val clearedLocations: List<ValueLocation>,
)

internal sealed interface LinkRepairIntent {
    data class Clear(
        val occurrence: LinkOccurrenceId,
    ) : LinkRepairIntent

    data class Remove(
        val occurrence: LinkOccurrenceId,
    ) : LinkRepairIntent
}

internal sealed interface TypePreviewResult {
    data class Ready(
        val preview: TypeArgumentChangePreview,
    ) : TypePreviewResult

    data class InvalidArguments(
        val diagnostics: List<DeclarationDiagnostic>,
    ) : TypePreviewResult

    data class Incomplete(
        val arguments: List<ArgumentLocation>,
    ) : TypePreviewResult

    data class Rejected(
        val problems: List<com.typewritermc.authoring.ValueProblem>,
    ) : TypePreviewResult
}

internal interface TypeArgumentOperations {
    fun preview(
        resource: ResourceId,
        requested: TypeSelection,
        snapshot: AuthoringLease,
    ): TypePreviewResult

    suspend fun prepare(preview: TypeArgumentChangePreview): PreparedEditResult
}

/** Previews repairs and prepares validated edits without persisting them. */
internal class DefaultTypeArgumentOperations(
    private val snapshots: AuthoringViewStore,
) : TypeArgumentOperations {
    override fun preview(
        resource: ResourceId,
        requested: TypeSelection,
        snapshot: AuthoringLease,
    ): TypePreviewResult {
        val root = snapshot.root
        val requestedDefinition = requested.definition
        val record =
            root.resources[resource]
                ?: return TypePreviewResult.InvalidArguments(
                    listOf(DeclarationDiagnostic(requestedDefinition, "resource_missing")),
                )
        val previous = record.configuration
        if (previous.definition != requestedDefinition) {
            return TypePreviewResult.InvalidArguments(
                listOf(DeclarationDiagnostic(requestedDefinition, "type_argument_definition_changed")),
            )
        }
        val next = root.catalog.checked.resolvePartial(requested)
        if (next is Resolution.Invalid) return TypePreviewResult.InvalidArguments(next.diagnostics)
        val old = root.catalog.checked.resolvePartial(previous)
        if (old is Resolution.Invalid) return TypePreviewResult.InvalidArguments(old.diagnostics)
        old as Resolution.Ready
        next as Resolution.Ready

        val cleared = mutableListOf<ValueLocation>()
        val nestedRetags = mutableListOf<EditIntent.Retag>()
        val inspected = linkedSetOf<InputIdentity>()
        val rootLocation = ValueLocation(resource, ValuePath())
        val oldFields = old.value.knownFields.associateBy { it.key }
        val newFields = next.value.knownFields.associateBy { it.key }
        newFields.forEach { (name, newField) ->
            val location = rootLocation.field(name)
            val oldField = oldFields[name]
            val value = record.fields[name]
            if (oldField == null || value == null) {
                cleared += location
                inspected += InputIdentity.Value(location)
            } else {
                collectRepairs(
                    value,
                    oldField.type,
                    newField.type,
                    location,
                    root.catalog.checked,
                    cleared,
                    nestedRetags,
                    inspected,
                )
            }
        }
        next.value.dependentFields.forEach { field ->
            val location = rootLocation.field(field.owner.name)
            inspected += InputIdentity.Value(location)
            if (record.fields[field.owner.name] != DataValue.Unfilled) cleared += location
        }
        val relationRepairs =
            incompatibleLinks(
                resource,
                requested,
                root.resources,
                root.links.values,
                root.catalog.relations,
                root.catalog.checked,
                inspected,
            )
        val relationRepairLocations = relationRepairs.mapTo(mutableSetOf(), LinkRepairIntent::location)
        val evidence =
            buildSet<InputIdentity> {
                add(InputIdentity.Existence(resource))
                add(InputIdentity.Form(rootLocation))
                add(InputIdentity.Incoming(resource, null))
                addAll(inspected)
                relationRepairs.forEach { repair ->
                    val occurrence =
                        when (repair) {
                            is LinkRepairIntent.Clear -> repair.occurrence
                            is LinkRepairIntent.Remove -> repair.occurrence
                        }
                    add(InputIdentity.Value(occurrence.location))
                }
                add(InputIdentity.Catalog(root.catalog.generation))
            }.toMutableSet()
        val repairs =
            buildList {
                add(EditIntent.ConfigureResource(resource, requested))
                addAll(nestedRetags)
                cleared
                    .distinct()
                    .filterNot(relationRepairLocations::contains)
                    .forEach { add(EditIntent.SetValue(it, DataValue.Unfilled)) }
            }
        val plannedIntents =
            buildList {
                addAll(repairs)
                relationRepairs.forEach { repair ->
                    val occurrence =
                        when (repair) {
                            is LinkRepairIntent.Clear -> repair.occurrence
                            is LinkRepairIntent.Remove -> repair.occurrence
                        }
                    add(EditIntent.DisconnectRelation(occurrence))
                }
            }
        val planned =
            AuthoringMutationPlanner(
                root.catalog.checked,
                root.catalog.relations,
                root.catalog.endpointBindings,
            ).plan(
                root.resources,
                PreparedEdit(
                    root.catalog.generation,
                    emptyList(),
                    plannedIntents,
                ),
            )
        if (planned is MutationPlanningResult.Rejected) return TypePreviewResult.Rejected(planned.problems)
        planned as MutationPlanningResult.Accepted
        val reads = CapturedAuthoringReads(snapshot.originalView())
        evidence.forEach(reads::observeInput)
        val witness = PreparedEdit(root.catalog.generation, emptyList(), plannedIntents)
        val required =
            root.values.requiredExpectations(
                witness,
                root.resources,
                root.catalog.relations.mapTo(linkedSetOf()) {
                    it.id
                },
                planned.plan,
            )
        val observed = (reads.observations() + required).distinct()
        return TypePreviewResult.Ready(
            TypeArgumentChangePreview(
                resource = resource,
                next = requested,
                edit = PreparedEdit(root.catalog.generation, observed, plannedIntents),
                linkRepairs = relationRepairs,
                clearedLocations =
                    (cleared + relationRepairLocations).distinct(),
            ),
        )
    }

    override suspend fun prepare(preview: TypeArgumentChangePreview): PreparedEditResult {
        val rootLocation = ValueLocation(preview.resource, ValuePath())
        if (!preview.hasCoherentMetadata()) {
            return PreparedEditResult.Rejected(listOf(ValueProblem(rootLocation, "type_argument_preview_mismatch")))
        }
        return snapshots.capture().use { snapshot ->
            if (snapshot.root.catalog.generation != preview.edit.catalog) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(rootLocation, "catalog_changed")))
            }
            val conflicts = snapshot.root.values.conflicts(preview.edit.expectations)
            if (conflicts.isNotEmpty()) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(rootLocation, "expectation_conflict")))
            }
            val verified =
                when (val regenerated = preview(preview.resource, preview.next, snapshot)) {
                    is TypePreviewResult.Ready -> {
                        regenerated.preview
                    }

                    is TypePreviewResult.Rejected -> {
                        return PreparedEditResult.Rejected(regenerated.problems)
                    }

                    else -> {
                        return PreparedEditResult.Rejected(
                            listOf(ValueProblem(rootLocation, "type_argument_preview_no_longer_valid")),
                        )
                    }
                }
            if (!verified.sameRepairs(preview)) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(rootLocation, "type_argument_preview_mismatch")))
            }
            if (preview.edit.expectations.any { expected -> verified.edit.expectations.none { it.sameFact(expected) } } ||
                verified.edit.expectations.any { expected -> preview.edit.expectations.none { it.sameFact(expected) } }
            ) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(rootLocation, "type_argument_preview_mismatch")))
            }
            PreparedEditResult.Prepared(verified.edit)
        }
    }

    private fun TypeArgumentChangePreview.sameRepairs(other: TypeArgumentChangePreview): Boolean =
        resource == other.resource &&
            next == other.next &&
            edit.intents == other.edit.intents &&
            linkRepairs == other.linkRepairs &&
            clearedLocations == other.clearedLocations

    private fun TypeArgumentChangePreview.hasCoherentMetadata(): Boolean {
        val configuration = edit.intents.filterIsInstance<EditIntent.ConfigureResource>()
        if (configuration != listOf(EditIntent.ConfigureResource(resource, next))) return false
        val cleared =
            (
                edit.intents
                    .filterIsInstance<EditIntent.SetValue>()
                    .filter { it.value == DataValue.Unfilled }
                    .map { it.at } +
                    linkRepairs.map(LinkRepairIntent::location)
            ).distinct()
        return clearedLocations == cleared
    }
}

private fun collectRepairs(
    value: DataValue,
    old: TypeUse,
    next: TypeUse,
    at: ValueLocation,
    catalog: CheckedCatalog,
    repairs: MutableList<ValueLocation>,
    retags: MutableList<EditIntent.Retag>,
    inspected: MutableSet<InputIdentity>,
) {
    inspected += InputIdentity.Value(at)
    if (value == DataValue.Unfilled) return
    if (value == DataValue.Null) {
        if (next !is TypeUse.Nullable) repairs += at
        return
    }

    val expected = if (next is TypeUse.Nullable) next.value else next
    val declaredActual = if (old is TypeUse.Nullable) old.value else old
    val actual = (value as? DataValue.Named)?.actualType ?: declaredActual
    if (catalog.isReadableAs(actual, next)) return

    val namedValue = value as? DataValue.Named
    val actualNamed = actual as? TypeUse.Named
    val expectedNamed = expected as? TypeUse.Named
    val canRetag =
        namedValue != null &&
            actualNamed != null &&
            expectedNamed != null &&
            actualNamed.definition == expectedNamed.definition
    if (!canRetag) {
        repairs += at
        return
    }

    inspected += InputIdentity.Form(at)
    val actualType = requireNotNull(actualNamed)
    val expectedType = requireNotNull(expectedNamed)
    val oldResolved = catalog.resolve(actualType) as? Resolution.Ready
    val newResolved = catalog.resolve(expectedType) as? Resolution.Ready
    val oldRepresentation = oldResolved?.value?.schema?.representation
    val newRepresentation = newResolved?.value?.schema?.representation
    if (oldRepresentation == null || newRepresentation == null || oldRepresentation::class != newRepresentation::class) {
        repairs += at
        return
    }
    retags += EditIntent.Retag(at, expectedType)
    val payload = requireNotNull(namedValue).payload
    when {
        payload is DataValue.Record && oldRepresentation is ResolvedRepresentation.Record &&
            newRepresentation is ResolvedRepresentation.Record -> {
            val oldFields = oldRepresentation.fields.associateBy { it.key }
            newRepresentation.fields.forEach { field ->
                val child = payload.fields[field.key]
                val previous = oldFields[field.key]
                val childLocation = at.field(field.key)
                if (child == null || previous == null) {
                    repairs += childLocation
                    inspected += InputIdentity.Value(childLocation)
                } else {
                    collectRepairs(child, previous.type, field.type, childLocation, catalog, repairs, retags, inspected)
                }
            }
        }

        payload is DataValue.ListValue && oldRepresentation is ResolvedRepresentation.Sequence &&
            newRepresentation is ResolvedRepresentation.Sequence -> {
            inspected += InputIdentity.Membership(at)
            inspected += InputIdentity.Order(at)
            payload.items.forEach { item ->
                collectRepairs(
                    item.value,
                    oldRepresentation.item,
                    newRepresentation.item,
                    at.item(item.id),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
            }
        }

        payload is DataValue.SetValue && oldRepresentation is ResolvedRepresentation.Sequence &&
            newRepresentation is ResolvedRepresentation.Sequence -> {
            inspected += InputIdentity.Membership(at)
            payload.items.forEach { item ->
                collectRepairs(
                    item.value,
                    oldRepresentation.item,
                    newRepresentation.item,
                    at.item(item.id),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
            }
        }

        payload is DataValue.MapValue && oldRepresentation is ResolvedRepresentation.Mapping &&
            newRepresentation is ResolvedRepresentation.Mapping -> {
            inspected += InputIdentity.Membership(at)
            inspected += InputIdentity.Order(at)
            payload.rows.forEach { row ->
                collectRepairs(
                    row.key,
                    oldRepresentation.key,
                    newRepresentation.key,
                    at.item(row.id).mapKey(),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
                collectRepairs(
                    row.value,
                    oldRepresentation.value,
                    newRepresentation.value,
                    at.item(row.id).mapValue(),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
            }
        }

        else -> {
            repairs += at
        }
    }
}

private fun incompatibleLinks(
    resource: ResourceId,
    requested: TypeSelection,
    resources: Map<ResourceId, com.typewritermc.authoring.AuthoringRecord>,
    occurrences: Collection<com.typewritermc.authoring.LinkOccurrence>,
    contracts: List<RelationContract>,
    catalog: CheckedCatalog,
    inspected: MutableSet<InputIdentity>,
): List<LinkRepairIntent> {
    val endpointContracts =
        contracts.flatMap { contract -> listOf(contract.first.id to contract, contract.second.id to contract) }.toMap()
    return occurrences
        .mapNotNull { occurrence ->
            if (occurrence.source != resource && occurrence.target.resource != resource) return@mapNotNull null
            val sourceRecord = resources[occurrence.source]
            val targetRecord = resources[occurrence.target.resource]
            inspected += InputIdentity.Form(ValueLocation(occurrence.source, ValuePath()))
            inspected += InputIdentity.Value(occurrence.id.location)
            inspected += InputIdentity.Form(ValueLocation(occurrence.target.resource, ValuePath()))
            val contract = endpointContracts[occurrence.id.endpoint] ?: return@mapNotNull LinkRepairIntent.Clear(occurrence.id)
            val sourceEndpoint = if (contract.first.id == occurrence.id.endpoint) contract.first else contract.second
            val targetEndpoint = if (sourceEndpoint.slot == EndpointSlot.First) contract.second else contract.first
            inspected += InputIdentity.Incoming(resource, contract.id)
            val proposedSource = sourceRecord?.proposedIf(occurrence.source == resource, requested)
            val proposedTarget = targetRecord?.proposedIf(occurrence.target.resource == resource, requested)
            val expectedTarget =
                proposedSource?.let {
                    ResourceValueMapper.expectedTarget(occurrence, it, catalog)
                }
            val sourceValid = proposedSource?.matches(sourceEndpoint.resource, catalog) == true
            val targetValid = proposedTarget?.matches(targetEndpoint.resource, catalog) == true
            val bindingValid = expectedTarget != null && proposedTarget?.matches(expectedTarget, catalog) == true
            if (sourceValid && targetValid && bindingValid) {
                null
            } else if (occurrence.id.location.path.segments
                    .lastOrNull() is PathSegment.Item
            ) {
                LinkRepairIntent.Remove(occurrence.id)
            } else {
                LinkRepairIntent.Clear(occurrence.id)
            }
        }.distinct()
}

private fun com.typewritermc.authoring.AuthoringRecord.proposedIf(
    proposed: Boolean,
    requested: TypeSelection,
): com.typewritermc.authoring.AuthoringRecord = if (proposed) copy(configuration = requested) else this

private fun com.typewritermc.authoring.AuthoringRecord.matches(
    expected: TypeUse,
    catalog: CheckedCatalog,
): Boolean =
    when (val selected = configuration) {
        is TypeSelection.Complete -> catalog.isReadableAs(selected.use, expected)
        is TypeSelection.Pending -> catalog.knownApplications(selected).any { catalog.isReadableAs(it, expected) }
    }

private fun com.typewritermc.authoring.AuthoringRecord.matches(
    expected: TypeTemplate.Named,
    catalog: CheckedCatalog,
): Boolean {
    val concrete = expected.concreteUseOrNull()
    if (concrete != null) return matches(concrete, catalog)
    return catalog.isNominalSubtype(configuration.definition, expected.definition)
}

private val LinkRepairIntent.location: ValueLocation
    get() =
        when (this) {
            is LinkRepairIntent.Clear -> occurrence.location
            is LinkRepairIntent.Remove -> occurrence.location
        }

private fun TypeTemplate.concreteUseOrNull(): TypeUse? {
    return when (this) {
        is TypeTemplate.Parameter -> null
        is TypeTemplate.Named -> TypeUse.Named(definition, arguments.map { it.concreteUseOrNull() ?: return null })
        is TypeTemplate.Nullable -> value.concreteUseOrNull()?.let(TypeUse::Nullable)
        is TypeTemplate.Scalar -> TypeUse.Scalar(kind)
    }
}

private val TypeSelection.definition
    get() =
        when (this) {
            is TypeSelection.Complete -> use.definition
            is TypeSelection.Pending -> definition
        }

private fun ValueLocation.field(name: String) = copy(path = ValuePath(path.segments + PathSegment.Field(name)))

private fun ValueLocation.item(id: com.typewritermc.authoring.ItemId) = copy(path = ValuePath(path.segments + PathSegment.Item(id)))

private fun ValueLocation.mapKey() = copy(path = ValuePath(path.segments + PathSegment.MapKey))

private fun ValueLocation.mapValue() = copy(path = ValuePath(path.segments + PathSegment.MapValue))
