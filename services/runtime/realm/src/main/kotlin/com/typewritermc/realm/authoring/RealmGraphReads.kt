package com.typewritermc.realm.authoring

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.GraphEndpoint
import com.typewritermc.authoring.GraphReads
import com.typewritermc.authoring.GraphStep
import com.typewritermc.authoring.LinkInspectionQuery
import com.typewritermc.authoring.LinkInspectionResult
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.ReachabilityQuery
import com.typewritermc.authoring.ReachabilityResult
import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.RouteQuery
import com.typewritermc.authoring.RouteResult
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.UnresolvedLink
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.realm.checking.SnapshotReadCapability
import com.typewritermc.realm.checking.SnapshotReads
import com.typewritermc.realm.repository.LinkSchemaCapabilities
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointBindingTemplate
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution

/** Traverses only the graph derived from the retained authored snapshot. */
internal object RealmGraphReads : GraphReads {
    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun <D : ResourceDraft> reachable(query: ReachabilityQuery<D>): ReachabilityResult<D> {
        val snapshot = reads.requireSnapshotReads()
        val graph = CapturedGraph(snapshot, query.links)
        val queue = ArrayDeque<Pair<ResourceId, Int>>()
        query.seeds.sortedBy(ResourceId::value).forEach { queue += it to 0 }
        val visited = linkedSetOf<ResourceId>()
        val resources = mutableListOf<D>()
        val undecided = mutableListOf<UndecidedCandidate>()
        var links = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        while (queue.isNotEmpty()) {
            val (resource, depth) = queue.removeFirst()
            if (!visited.add(resource)) continue
            if (visited.size > query.budget.maxResources) {
                completion = interrupted(snapshot, "resource budget exceeded")
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
                    completion = interrupted(snapshot, "link budget exceeded")
                    break
                }
                queue += edge.to to (depth + 1)
            }
            if (completion is InspectionCompletion.Interrupted) break
        }
        val unresolved = visited.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(snapshot, "selected link target unavailable")
        }
        return ReachabilityResult(resources, unresolved, undecided, snapshot.health().failures, completion)
    }

    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun incomingResources(
        target: ResourceId,
        family: RelationFamilyId,
    ): PartialSelection<ResourceDraft> {
        val snapshot = reads.requireSnapshotReads()
        val graph = CapturedGraph(snapshot, RelationSelection.Family(family, TraversalDirection.Forward))
        graph.observeAt(target)
        val known = mutableListOf<ResourceDraft>()
        val undecided = mutableListOf<UndecidedCandidate>()
        graph.edgesInto(target).map(DirectedEdge::from).distinct().sortedBy(ResourceId::value).forEach { resource ->
            when (val bound = graph.bind(resource, com.typewritermc.authoring.ResourceDrafts)) {
                is BoundMatch.Match -> known += bound.value
                is BoundMatch.Undecided -> undecided += bound.value
                BoundMatch.No -> Unit
            }
        }
        undecided += graph.undecidedIncoming(target)
        return PartialSelection(known, undecided, InspectionCompletion.Complete, snapshot.health().failures)
    }

    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun routes(query: RouteQuery): RouteResult {
        val snapshot = reads.requireSnapshotReads()
        val graph = CapturedGraph(snapshot, query.links)
        val paths = mutableListOf<List<GraphStep>>()
        var steps = 0L
        var links = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        val queue = ArrayDeque<RouteState>()
        val inspected = linkedSetOf<ResourceId>()
        query.seeds.sortedBy(ResourceId::value).forEach { seed -> queue += RouteState(seed, emptyList(), setOf(seed)) }
        while (queue.isNotEmpty()) {
            val state = queue.removeFirst()
            if (state.resource !in inspected && inspected.size.toLong() >= query.budget.maxResources) {
                completion = interrupted(snapshot, "resource budget exceeded")
                break
            }
            inspected += state.resource
            graph.observeAt(state.resource)
            if (state.resource == query.target) {
                if (paths.size.toLong() >= query.budget.maxRoutes) {
                    completion = interrupted(snapshot, "route budget exceeded")
                    break
                }
                paths += state.steps
                continue
            }
            if (state.steps.size >= query.maxDepth) continue
            for (edge in graph.edgesFrom(state.resource)) {
                if (++links > query.budget.maxLinks || ++steps > query.budget.maxSteps) {
                    completion = interrupted(snapshot, "route step budget exceeded")
                    break
                }
                if (edge.to in state.visited) continue
                queue += RouteState(edge.to, state.steps + edge.step, state.visited + edge.to)
            }
            if (completion is InspectionCompletion.Interrupted) break
        }
        val unresolved = inspected.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(snapshot, "selected link target unavailable")
        }
        return RouteResult(paths, unresolved, snapshot.health().failures, completion)
    }

    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun occurrences(query: LinkInspectionQuery): LinkInspectionResult {
        val snapshot = reads.requireSnapshotReads()
        val graph = CapturedGraph(snapshot, query.links)
        val occurrences = mutableListOf<LinkOccurrence>()
        var inspected = 0L
        var completion: InspectionCompletion = InspectionCompletion.Complete
        occurrenceLoop@ for (resource in query.sources.sortedBy(ResourceId::value)) {
            graph.observeAt(resource)
            for (occurrence in graph.occurrencesAt(resource)) {
                if (++inspected > query.budget.maxLinks) {
                    completion = interrupted(snapshot, "occurrence budget exceeded")
                    break@occurrenceLoop
                }
                snapshot.observeInput(InputIdentity.Value(occurrence.id.location))
                occurrences += occurrence
            }
        }
        val unresolved = query.sources.flatMap(graph::unresolvedAt).distinct()
        if (completion is InspectionCompletion.Complete && unresolved.any { it is UnresolvedLink.UnavailableTarget }) {
            completion = interrupted(snapshot, "selected link target unavailable")
        }
        return LinkInspectionResult(occurrences, unresolved, snapshot.health().failures, completion)
    }

    context(reads: com.typewritermc.authoring.AuthoredReads)
    override fun follow(occurrence: LinkOccurrence): Availability<DraftBinding> {
        val snapshot = reads.requireSnapshotReads()
        snapshot.observeInput(InputIdentity.Value(occurrence.id.location))
        snapshot.observeInput(InputIdentity.Existence(occurrence.target.resource))
        return snapshot.resourceBinding(occurrence.target.resource)
    }
}

private class CapturedGraph(
    private val reads: SnapshotReads,
    private val selection: RelationSelection,
) {
    private val view = reads.view
    private val root = view.original
    private val index = view.graphIndex(selection)
    private val reportedProblems = mutableSetOf<com.typewritermc.authoring.ValueProblem>()

    init {
        reads.observeInput(InputIdentity.Catalog(root.catalog.generation))
    }

    fun observeAt(resource: ResourceId) {
        reads.observeInput(InputIdentity.Existence(resource))
        index.projectionProblems[resource].orEmpty().forEach { problem ->
            if (reportedProblems.add(problem)) {
                reads.recordFailure(
                    EvaluationDiagnostic(problem.code, "Declared graph projection is inconsistent.", listOf(problem.location)),
                )
            }
        }
        index.contracts.forEach { contract ->
            reads.observeInput(InputIdentity.Incoming(resource, contract.id))
        }
    }

    fun edgesFrom(resource: ResourceId): List<DirectedEdge> = index.outgoing[resource].orEmpty()

    fun edgesInto(resource: ResourceId): List<DirectedEdge> = index.incoming[resource].orEmpty()

    fun occurrencesAt(resource: ResourceId): List<LinkOccurrence> =
        index.occurrencesBySource[resource].orEmpty().sortedBy {
            it.id.location.path
                .toString()
        }

    fun unresolvedAt(resource: ResourceId): List<UnresolvedLink> {
        return buildList {
            index.unavailableBySource[resource].orEmpty().forEach { occurrence ->
                observeUnavailableTarget(occurrence)
                add(UnresolvedLink.UnavailableTarget(occurrence.id, occurrence.target.resource))
            }
            index.selectedEndpoints.forEach endpointLoop@{ endpoint ->
                val record = view.resources[resource] ?: return@endpointLoop
                val evidence = index.declaredEvidence.getValue(resource).getValue(endpoint)
                evidence.memberships.forEach { reads.observeInput(InputIdentity.Membership(it)) }
                evidence.forms.forEach { reads.observeInput(InputIdentity.Form(it)) }
                evidence.values.forEach locationLoop@{ location ->
                    reads.observeInput(InputIdentity.Value(location))
                    val occurrence = LinkOccurrenceId(endpoint, location)
                    if (occurrence in index.occurrenceIds || occurrence in index.unavailableOccurrenceIds) {
                        return@locationLoop
                    }
                    val value = rawValue(record, location.path)
                    if (value == DataValue.Unfilled) add(UnresolvedLink.Unfilled(occurrence))
                }
            }
        }
    }

    fun undecidedIncoming(target: ResourceId): List<UndecidedCandidate> =
        index.unavailableByTarget[target]
            .orEmpty()
            .asSequence()
            .onEach(::observeUnavailableTarget)
            .groupBy(LinkOccurrence::source)
            .map { (source, occurrences) ->
                UndecidedCandidate(
                    source,
                    occurrences.map { it.id.location } + ValueLocation(target, ValuePath()),
                )
            }.sortedBy { it.resource.value }

    private fun observeUnavailableTarget(occurrence: LinkOccurrence) {
        reads.observeInput(InputIdentity.Existence(occurrence.target.resource))
        reads.observeInput(InputIdentity.Form(ValueLocation(occurrence.target.resource, ValuePath())))
    }

    fun <D : ResourceDraft> bind(
        resource: ResourceId,
        type: DraftType<D>,
    ): BoundMatch<D> {
        val record = view.resources[resource] ?: return BoundMatch.No
        val location = ValueLocation(resource, ValuePath())
        val matches =
            when (val requested = type.match) {
                ResourceTypeMatch.AnyResource -> {
                    true
                }

                is ResourceTypeMatch.Definition -> {
                    when (val actual = record.configuration) {
                        is com.typewritermc.authoring.TypeSelection.Complete -> {
                            root.catalog.checked.isNominalSubtype(actual.use.definition, requested.id)
                        }

                        is com.typewritermc.authoring.TypeSelection.Pending -> {
                            root.catalog.checked.isNominalSubtype(actual.definition, requested.id)
                        }
                    }
                }

                is ResourceTypeMatch.Application -> {
                    when (val actual = record.configuration) {
                        is com.typewritermc.authoring.TypeSelection.Complete -> {
                            actual.use == requested.use
                        }

                        is com.typewritermc.authoring.TypeSelection.Pending -> {
                            return if (actual.definition == requested.use.definition) {
                                BoundMatch.Undecided(UndecidedCandidate(resource, listOf(location)))
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
            is Availability.Unavailable -> BoundMatch.Undecided(UndecidedCandidate(resource, binding.locations))
            is Availability.Failed -> BoundMatch.No
        }
    }
}

internal class CapturedGraphIndex(
    private val view: AuthoredSnapshotView,
    selection: RelationSelection,
) {
    private val root = view.original
    private val capabilities = LinkSchemaCapabilities(root.catalog.checked)
    val contracts = selectedContracts(root.catalog.relations, selection)
    private val contractById = contracts.associateBy(RelationContract::id)
    val selectedEndpoints = contracts.flatMapTo(linkedSetOf()) { listOf(it.first.id, it.second.id) }
    private val occurrences = view.links.values.filter { it.id.endpoint in selectedEndpoints }
    val occurrenceIds = occurrences.mapTo(hashSetOf(), LinkOccurrence::id)
    val occurrencesBySource = occurrences.groupBy(LinkOccurrence::source)
    val unavailableOccurrences = occurrences.filterTo(linkedSetOf(), ::hasUnavailableTarget)
    val unavailableBySource = unavailableOccurrences.groupBy(LinkOccurrence::source)
    val unavailableByTarget = unavailableOccurrences.groupBy { it.target.resource }
    val unavailableOccurrenceIds = unavailableOccurrences.mapTo(hashSetOf(), LinkOccurrence::id)
    val declaredEvidence =
        view.resources.mapValues { (resource, record) ->
            selectedEndpoints.associateWith { endpoint ->
                ResourceValueMapper.declaredEvidence(endpoint, resource, record, root.catalog.checked, capabilities)
            }
        }
    val projectionProblems: Map<ResourceId, List<com.typewritermc.authoring.ValueProblem>>
    val outgoing: Map<ResourceId, List<DirectedEdge>>
    val incoming: Map<ResourceId, List<DirectedEdge>>

    init {
        val result =
            ResourceValueMapper.project(
                occurrences,
                view.resources,
                contracts,
                root.catalog.checked,
            )
        projectionProblems =
            result.problems
                .filterNot { problem ->
                    unavailableOccurrences.any { it.id.location == problem.location }
                }.groupBy { it.location.resource }
        val directed =
            result.projections.flatMap { projection ->
                projection.directed(contractById.getValue(projection.contract), direction(selection))
            }
        outgoing = directed.groupBy(DirectedEdge::from)
        incoming = directed.groupBy(DirectedEdge::to)
    }

    private fun hasUnavailableTarget(occurrence: LinkOccurrence): Boolean {
        val target = view.resources[occurrence.target.resource] ?: return true
        return when (val selected = target.configuration) {
            is com.typewritermc.authoring.TypeSelection.Pending -> {
                true
            }

            is com.typewritermc.authoring.TypeSelection.Complete -> {
                root.catalog.checked.resolve(selected.use) !is Resolution.Ready
            }
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

internal data class DirectedEdge(
    val from: ResourceId,
    val to: ResourceId,
    val step: GraphStep,
)

private data class RouteState(
    val resource: ResourceId,
    val steps: List<GraphStep>,
    val visited: Set<ResourceId>,
)

private fun LinkProjection.directed(
    contract: RelationContract,
    direction: TraversalDirection,
): List<DirectedEdge> =
    buildList {
        if (direction != TraversalDirection.Reverse) add(forward(contract))
        if (direction != TraversalDirection.Forward) add(reverse(contract))
    }

private fun LinkProjection.forward(contract: RelationContract): DirectedEdge =
    DirectedEdge(
        first,
        second,
        GraphStep(
            contract.id,
            GraphEndpoint(first, contract.first.id, firstLocation),
            GraphEndpoint(second, contract.second.id, secondLocation),
        ),
    )

private fun LinkProjection.reverse(contract: RelationContract): DirectedEdge =
    DirectedEdge(
        second,
        first,
        GraphStep(
            contract.id,
            GraphEndpoint(second, contract.second.id, secondLocation),
            GraphEndpoint(first, contract.first.id, firstLocation),
        ),
    )

private fun selectedContracts(
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

private fun rawValue(
    record: com.typewritermc.authoring.AuthoringRecord?,
    path: ValuePath,
): DataValue? {
    var cursor: RawCursor = RawCursor.Value(DataValue.Record(record?.fields ?: return null))
    path.segments.forEach { segment ->
        cursor =
            when (segment) {
                is com.typewritermc.authoring.PathSegment.Field -> {
                    val current = cursor.valueOrNull()?.unwrapNamed() as? DataValue.Record ?: return null
                    current.fields[segment.name]?.let(RawCursor::Value)
                }

                is com.typewritermc.authoring.PathSegment.Item -> {
                    when (val current = cursor.valueOrNull()?.unwrapNamed()) {
                        is DataValue.ListValue -> {
                            current.items
                                .singleOrNull { it.id == segment.id }
                                ?.value
                                ?.let(RawCursor::Value)
                        }

                        is DataValue.SetValue -> {
                            current.items
                                .singleOrNull { it.id == segment.id }
                                ?.value
                                ?.let(RawCursor::Value)
                        }

                        is DataValue.MapValue -> {
                            current.rows.singleOrNull { it.id == segment.id }?.let(RawCursor::Row)
                        }

                        else -> {
                            null
                        }
                    }
                }

                com.typewritermc.authoring.PathSegment.MapKey -> {
                    (cursor as? RawCursor.Row)?.row?.key?.let(RawCursor::Value)
                }

                com.typewritermc.authoring.PathSegment.MapValue -> {
                    (cursor as? RawCursor.Row)?.row?.value?.let(RawCursor::Value)
                }
            } ?: return null
    }
    return cursor.valueOrNull()
}

private sealed interface RawCursor {
    data class Value(
        val value: DataValue,
    ) : RawCursor

    data class Row(
        val row: com.typewritermc.types.MapRow,
    ) : RawCursor

    fun valueOrNull(): DataValue? = (this as? Value)?.value
}

private fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload.unwrapNamed() else this

private fun com.typewritermc.authoring.AuthoredReads.requireSnapshotReads(): SnapshotReads =
    (this as? SnapshotReadCapability)?.snapshotReads
        ?: error("Graph reads require the retained Realm snapshot capability.")

private fun interrupted(
    reads: SnapshotReads,
    reason: String,
): InspectionCompletion.Interrupted {
    reads.recordIncomplete(reason)
    return InspectionCompletion.Interrupted(reason)
}
