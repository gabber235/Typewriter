package com.typewritermc.realm.authoring

import com.typewritermc.authoring.GraphEndpoint
import com.typewritermc.authoring.GraphStep
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.of
import com.typewritermc.authoring.use
import com.typewritermc.checking.InputIdentity
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** One resource's stored links: no catalog, so it changes only when a record holding one of them changes. */
internal data class LinkSlice(
    /** The occurrences this resource holds. */
    val own: List<LinkOccurrence>,
    /** The occurrences whose target is this resource. */
    val into: List<LinkOccurrence>,
) {
    companion object {
        val EMPTY = LinkSlice(emptyList(), emptyList())
    }
}

/** Groups links by resource once. Every view kind calls it over its own links. */
internal fun Collection<LinkOccurrence>.slices(): Map<ResourceId, LinkSlice> {
    val own = groupBy { it.source }
    val into = groupBy { it.target.resource }
    return (own.keys + into.keys).associateWith { LinkSlice(own[it].orEmpty(), into[it].orEmpty()) }
}

/** What the catalog says about one slice. */
internal data class ResourceProjection(
    /** The links whose first or second is this resource, each once. */
    val projections: List<LinkProjection>,
    val own: List<LinkOccurrence>,
    val into: List<LinkOccurrence>,
    /** Hard problems at this resource's locations. */
    val problems: List<ValueProblem>,
    /** Links at this resource's locations that do not fit their holder's schema. */
    val fit: List<ValueProblem>,
)

/** Every judged slice folded together, as one realm wide projection. */
internal fun Collection<ResourceProjection>.fold(): ProjectionResult =
    ProjectionResult(
        projections = flatMapTo(linkedSetOf()) { it.projections }.sortedBy(::projectionKey),
        problems = flatMapTo(linkedSetOf()) { it.problems }.toList(),
        fit = flatMapTo(linkedSetOf()) { it.fit }.toList(),
    )

/**
 * Judges [resource]'s [slice] the way the realm wide projection judges it. A tracked reader records the catalog reads
 * by construction, and the record facts observed here are what the answer depends on: projecting reads of a link end
 * only its configuration, and of its holder the values on the paths of the occurrences it holds.
 */
internal fun CapturedAuthoringReads.judge(
    resource: ResourceId,
    slice: LinkSlice,
): ResourceProjection {
    val occurrences = (slice.own + slice.into).distinctBy { it.id }
    val ends = (listOf(resource) + slice.own.map { it.target.resource } + slice.into.map { it.source }).distinct()
    ends.forEach { end ->
        observeInput(InputIdentity.Existence(end))
        observeInput(InputIdentity.Form(ValueLocation.of(end)))
    }
    occurrences.forEach { occurrence ->
        observeInput(InputIdentity.Value(occurrence.id.location))
        // A link's slot follows the actual type of each union value above it, so each ancestor's form counts.
        occurrence.id.location
            .ancestors()
            .forEach { observeInput(InputIdentity.Form(it)) }
    }
    val known = ends.mapNotNull { id -> view.resources[id]?.let { id to it } }.toMap()
    val result = ResourceValueMapper.project(occurrences, known, viewCatalog.relations, typeCatalog)
    return ResourceProjection(
        projections = result.projections.filter { it.first == resource || it.second == resource }.distinct(),
        own = slice.own,
        into = slice.into,
        problems = result.problems.filter { it.location.resource == resource },
        fit = result.fit.filter { it.location.resource == resource },
    )
}

/** What a graph read needs at one node, in one selection. */
internal data class NodeLinks(
    /** The relations of the selection; a node observes its incoming links of each. */
    val contracts: List<RelationContract>,
    /** This resource's own occurrences in the selection, sorted by path. */
    val occurrences: List<LinkOccurrence>,
    val outgoing: List<DirectedEdge>,
    val incoming: List<DirectedEdge>,
    /** Problems at selected own occurrences whose target is available. */
    val problems: List<ValueProblem>,
    /** Own occurrences whose target is missing, pending or not ready. */
    val unavailable: List<LinkOccurrence>,
    /** Occurrences into this resource while it is unavailable. */
    val unavailableInto: List<LinkOccurrence>,
    /** Where this resource declares each selected endpoint, when it exists. */
    val declared: Map<EndpointId, DeclaredLinkEvidence>,
)

/**
 * The per node part of a graph read over [slice] and a selection. A tracked reader records the target and schema
 * reads, and the facts declared evidence rests on are observed, so a node's answer reruns with them.
 */
internal fun CapturedAuthoringReads.linksAt(
    resource: ResourceId,
    slice: ResourceProjection,
    selection: RelationSelection,
): NodeLinks {
    val contracts = selectedContracts(viewCatalog.relations, selection)
    val byId = contracts.associateBy(RelationContract::id)
    val endpoints = contracts.flatMapTo(linkedSetOf()) { listOf(it.first.id, it.second.id) }
    val own = slice.own.filter { it.id.endpoint in endpoints }
    val unavailable = own.filter { !isAvailable(it.target.resource) }
    val available = (own - unavailable.toSet()).mapTo(hashSetOf()) { it.id.location }
    val directed =
        slice.projections
            .filter { it.contract in byId }
            .flatMap { it.directed(byId.getValue(it.contract), direction(selection)) }
    observeInput(InputIdentity.Existence(resource))
    observeInput(InputIdentity.Form(ValueLocation.of(resource)))
    val record = view.resources[resource]
    val capabilities = LinkSchemaCapabilities(typeCatalog)
    val declared =
        record
            ?.let {
                endpoints.associateWith { endpoint ->
                    ResourceValueMapper.declaredEvidence(endpoint, resource, it, typeCatalog, capabilities)
                }
            }.orEmpty()
    declared.values.forEach { observeDeclared(it) }
    return NodeLinks(
        contracts = contracts,
        occurrences = own.sortedBy { ValuePath.serializer.toJsonCode(it.id.location.path) },
        outgoing = directed.filter { it.from == resource },
        incoming = directed.filter { it.to == resource },
        problems = slice.problems.filter { it.location in available },
        unavailable = unavailable,
        unavailableInto = if (isAvailable(resource)) emptyList() else slice.into.filter { it.id.endpoint in endpoints },
        declared = declared,
    )
}

/** Where a graph read reads a node: through the graph inside a query, from the view's own slices outside one. */
internal fun interface GraphLinks {
    fun at(
        resource: ResourceId,
        selection: RelationSelection,
    ): NodeLinks
}

/** The facts a declared evidence answer rests on. */
private fun CapturedAuthoringReads.observeDeclared(evidence: DeclaredLinkEvidence) {
    evidence.memberships.forEach { observeInput(InputIdentity.Membership(it)) }
    evidence.forms.forEach { observeInput(InputIdentity.Form(it)) }
    evidence.values.forEach { observeInput(InputIdentity.Value(it)) }
}

/** Whether a link to [resource] can be followed: it exists with a ready type. Reads its existence and form only. */
private fun CapturedAuthoringReads.isAvailable(resource: ResourceId): Boolean {
    observeInput(InputIdentity.Existence(resource))
    observeInput(InputIdentity.Form(ValueLocation.of(resource)))
    return when (val selected = view.resources[resource]?.configuration) {
        null, is TypeSelection.PendingWrapper -> false
        is TypeSelection.CompleteWrapper -> typeCatalog.resolve(selected.use.use) is Resolution.Ready
        else -> unknownVariant(selected)
    }
}

/** Every location strictly above this one in its resource, the resource root first. */
private fun ValueLocation.ancestors(): List<ValueLocation> =
    path.segments.indices.map { size -> ValueLocation(resource = resource, path = ValuePath(segments = path.segments.take(size))) }

internal data class DirectedEdge(
    val from: ResourceId,
    val to: ResourceId,
    val step: GraphStep,
)

private fun LinkProjection.directed(
    contract: RelationContract,
    direction: TraversalDirection,
): List<DirectedEdge> =
    buildList {
        if (direction != TraversalDirection.REVERSE) add(forward(contract))
        if (direction != TraversalDirection.FORWARD) add(reverse(contract))
    }

private fun LinkProjection.forward(contract: RelationContract): DirectedEdge =
    DirectedEdge(
        first,
        second,
        GraphStep(
            contract.id,
            GraphEndpoint(first.toResourceId(), contract.first.id, firstLocation),
            GraphEndpoint(second.toResourceId(), contract.second.id, secondLocation),
        ),
    )

private fun LinkProjection.reverse(contract: RelationContract): DirectedEdge =
    DirectedEdge(
        second,
        first,
        GraphStep(
            contract.id,
            GraphEndpoint(second.toResourceId(), contract.second.id, secondLocation),
            GraphEndpoint(first.toResourceId(), contract.first.id, firstLocation),
        ),
    )

internal fun selectedContracts(
    contracts: List<RelationContract>,
    selection: RelationSelection,
): List<RelationContract> =
    when (selection) {
        is RelationSelection.All -> contracts
        is RelationSelection.Contracts -> contracts.filter { it.id in selection.ids }
        is RelationSelection.Family -> contracts.filter { selection.id in it.families }
    }

private fun direction(selection: RelationSelection): TraversalDirection =
    when (selection) {
        is RelationSelection.All -> selection.direction
        is RelationSelection.Contracts -> selection.direction
        is RelationSelection.Family -> selection.direction
    }
