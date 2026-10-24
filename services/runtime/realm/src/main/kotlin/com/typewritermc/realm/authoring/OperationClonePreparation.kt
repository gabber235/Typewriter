package com.typewritermc.realm.authoring

import com.typewritermc.authoring.field
import com.typewritermc.authoring.id
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.authoring.name
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.root
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.actualType
import com.typewritermc.types.endpoint
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.payload
import com.typewritermc.types.record
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.unknownVariant
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/** Copies the ownership closure before reconnecting any of its references. */
internal class OperationClonePreparation(
    private val reads: RelationReads,
    private val relations: OperationRelationPreparation,
    private val layouts: OperationLayoutPreparation,
) {
    private val catalog get() = reads.catalog
    private val capturedReads get() = reads.reads

    /** Copies the ownership closures of [roots] under their current owners and returns the copied roots in order. */
    context(operation: OperationPreparation)
    suspend fun duplicateOwned(roots: List<ResourceId>): List<ResourceId> {
        require(roots.isNotEmpty() && roots.distinct().size == roots.size)
        val resources = reads.resources
        val occurrences = reads.links.values.toList()
        val projection = ResourceValueMapper.project(occurrences, resources, catalog.relations, catalog.checked)
        require(projection.problems.isEmpty()) { "Repair the selected relations before duplicating resources." }
        val owning = catalog.ownershipRelationIds
        val ownership = projection.projections.filter { it.contract in owning }
        val closure = linkedSetOf<ResourceId>()
        val pending = ArrayDeque(roots)
        while (pending.isNotEmpty()) {
            val resource = pending.removeFirst()
            if (!closure.add(resource)) continue
            require(resource in resources) { "A selected resource no longer exists." }
            capturedReads.observeInput(InputIdentity.Existence(resource))
            capturedReads.observeInput(InputIdentity.Form(ValueLocation.of(resource)))
            capturedReads.observeInput(InputIdentity.Value(ValueLocation.of(resource)))
            capturedReads.observeInput(InputIdentity.Incoming(resource, null))
            ownership.filter { it.first == resource }.forEach { pending += it.second }
        }
        val copies = closure.associateWith { operation.identities.resource("clone:${it.value.length}:${it.value}").toSkir() }
        require(copies.values.none { it in resources }) { "A copy identity already exists. Start a new operation." }
        val locations = linkedMapOf<ValueLocation, ValueLocation>()
        val contracts =
            catalog.relations
                .flatMap { listOf(it.first.id to it, it.second.id to it) }
                .toMap()

        fun retained(link: DataValue.LinkWrapper): Boolean {
            val contract = requireNotNull(contracts[link.endpoint])
            return link.value.target.resource in closure || contract.id in owning || link.endpoint == contract.first.id
        }

        fun directLink(value: DataValue): DataValue.LinkWrapper? =
            when (value) {
                is DataValue.LinkWrapper -> value
                is DataValue.NamedWrapper -> directLink(value.payload)
                else -> null
            }

        fun copyValue(
            value: DataValue,
            from: ValueLocation,
            to: ValueLocation,
        ): DataValue {
            locations[from] = to
            return when (value) {
                is DataValue.LinkWrapper -> {
                    DataValue.UNFILLED
                }

                is DataValue.NamedWrapper -> {
                    DataValue.named(value.actualType, copyValue(value.payload, from, to))
                }

                is DataValue.RecordWrapper -> {
                    DataValue.record(
                        value.fields.associate { field ->
                            field.name to
                                copyValue(field.value, from.field(field.name), to.field(field.name))
                        },
                    )
                }

                is DataValue.ListValueWrapper -> {
                    DataValue.listValue(
                        value.items.mapNotNull { item ->
                            if (directLink(item.value)?.let { !retained(it) } == true) return@mapNotNull null
                            val id = operation.identities.item("clone:${from.identityKey()}:${item.id.value.length}:${item.id.value}")
                            ListItem(id = id, value = copyValue(item.value, from.item(item.id), to.item(id)))
                        },
                    )
                }

                is DataValue.SetValueWrapper -> {
                    DataValue.setValue(
                        value.items.mapNotNull { item ->
                            if (directLink(item.value)?.let { !retained(it) } == true) return@mapNotNull null
                            val id = operation.identities.item("clone:${from.identityKey()}:${item.id.value.length}:${item.id.value}")
                            ListItem(id = id, value = copyValue(item.value, from.item(item.id), to.item(id)))
                        },
                    )
                }

                is DataValue.MapValueWrapper -> {
                    DataValue.mapValue(
                        value.rows.mapNotNull { row ->
                            if (listOf(row.key, row.value).any {
                                    directLink(it)?.let { link ->
                                        !retained(link)
                                    } == true
                                }
                            ) {
                                return@mapNotNull null
                            }
                            val id = operation.identities.item("clone:${from.identityKey()}:${row.id.value.length}:${row.id.value}")
                            MapRow(
                                id = id,
                                key = copyValue(row.key, from.item(row.id).mapKey(), to.item(id).mapKey()),
                                value = copyValue(row.value, from.item(row.id).mapValue(), to.item(id).mapValue()),
                            )
                        },
                    )
                }

                else -> {
                    value
                }
            }
        }
        val records =
            closure.associate { original ->
                val record = resources.getValue(original)
                val fields =
                    copyValue(
                        DataValue.RecordWrapper(record.payload),
                        ValueLocation.of(original),
                        ValueLocation.of(copies.getValue(original)),
                    ) as DataValue.RecordWrapper
                copies.getValue(original) to record.copy(fields = fields.value.fields)
            }
        records.forEach { (id, record) -> operation.create(id.toResourceId(), record) }

        val connected = hashSetOf<LinkOccurrenceId>()
        for (old in occurrences.filter { it.source in closure }) {
            if (old.id in connected) continue
            if (!retained(DataValue.createLink(endpoint = old.id.endpoint, target = old.target))) continue
            val sourceLocation = locations.getValue(old.id.location)
            val target = copies[old.target.resource] ?: old.target.resource
            val oldOpposite = old.target.opposite?.let { ValueLocation(resource = old.target.resource, path = it) }
            val oppositeLocation = oldOpposite?.takeIf { it.resource in closure }?.let(locations::getValue)
            val source =
                LinkOccurrence(
                    id = LinkOccurrenceId(endpoint = old.id.endpoint, location = sourceLocation),
                    source = sourceLocation.resource,
                    target = LinkTarget(resource = target, opposite = oppositeLocation?.path),
                )
            val counterpart =
                if (oppositeLocation != null) {
                    val contract = contracts.getValue(old.id.endpoint)
                    val endpoint = if (contract.first.id == old.id.endpoint) contract.second.id else contract.first.id
                    connected += LinkOccurrenceId(endpoint = endpoint, location = requireNotNull(oldOpposite))
                    CounterpartChoice.ExistingWrapper(
                        LinkOccurrence(
                            id = LinkOccurrenceId(endpoint = endpoint, location = oppositeLocation),
                            source = target,
                            target = LinkTarget(resource = source.source, opposite = sourceLocation.path),
                        ),
                    )
                } else {
                    relations.counterpartFor(source, target, operation.choices)
                }
            operation.connect(ConnectIntent(source = source, target = target, counterpart = counterpart))
            connected += old.id
        }

        // Ownership can be authored only on the external owner, with no inverse field on a copied root.
        ownership.filter { it.second in closure && it.first !in closure && it.secondLocation == null }.forEach { edge ->
            val oldPath = requireNotNull(edge.firstLocation)
            require(oldPath.segments.lastOrNull() is PathSegment.ItemWrapper) {
                "The external owner cannot hold an additional copy in its scalar ownership field."
            }
            val parent = ValuePath(segments = oldPath.segments.dropLast(1))
            val fresh = operation.identities.item("clone-owner:${ValueLocation.of(edge.first, oldPath).identityKey()}")
            val at = ValueLocation.of(edge.first, parent.item(fresh))
            val endpoint =
                catalog.relations
                    .single { it.id == edge.contract }
                    .first.id
            val target = copies.getValue(edge.second)
            operation.connect(
                ConnectIntent(
                    source =
                        LinkOccurrence(
                            id = LinkOccurrenceId(endpoint = endpoint, location = at),
                            source = edge.first,
                            target = LinkTarget(resource = target, opposite = null),
                        ),
                    target = target,
                    counterpart = null,
                ),
            )
        }

        // Copied roots join their originals' owners, whose layout places them. Only the realm root has no owner, and it
        // is never duplicated, so a root without one has no layout to join.
        val outerRoots = closure.filter { resource -> ownership.none { it.second == resource && it.first in closure } }
        outerRoots
            .groupBy { resource -> ownership.singleOrNull { it.second == resource }?.first }
            .forEach { (owner, originals) ->
                if (owner != null) with(layouts) { originals.map(copies::getValue).placeIn(owner, null) }
            }
        return roots.map(copies::getValue)
    }
}

private fun ValueLocation.identityKey(): String =
    "${resource.value.length}:${resource.value}" +
        path.segments.joinToString("") { segment ->
            when (segment) {
                is PathSegment.FieldWrapper -> "f${segment.name.length}:${segment.name}"
                is PathSegment.ItemWrapper -> "i${segment.id.value.length}:${segment.id.value}"
                PathSegment.MAP_KEY -> "k"
                PathSegment.MAP_VALUE -> "v"
                else -> unknownVariant(segment)
            }
        }
