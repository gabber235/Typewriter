package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ArgumentLocation
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.PreparedEditResult
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.authoring.use
import com.typewritermc.checking.InputIdentity
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.AuthoringMutationPlanner
import com.typewritermc.realm.repository.MutationPlanningResult
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.realm.repository.requiredExpectations
import com.typewritermc.realm.repository.sameFact
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.ResourceId
import com.typewritermc.types.actualType
import com.typewritermc.types.catalog.CheckedCatalog
import com.typewritermc.types.catalog.DeclarationDiagnostic
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.nullable
import com.typewritermc.types.payload
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.skir.getOrThrow
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.LinkRepairIntent
import skirout.editor.v1.authoring.TypeArgumentChangePreview
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.authoring.PreparedEdit as SkirPreparedEdit

/** Checks a preview received from an editor; preparation decodes and checks its edit. */
internal fun TypeArgumentChangePreview.requireValid(): TypeArgumentChangePreview =
    apply {
        resource.requireValid()
        next.requireValid()
        linkRepairs.forEach { it.occurrence.requireValid() }
        clearedLocations.forEach { it.requireValid() }
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
        val problems: List<ValueProblem>,
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

/**
 * Previews a resource type argument change together with repairs to values and incident links.
 *
 * The resource type definition remains fixed. Incompatible values become unfilled, compatible nested records can
 * be retagged, and invalid links become disconnect intents. Preparation checks current expectations and
 * regenerates the preview before returning an edit, so caller supplied repair metadata is never trusted as
 * authority. Persistence remains a separate authoring commit.
 */
internal class DefaultTypeArgumentOperations(
    private val views: AuthoringViewStore,
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
        val rootLocation = ValueLocation.of(resource)
        val oldFields = old.value.knownFields.associateBy { it.key }
        val newFields = next.value.knownFields.associateBy { it.key }
        newFields.forEach { (name, newField) ->
            val location = rootLocation.field(name)
            val oldField = oldFields[name]
            val value = record.field(name)
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
            if (record.field(field.owner.name) != DataValue.UNFILLED) cleared += location
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
        val relationRepairLocations = relationRepairs.mapTo(mutableSetOf()) { it.occurrence.location }
        val evidence =
            buildSet<InputIdentity> {
                add(InputIdentity.Existence(resource))
                add(InputIdentity.Form(rootLocation))
                add(InputIdentity.Incoming(resource, null))
                addAll(inspected)
                relationRepairs.forEach { repair -> add(InputIdentity.Value(repair.occurrence.location)) }
                add(InputIdentity.Catalog(root.catalog.generation))
            }.toMutableSet()
        val repairs =
            buildList {
                add(EditIntent.ConfigureResource(resource, requested))
                addAll(nestedRetags)
                cleared
                    .distinct()
                    .filterNot(relationRepairLocations::contains)
                    .forEach { add(EditIntent.SetValue(it, DataValue.UNFILLED)) }
            }
        val plannedIntents =
            buildList {
                addAll(repairs)
                relationRepairs.forEach { repair -> add(EditIntent.DisconnectRelation(repair.occurrence)) }
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
                resource = resource.toSkir(),
                next = requested,
                edit = PreparedEdit(root.catalog.generation, observed, plannedIntents).encoded(),
                linkRepairs = relationRepairs,
                clearedLocations =
                    (cleared + relationRepairLocations).distinct(),
            ),
        )
    }

    override suspend fun prepare(preview: TypeArgumentChangePreview): PreparedEditResult {
        val resource = preview.resource.toResourceId()
        val edit = preview.edit.decoded()
        val rootLocation = ValueLocation.of(resource)
        if (!preview.hasCoherentMetadata(resource, edit)) {
            return PreparedEditResult.Rejected(listOf(ValueProblem(location = rootLocation, code = "type_argument_preview_mismatch")))
        }
        return views.capture().use { snapshot ->
            if (snapshot.root.catalog.generation != edit.catalog) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(location = rootLocation, code = "catalog_changed")))
            }
            val conflicts = snapshot.root.values.conflicts(edit.expectations)
            if (conflicts.isNotEmpty()) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(location = rootLocation, code = "expectation_conflict")))
            }
            val verified =
                when (val regenerated = preview(resource, preview.next, snapshot)) {
                    is TypePreviewResult.Ready -> {
                        regenerated.preview
                    }

                    is TypePreviewResult.Rejected -> {
                        return PreparedEditResult.Rejected(regenerated.problems)
                    }

                    else -> {
                        return PreparedEditResult.Rejected(
                            listOf(ValueProblem(location = rootLocation, code = "type_argument_preview_no_longer_valid")),
                        )
                    }
                }
            if (!verified.sameRepairs(preview)) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(location = rootLocation, code = "type_argument_preview_mismatch")))
            }
            val verifiedEdit = verified.edit.decoded()
            if (edit.expectations.any { expected -> verifiedEdit.expectations.none { it.sameFact(expected) } } ||
                verifiedEdit.expectations.any { expected -> edit.expectations.none { it.sameFact(expected) } }
            ) {
                return PreparedEditResult.Rejected(listOf(ValueProblem(location = rootLocation, code = "type_argument_preview_mismatch")))
            }
            PreparedEditResult.Prepared(verifiedEdit)
        }
    }

    private fun TypeArgumentChangePreview.sameRepairs(other: TypeArgumentChangePreview): Boolean =
        resource == other.resource &&
            next == other.next &&
            edit.intents == other.edit.intents &&
            linkRepairs == other.linkRepairs &&
            clearedLocations == other.clearedLocations

    private fun TypeArgumentChangePreview.hasCoherentMetadata(
        resource: ResourceId,
        edit: PreparedEdit,
    ): Boolean {
        val configuration = edit.intents.filterIsInstance<EditIntent.ConfigureResource>()
        if (configuration != listOf(EditIntent.ConfigureResource(resource, next))) return false
        val cleared =
            (
                edit.intents
                    .filterIsInstance<EditIntent.SetValue>()
                    .filter { it.value == DataValue.UNFILLED }
                    .map { it.at } +
                    linkRepairs.map { it.occurrence.location }
            ).distinct()
        return clearedLocations == cleared
    }
}

/** The Skir form of a prepared edit, which previews carry, until prepared edits are Skir values. */
private fun PreparedEdit.encoded(): SkirPreparedEdit = SkirAuthoringOperationCodec.encode(this).getOrThrow()

/** Reads the edit of a preview, checking it as every other operation decoding does, until prepared edits are Skir values. */
private fun SkirPreparedEdit.decoded(): PreparedEdit = SkirAuthoringOperationCodec.decode(this).getOrThrow()

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
    if (value == DataValue.UNFILLED) return
    if (value == DataValue.NULL) {
        if (next !is TypeUse.NullableWrapper) repairs += at
        return
    }

    val expected = if (next is TypeUse.NullableWrapper) next.value.value else next
    val declaredActual = if (old is TypeUse.NullableWrapper) old.value.value else old
    val actual = (value as? DataValue.NamedWrapper)?.actualType?.use ?: declaredActual
    if (catalog.isReadableAs(actual, next)) return

    val namedValue = value as? DataValue.NamedWrapper
    val actualNamed = actual as? TypeUse.NamedWrapper
    val expectedNamed = expected as? TypeUse.NamedWrapper
    val canRetag =
        namedValue != null &&
            actualNamed != null &&
            expectedNamed != null &&
            actualNamed.value.definition == expectedNamed.value.definition
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
    retags += EditIntent.Retag(at, expectedType.value)
    val payload = requireNotNull(namedValue).payload
    when {
        payload is DataValue.RecordWrapper && oldRepresentation is ResolvedRepresentation.RecordWrapper &&
            newRepresentation is ResolvedRepresentation.RecordWrapper -> {
            val oldFields = oldRepresentation.value.fields.associateBy { it.key }
            newRepresentation.value.fields.forEach { field ->
                val child = payload.field(field.key)
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

        payload is DataValue.ListValueWrapper && oldRepresentation is ResolvedRepresentation.SequenceWrapper &&
            newRepresentation is ResolvedRepresentation.SequenceWrapper -> {
            inspected += InputIdentity.Membership(at)
            inspected += InputIdentity.Order(at)
            payload.items.forEach { item ->
                collectRepairs(
                    item.value,
                    oldRepresentation.value.item,
                    newRepresentation.value.item,
                    at.item(item.id),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
            }
        }

        payload is DataValue.SetValueWrapper && oldRepresentation is ResolvedRepresentation.SequenceWrapper &&
            newRepresentation is ResolvedRepresentation.SequenceWrapper -> {
            inspected += InputIdentity.Membership(at)
            payload.items.forEach { item ->
                collectRepairs(
                    item.value,
                    oldRepresentation.value.item,
                    newRepresentation.value.item,
                    at.item(item.id),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
            }
        }

        payload is DataValue.MapValueWrapper && oldRepresentation is ResolvedRepresentation.MappingWrapper &&
            newRepresentation is ResolvedRepresentation.MappingWrapper -> {
            inspected += InputIdentity.Membership(at)
            inspected += InputIdentity.Order(at)
            payload.rows.forEach { row ->
                collectRepairs(
                    row.key,
                    oldRepresentation.value.key,
                    newRepresentation.value.key,
                    at.item(row.id).mapKey(),
                    catalog,
                    repairs,
                    retags,
                    inspected,
                )
                collectRepairs(
                    row.value,
                    oldRepresentation.value.value,
                    newRepresentation.value.value,
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
    resources: Map<ResourceId, AuthoringRecord>,
    occurrences: Collection<LinkOccurrence>,
    contracts: List<RelationContract>,
    catalog: CheckedCatalog,
    inspected: MutableSet<InputIdentity>,
): List<LinkRepairIntent> {
    val endpointContracts =
        contracts.flatMap { contract -> listOf(contract.first.id to contract, contract.second.id to contract) }.toMap()
    return occurrences
        .mapNotNull { occurrence ->
            if (occurrence.source.toResourceId() != resource &&
                occurrence.target.resource.toResourceId() != resource
            ) {
                return@mapNotNull null
            }
            val sourceRecord = resources[occurrence.source.toResourceId()]
            val targetRecord = resources[occurrence.target.resource.toResourceId()]
            inspected += InputIdentity.Form(ValueLocation(resource = occurrence.source, path = ValuePath.root))
            inspected += InputIdentity.Value(occurrence.id.location)
            inspected += InputIdentity.Form(ValueLocation(resource = occurrence.target.resource, path = ValuePath.root))
            val contract = endpointContracts[occurrence.id.endpoint] ?: return@mapNotNull LinkRepairIntent.ClearWrapper(occurrence.id)
            val sourceEndpoint = if (contract.first.id == occurrence.id.endpoint) contract.first else contract.second
            val targetEndpoint = if (sourceEndpoint.slot == EndpointSlot.First) contract.second else contract.first
            inspected += InputIdentity.Incoming(resource, contract.id)
            val proposedSource = sourceRecord?.proposedIf(occurrence.source.toResourceId() == resource, requested)
            val proposedTarget = targetRecord?.proposedIf(occurrence.target.resource.toResourceId() == resource, requested)
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
                    .lastOrNull() is PathSegment.ItemWrapper
            ) {
                LinkRepairIntent.RemoveWrapper(occurrence.id)
            } else {
                LinkRepairIntent.ClearWrapper(occurrence.id)
            }
        }.distinct()
}

private fun AuthoringRecord.proposedIf(
    proposed: Boolean,
    requested: TypeSelection,
): AuthoringRecord = if (proposed) copy(configuration = requested) else this

private fun AuthoringRecord.matches(
    expected: TypeUse,
    catalog: CheckedCatalog,
): Boolean =
    when (val selected = configuration) {
        is TypeSelection.CompleteWrapper -> catalog.isReadableAs(selected.use.use, expected)
        is TypeSelection.PendingWrapper -> catalog.knownApplications(selected).any { catalog.isReadableAs(it.use, expected) }
        else -> unknownVariant(selected)
    }

private fun AuthoringRecord.matches(
    expected: NamedTypeTemplate,
    catalog: CheckedCatalog,
): Boolean {
    val concrete = expected.template.concreteUseOrNull()
    if (concrete != null) return matches(concrete, catalog)
    return catalog.isNominalSubtype(configuration.definition, expected.definition)
}

/** The occurrence a repair clears or removes. */
private val LinkRepairIntent.occurrence: LinkOccurrenceId
    get() =
        when (this) {
            is LinkRepairIntent.ClearWrapper -> value
            is LinkRepairIntent.RemoveWrapper -> value
            else -> unknownVariant(this)
        }

private fun TypeTemplate.concreteUseOrNull(): TypeUse? {
    return when (this) {
        is TypeTemplate.ParameterWrapper -> null
        is TypeTemplate.NamedWrapper -> value.definition.use(value.arguments.map { it.concreteUseOrNull() ?: return null })
        is TypeTemplate.NullableWrapper -> value.value.concreteUseOrNull()?.nullable()
        is TypeTemplate.ScalarWrapper -> value.use
        else -> unknownVariant(this)
    }
}
