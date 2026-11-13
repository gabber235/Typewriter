package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GraphStep
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.LinkInspectionResult
import com.typewritermc.authoring.LocatedPortableValue
import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.ReachabilityResult
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.RouteResult
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.locate
import com.typewritermc.authoring.of
import com.typewritermc.authoring.payload
import com.typewritermc.authoring.record
import com.typewritermc.authoring.root
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.expression.operations.HostFailure
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResourceType
import com.typewritermc.types.endpoint
import com.typewritermc.types.record
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.expression.EvaluationDiagnostic
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** Traverses only the graph derived from the retained authored reads. */
internal object RealmGraphReads {
    context(reads: CapturedAuthoringReads)
    fun <D : ResourceDraft> reachable(query: ReachabilityQuery<D>): ReachabilityResult<D> {
        val graph = CapturedGraph(reads, query.links)
        val queue = ArrayDeque<Pair<ResourceId, Int>>()
        query.seeds
            .toSkir()
            .sortedBy(ResourceId::value)
            .forEach { queue += it to 0 }
        val visited = linkedSetOf<ResourceId>()
        val resources = mutableListOf<D>()
        val undecided = mutableListOf<UndecidedCandidate>()
        var links = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        while (queue.isNotEmpty()) {
            val (resource, depth) = queue.removeFirst()
            if (!visited.add(resource)) continue
            if (visited.size > query.budget.maxResources) {
                completion = interrupted(reads, "resource budget exceeded")
                break
            }
            when (val bound = graph.bind(resource, query.type)) {
                is BoundMatch.Match -> resources += bound.value
                is BoundMatch.Undecided -> undecided += bound.value
                BoundMatch.No -> Unit
            }
            graph.observeAt(resource)
            val maxDepth = query.maxDepth
            if (maxDepth != null && depth >= maxDepth) continue
            for (edge in graph.edgesFrom(resource)) {
                if (++links > query.budget.maxLinks) {
                    completion = interrupted(reads, "link budget exceeded")
                    break
                }
                queue += edge.to to (depth + 1)
            }
            if (completion is InspectionCompletion.Interrupted) break
        }
        val unresolved = visited.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(reads, "selected link target unavailable")
        }
        return ReachabilityResult(resources, unresolved, undecided, reads.health().failures, completion)
    }

    context(reads: CapturedAuthoringReads)
    fun incomingResources(
        target: ResourceId,
        family: RelationFamilyId,
    ): PartialSelection<ResourceDraft> {
        val graph = CapturedGraph(reads, RelationSelection.Family(family, TraversalDirection.FORWARD))
        graph.observeAt(target)
        val known = mutableListOf<ResourceDraft>()
        val undecided = mutableListOf<UndecidedCandidate>()
        graph.edgesInto(target).map(DirectedEdge::from).distinct().sortedBy(ResourceId::value).forEach { resource ->
            when (val bound = graph.bind(resource, ResourceDrafts)) {
                is BoundMatch.Match -> known += bound.value
                is BoundMatch.Undecided -> undecided += bound.value
                BoundMatch.No -> Unit
            }
        }
        undecided += graph.undecidedIncoming(target)
        return PartialSelection(known, undecided, InspectionCompletion.Complete, reads.health().failures)
    }

    context(reads: CapturedAuthoringReads)
    fun routes(query: RouteQuery): RouteResult {
        val graph = CapturedGraph(reads, query.links)
        val paths = mutableListOf<List<GraphStep>>()
        var steps = 0L
        var links = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        val queue = ArrayDeque<RouteState>()
        val inspected = linkedSetOf<ResourceId>()
        query.seeds
            .toSkir()
            .sortedBy(ResourceId::value)
            .forEach { seed -> queue += RouteState(seed, emptyList(), setOf(seed)) }
        while (queue.isNotEmpty()) {
            val state = queue.removeFirst()
            if (state.resource !in inspected && inspected.size.toLong() >= query.budget.maxResources) {
                completion = interrupted(reads, "resource budget exceeded")
                break
            }
            inspected += state.resource
            graph.observeAt(state.resource)
            if (state.resource == query.target.toSkir()) {
                if (paths.size.toLong() >= query.budget.maxRoutes) {
                    completion = interrupted(reads, "route budget exceeded")
                    break
                }
                paths += state.steps
                continue
            }
            if (state.steps.size >= query.maxDepth) continue
            for (edge in graph.edgesFrom(state.resource)) {
                if (++links > query.budget.maxLinks || ++steps > query.budget.maxSteps) {
                    completion = interrupted(reads, "route step budget exceeded")
                    break
                }
                if (edge.to in state.visited) continue
                queue += RouteState(edge.to, state.steps + edge.step, state.visited + edge.to)
            }
            if (completion is InspectionCompletion.Interrupted) break
        }
        val unresolved = inspected.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(reads, "selected link target unavailable")
        }
        return RouteResult(paths, unresolved, reads.health().failures, completion)
    }

    context(reads: CapturedAuthoringReads)
    fun occurrences(query: LinkInspectionQuery): LinkInspectionResult {
        val graph = CapturedGraph(reads, query.links)
        val occurrences = mutableListOf<LinkOccurrence>()
        var inspected = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        val sources = query.sources.toSkir().sortedBy(ResourceId::value)
        occurrenceLoop@ for (resource in sources) {
            graph.observeAt(resource)
            for (occurrence in graph.occurrencesAt(resource)) {
                if (++inspected > query.budget.maxLinks) {
                    completion = interrupted(reads, "occurrence budget exceeded")
                    break@occurrenceLoop
                }
                reads.observeInput(InputIdentity.Value(occurrence.id.location))
                occurrences += occurrence
            }
        }
        val unresolved = sources.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(reads, "selected link target unavailable")
        }
        return LinkInspectionResult(occurrences, unresolved, reads.health().failures, completion)
    }

    context(reads: CapturedAuthoringReads)
    fun follow(occurrence: LinkOccurrence): Availability<DraftBinding> {
        reads.observeInput(InputIdentity.Value(occurrence.id.location))
        reads.observeInput(InputIdentity.Existence(occurrence.target.resource))
        return reads.resourceBinding(occurrence.target.resource)
    }
}

private class CapturedGraph(
    private val reads: CapturedAuthoringReads,
    private val selection: RelationSelection,
) {
    private val view = reads.view
    private val root = view.original
    private val links = reads.graphLinks
    private val reportedProblems = mutableSetOf<ValueProblem>()

    init {
        reads.observeInput(InputIdentity.Catalog(root.catalog.generation))
    }

    private fun at(resource: ResourceId): NodeLinks = links.at(resource, selection)

    fun observeAt(resource: ResourceId) {
        reads.observeInput(InputIdentity.Existence(resource))
        val node = at(resource)
        node.problems.forEach { problem ->
            if (reportedProblems.add(problem)) {
                reads.recordFailure(
                    EvaluationDiagnostic(
                        failure = HostFailure.InconsistentGraphProjection,
                        message = "Declared graph projection is inconsistent: ${problem.code}.",
                        locations = listOf(problem.location),
                    ),
                )
            }
        }
        node.contracts.forEach { contract ->
            reads.observeInput(InputIdentity.Incoming(resource, contract.id))
        }
    }

    fun edgesFrom(resource: ResourceId): List<DirectedEdge> = at(resource).outgoing

    fun edgesInto(resource: ResourceId): List<DirectedEdge> = at(resource).incoming

    fun occurrencesAt(resource: ResourceId): List<LinkOccurrence> = at(resource).occurrences

    fun unresolvedAt(resource: ResourceId): List<UnresolvedLink> {
        val node = at(resource)
        return buildList {
            node.unavailable.forEach { occurrence ->
                observeUnavailableTarget(occurrence)
                add(UnresolvedLink.UnavailableTarget(occurrence.id, occurrence.target.resource.toResourceId()))
            }
            val record = view.resources[resource] ?: return@buildList
            val known = (node.occurrences + node.unavailable).mapTo(hashSetOf(), LinkOccurrence::id)
            node.declared.forEach { (endpoint, evidence) ->
                evidence.memberships.forEach { reads.observeInput(InputIdentity.Membership(it)) }
                evidence.forms.forEach { reads.observeInput(InputIdentity.Form(it)) }
                evidence.values.forEach locationLoop@{ location ->
                    reads.observeInput(InputIdentity.Value(location))
                    val occurrence = LinkOccurrenceId(endpoint = endpoint, location = location)
                    if (occurrence in known) return@locationLoop
                    val value = rawValue(record, location.path)
                    if (value == DataValue.UNFILLED) add(UnresolvedLink.Unfilled(occurrence))
                }
            }
        }
    }

    fun undecidedIncoming(target: ResourceId): List<UndecidedCandidate> =
        at(target)
            .unavailableInto
            .asSequence()
            .onEach(::observeUnavailableTarget)
            .groupBy(LinkOccurrence::source)
            .map { (source, occurrences) ->
                UndecidedCandidate(
                    source.toResourceId(),
                    occurrences.map { it.id.location } + ValueLocation.of(target),
                )
            }.sortedBy { it.resource.value }

    private fun observeUnavailableTarget(occurrence: LinkOccurrence) {
        reads.observeInput(InputIdentity.Existence(occurrence.target.resource))
        reads.observeInput(InputIdentity.Form(ValueLocation(resource = occurrence.target.resource, path = ValuePath.root)))
    }

    fun <D : ResourceDraft> bind(
        resource: ResourceId,
        type: DraftType<D>,
    ): BoundMatch<D> {
        val record = view.resources[resource] ?: return BoundMatch.No
        val location = ValueLocation.of(resource)
        val matches =
            when (val requested = type.match) {
                ResourceTypeMatch.AnyResource -> {
                    true
                }

                is ResourceTypeMatch.Definition -> {
                    root.catalog.checked.isNominalSubtype(record.configuration.definition, requested.id)
                }

                is ResourceTypeMatch.Application -> {
                    when (val actual = (root.catalog.checked.authoredTypeOf(record.configuration) as? Resolution.Ready)?.value) {
                        null -> {
                            false
                        }

                        is ResourceType.Complete -> {
                            actual.checked.use == requested.use.use
                        }

                        is ResourceType.Partial -> {
                            return if (actual.definition == requested.use.definition) {
                                BoundMatch.Undecided(UndecidedCandidate(resource.toResourceId(), listOf(location)))
                            } else {
                                BoundMatch.No
                            }
                        }
                    }
                }
            }
        if (!matches) return BoundMatch.No
        return when (val binding = reads.resourceBinding(resource)) {
            is Availability.Available -> BoundMatch.Match(type.bind(binding.value))
            is Availability.Unavailable -> BoundMatch.Undecided(UndecidedCandidate(resource.toResourceId(), binding.locations))
            is Availability.Failed -> BoundMatch.No
        }
    }
}

private sealed interface BoundMatch<out D> {
    data class Match<D>(
        val value: D,
    ) : BoundMatch<D>

    data class Undecided(
        val value: UndecidedCandidate,
    ) : BoundMatch<Nothing>

    data object No : BoundMatch<Nothing>
}

private data class RouteState(
    val resource: ResourceId,
    val steps: List<GraphStep>,
    val visited: Set<ResourceId>,
)

private fun rawValue(
    record: AuthoringRecord?,
    path: ValuePath,
): DataValue? {
    val payload = record?.payload ?: return null
    return (DataValue.RecordWrapper(payload).locate(path) as? LocatedPortableValue.Value)?.value
}

private fun interrupted(
    reads: CapturedAuthoringReads,
    reason: String,
): InspectionCompletion.Interrupted {
    reads.recordIncomplete(reason)
    return InspectionCompletion.Interrupted(reason)
}
