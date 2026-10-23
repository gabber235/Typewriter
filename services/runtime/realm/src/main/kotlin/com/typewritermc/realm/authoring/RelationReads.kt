package com.typewritermc.realm.authoring

import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.use
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.CounterpartBinding
import com.typewritermc.realm.repository.DeclaredLinkEvidence
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.endpoint
import com.typewritermc.types.isAcyclic
import com.typewritermc.types.ownsResources
import com.typewritermc.types.payload
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * Reads relation bindings, ownership and endpoint compatibility over one captured working graph.
 *
 * The graph is the view behind [reads], so staged edits are visible as soon as they are written. Every read that
 * decides an answer is recorded on [reads], so a preview built from these answers is rejected when they change.
 */
internal class RelationReads(
    val reads: CapturedAuthoringReads,
) {
    val catalog: AuthoringCatalogLease get() = reads.view.original.catalog
    val resources: Map<ResourceId, AuthoringRecord> get() = reads.view.resources
    val links: Map<LinkOccurrenceId, LinkOccurrence> get() = reads.view.links

    /** Changes whenever a staged write replaces the graph; saved and staged views never change. */
    val revision: Long get() = (reads.view as? AuthoredReadView.Working)?.revision ?: 0L

    private var projected: Pair<Long, List<LinkProjection>>? = null

    /** Relation projections of the current graph, recomputed only after a staged write replaces it. */
    val projections: List<LinkProjection>
        get() {
            val revision = revision
            projected?.let { (at, projections) -> if (at == revision) return projections }
            val view = reads.view
            val projections =
                if (view.resources === view.original.resources) {
                    view.original.projection.projections
                } else {
                    ResourceValueMapper.project(links.values, resources, catalog.relations, catalog.checked).projections
                }
            projected = revision to projections
            return projections
        }

    fun contract(endpoint: EndpointId): RelationContract = catalog.relations.single { it.first.id == endpoint || it.second.id == endpoint }

    fun recordOf(id: ResourceId): AuthoringRecord = resources[id] ?: error("The linked resource is unavailable")

    /** Records that the existence and type of [id] were read. */
    fun observeForm(id: ResourceId) {
        reads.observeInput(InputIdentity.Existence(id))
        reads.observeInput(InputIdentity.Form(ValueLocation.of(id)))
    }

    fun observe(source: LinkOccurrence) {
        reads.observeInput(InputIdentity.Value(source.id.location))
        reads.observeInput(InputIdentity.Incoming(source.source, null))
        reads.observeInput(InputIdentity.Incoming(source.target.resource, null))
    }

    /** Bindings this resource declares for [endpoint]; the evidence is recorded as read before anyone inspects it. */
    fun ResourceId.bindingEvidence(endpoint: EndpointId): DeclaredLinkEvidence =
        ResourceValueMapper.declaredEvidence(endpoint, this, recordOf(this), catalog.checked).also { evidence ->
            evidence.memberships.forEach { reads.observeInput(InputIdentity.Membership(it)) }
            evidence.forms.forEach { reads.observeInput(InputIdentity.Form(it)) }
        }

    /**
     * The occurrence through which the current owner holds [subject], authored on the owner side. A captured origin
     * occurrence of an ownership relation wins, so a drag from one of several memberships moves that one.
     */
    fun ownership(
        subject: ResourceId,
        origin: OperationOrigin = OperationOrigin(),
    ): LinkOccurrence? {
        reads.observeInput(InputIdentity.Incoming(subject, null))
        val membership =
            origin.occurrences.singleOrNull { it.target.resource == subject && it.holdsOwnership() }
                ?: links.values.singleOrNull { it.target.resource == subject && it.holdsOwnership() }
                ?: return null
        require(links[membership.id] == membership) { "The source ownership changed" }
        observe(membership)
        return membership
    }

    /** Whether this occurrence is the owner side of an ownership relation. */
    private fun LinkOccurrence.holdsOwnership(): Boolean {
        val relation = contract(id.endpoint)
        return relation.ownsResources && id.endpoint == relation.first.id
    }

    /** The occurrence on [subject]'s inverse field that points at an owner of [membership]'s relation, if it has one. */
    fun memberSource(
        subject: ResourceId,
        membership: LinkOccurrence,
    ): LinkOccurrence? {
        val inverse = membership.target.opposite ?: return null
        val relation = contract(membership.id.endpoint)
        val endpoint = if (relation.first.id == membership.id.endpoint) relation.second.id else relation.first.id
        return LinkOccurrence(
            id = LinkOccurrenceId(endpoint = endpoint, location = ValueLocation.of(subject, inverse)),
            source = subject,
            target = LinkTarget(resource = membership.source, opposite = membership.id.location.path),
        )
    }

    /**
     * Occurrences that would make [owner] hold [subject] through [membership]'s ownership relation. A subject with an
     * inverse field links from that field; a subject without one, such as a keyframe in a segment, is held only by the
     * owner's own binding, so the owner's slots that already hold it or have room for it are offered instead.
     * [item] names a new collection item.
     */
    fun ownerSources(
        subject: ResourceId,
        membership: LinkOccurrence,
        owner: ResourceId,
        item: (String) -> ItemId,
    ): List<LinkOccurrence> {
        memberSource(subject, membership)?.let { source -> return listOfNotNull(source.takeIf { accepts(it, owner) }) }
        val endpoint = membership.id.endpoint
        val evidence = owner.bindingEvidence(endpoint)
        return if (evidence.isEmpty()) emptyList() else owner.occurrencesLinking(subject, endpoint, evidence, item)
    }

    /** Whether [target] has a type the binding of [source] accepts. */
    fun accepts(
        source: LinkOccurrence,
        target: ResourceId,
    ): Boolean {
        val sourceRecord = resources[source.source] ?: return false
        val destination = resources[target] ?: return false
        val actual = (destination.configuration as? TypeSelection.CompleteWrapper)?.use ?: return false
        val expected =
            ResourceValueMapper.expectedTarget(source, sourceRecord, catalog.checked) ?: run {
                val type = sourceRecord.authoredTypeAt(source.id.location.path, catalog.checked) ?: return false
                val checked = catalog.checked.resolve(type) as? Resolution.Ready ?: return false
                (checked.value.schema.representation as? ResolvedRepresentation.LinkWrapper)?.value?.target ?: return false
            }
        return catalog.checked.isReadableAs(actual.use, expected)
    }

    /**
     * Link occurrences that would connect [subject] and [target] through each non owning relation, the dragged side
     * first. Bindings live at each relation's first endpoint, so the subject holds the link when it declares a binding
     * for the relation and the target holds it only otherwise: a tag dropped onto a book is written to the book's tags
     * while a tag dropped onto a tag gains the target as a parent. [item] names a new collection item.
     */
    fun linkSources(
        subject: ResourceId,
        target: ResourceId,
        item: (String) -> ItemId,
    ): List<LinkOccurrence> =
        catalog.relations
            .filterNot { it.ownsResources }
            .flatMap { relation ->
                val endpoint = relation.first.id
                listOf(subject to target, target to subject).firstNotNullOfOrNull { (holder, linked) ->
                    val evidence = holder.bindingEvidence(endpoint)
                    when {
                        evidence.isEmpty() -> null
                        relation.isAcyclic && linked.reaches(holder, relation) -> emptyList()
                        else -> holder.occurrencesLinking(linked, endpoint, evidence, item)
                    }
                } ?: emptyList()
            }.distinctBy { it.id }

    /**
     * Whether following [relation] from this resource, first to second endpoint, arrives at [other]. A link from
     * [other] to this resource would then close a cycle.
     */
    private fun ResourceId.reaches(
        other: ResourceId,
        relation: RelationContract,
    ): Boolean {
        val next = projections.filter { it.contract == relation.id }.groupBy({ it.first }, { it.second })
        val visited = hashSetOf<ResourceId>()
        val pending = ArrayDeque(listOf(this))
        while (pending.isNotEmpty()) {
            val id = pending.removeFirst()
            if (!visited.add(id)) continue
            reads.observeInput(InputIdentity.Value(ValueLocation.of(id)))
            reads.observeInput(InputIdentity.Incoming(id, null))
            if (id == other) return true
            next[id].orEmpty().forEach(pending::add)
        }
        return false
    }

    /** Occurrences on this resource's [endpoint] bindings that already link [linked] or have room to link it. */
    private fun ResourceId.occurrencesLinking(
        linked: ResourceId,
        endpoint: EndpointId,
        evidence: DeclaredLinkEvidence,
        item: (String) -> ItemId,
    ): List<LinkOccurrence> {
        val record = recordOf(this)
        val locations = evidence.values.toMutableList()
        val collection = ResourceValueMapper.counterpartBinding(endpoint, this, record, catalog.checked) as? CounterpartBinding.Collection
        if (collection != null &&
            locations.none { links[LinkOccurrenceId(endpoint = endpoint, location = it)]?.target?.resource == linked }
        ) {
            locations += collection.location.item(item("source:$value:${endpoint.value}:${linked.value}"))
        }
        return locations.mapNotNull { at ->
            reads.observeInput(InputIdentity.Value(at))
            val present = links[LinkOccurrenceId(endpoint = endpoint, location = at)]
            val value = record.valueAt(at.path)
            if (present != null && present.target.resource != linked) return@mapNotNull null
            if (present == null && value != null && !value.unfilled()) return@mapNotNull null
            val occurrence =
                present
                    ?: LinkOccurrence(
                        id = LinkOccurrenceId(endpoint = endpoint, location = at),
                        source = this,
                        target = LinkTarget(resource = linked, opposite = null),
                    )
            occurrence.takeIf { accepts(it, linked) }
        }
    }

    /** Non owning link occurrences between [id] and [target], whichever of them holds each. */
    fun linksBetween(
        id: ResourceId,
        target: ResourceId,
    ): List<LinkOccurrence> = linksOf(id).filter { it.source == target || it.target.resource == target }

    /** Non owning link occurrences held by [id] or pointing at it. */
    fun linksOf(id: ResourceId): List<LinkOccurrence> {
        reads.observeInput(InputIdentity.Value(ValueLocation.of(id)))
        reads.observeInput(InputIdentity.Incoming(id, null))
        return links.values.filter { occurrence ->
            (occurrence.source == id || occurrence.target.resource == id) &&
                !contract(occurrence.id.endpoint).ownsResources
        }
    }
}

private fun DeclaredLinkEvidence.isEmpty(): Boolean = values.isEmpty() && memberships.isEmpty() && forms.isEmpty()

internal fun DataValue.unfilled(): Boolean =
    when (this) {
        DataValue.UNFILLED, DataValue.NULL -> true
        is DataValue.NamedWrapper -> payload.unfilled()
        else -> false
    }
