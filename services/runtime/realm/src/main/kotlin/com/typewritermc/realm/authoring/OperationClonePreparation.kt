package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.mapKey
import com.typewritermc.authoring.mapValue
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.DataValue
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ResourceId

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
            capturedReads.observeInput(InputIdentity.Form(ValueLocation(resource, ValuePath())))
            capturedReads.observeInput(InputIdentity.Value(ValueLocation(resource, ValuePath())))
            capturedReads.observeInput(InputIdentity.Incoming(resource, null))
            ownership.filter { it.first == resource }.forEach { pending += it.second }
        }
        val copies = closure.associateWith { operation.identities.resource("clone:${it.value.length}:${it.value}") }
        require(copies.values.none { it in resources }) { "A copy identity already exists. Start a new operation." }
        val locations = linkedMapOf<ValueLocation, ValueLocation>()
        val contracts =
            catalog.relations
                .flatMap { listOf(it.first.id to it, it.second.id to it) }
                .toMap()

        fun retained(link: DataValue.Link): Boolean {
            val contract = requireNotNull(contracts[link.endpoint])
            return link.target.resource in closure || contract.id in owning || link.endpoint == contract.first.id
        }

        fun directLink(value: DataValue): DataValue.Link? =
            when (value) {
                is DataValue.Link -> value
                is DataValue.Named -> directLink(value.payload)
                else -> null
            }

        fun copyValue(
            value: DataValue,
            from: ValueLocation,
            to: ValueLocation,
        ): DataValue {
            locations[from] = to
            return when (value) {
                is DataValue.Link -> {
                    DataValue.Unfilled
                }

                is DataValue.Named -> {
                    value.copy(payload = copyValue(value.payload, from, to))
                }

                is DataValue.Record -> {
                    value.copy(fields = value.fields.mapValues { (key, child) -> copyValue(child, from.field(key), to.field(key)) })
                }

                is DataValue.ListValue -> {
                    value.copy(
                        items =
                            value.items.mapNotNull { item ->
                                if (directLink(item.value)?.let { !retained(it) } == true) return@mapNotNull null
                                val id = operation.identities.item("clone:${from.identityKey()}:${item.id.value.length}:${item.id.value}")
                                ListItem(id, copyValue(item.value, from.item(item.id), to.item(id)))
                            },
                    )
                }

                is DataValue.SetValue -> {
                    value.copy(
                        items =
                            value.items.mapNotNull { item ->
                                if (directLink(item.value)?.let { !retained(it) } == true) return@mapNotNull null
                                val id = operation.identities.item("clone:${from.identityKey()}:${item.id.value.length}:${item.id.value}")
                                ListItem(id, copyValue(item.value, from.item(item.id), to.item(id)))
                            },
                    )
                }

                is DataValue.MapValue -> {
                    value.copy(
                        rows =
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
                                    id,
                                    copyValue(row.key, from.item(row.id).mapKey(), to.item(id).mapKey()),
                                    copyValue(row.value, from.item(row.id).mapValue(), to.item(id).mapValue()),
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
                        DataValue.Record(record.fields),
                        ValueLocation(original, ValuePath()),
                        ValueLocation(copies.getValue(original), ValuePath()),
                    ) as DataValue.Record
                copies.getValue(original) to record.copy(fields = fields.fields)
            }
        records.forEach { (id, record) -> operation.create(id, record) }

        val connected = hashSetOf<LinkOccurrenceId>()
        for (old in occurrences.filter { it.source in closure }) {
            if (old.id in connected) continue
            if (!retained(DataValue.Link(old.id.endpoint, old.target))) continue
            val sourceLocation = locations.getValue(old.id.location)
            val target = copies[old.target.resource] ?: old.target.resource
            val oldOpposite = old.target.opposite?.let { ValueLocation(old.target.resource, it) }
            val oppositeLocation = oldOpposite?.takeIf { it.resource in closure }?.let(locations::getValue)
            val source =
                LinkOccurrence(
                    LinkOccurrenceId(old.id.endpoint, sourceLocation),
                    sourceLocation.resource,
                    LinkTarget(target, oppositeLocation?.path),
                )
            val counterpart =
                if (oppositeLocation != null) {
                    val contract = contracts.getValue(old.id.endpoint)
                    val endpoint = if (contract.first.id == old.id.endpoint) contract.second.id else contract.first.id
                    connected += LinkOccurrenceId(endpoint, requireNotNull(oldOpposite))
                    CounterpartChoice.Existing(
                        LinkOccurrence(
                            LinkOccurrenceId(endpoint, oppositeLocation),
                            target,
                            LinkTarget(source.source, sourceLocation.path),
                        ),
                    )
                } else {
                    relations.counterpartFor(source, target, operation.choices)
                }
            operation.connect(ConnectIntent(source, target, counterpart))
            connected += old.id
        }

        // Ownership can be authored only on the external owner, with no inverse field on a copied root.
        ownership.filter { it.second in closure && it.first !in closure && it.secondLocation == null }.forEach { edge ->
            val oldPath = requireNotNull(edge.firstLocation)
            require(oldPath.segments.lastOrNull() is PathSegment.Item) {
                "The external owner cannot hold an additional copy in its scalar ownership field."
            }
            val parent = ValuePath(oldPath.segments.dropLast(1))
            val fresh = operation.identities.item("clone-owner:${ValueLocation(edge.first, oldPath).identityKey()}")
            val at = ValueLocation(edge.first, parent.item(fresh))
            val endpoint =
                catalog.relations
                    .single { it.id == edge.contract }
                    .first.id
            val target = copies.getValue(edge.second)
            operation.connect(
                ConnectIntent(LinkOccurrence(LinkOccurrenceId(endpoint, at), edge.first, LinkTarget(target, null)), target, null),
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
                is PathSegment.Field -> "f${segment.name.length}:${segment.name}"
                is PathSegment.Item -> "i${segment.id.value.length}:${segment.id.value}"
                PathSegment.MapKey -> "k"
                PathSegment.MapValue -> "v"
            }
        }
