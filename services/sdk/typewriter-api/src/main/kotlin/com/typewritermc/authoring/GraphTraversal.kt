package com.typewritermc.authoring

import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.types.EndpointId
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import kotlinx.serialization.Serializable

interface GraphReads {
    context(reads: AuthoredReads)
    fun <D : ResourceDraft> reachable(query: ReachabilityQuery<D>): ReachabilityResult<D>

    context(reads: AuthoredReads)
    fun incomingResources(
        target: ResourceId,
        family: RelationFamilyId,
    ): PartialSelection<ResourceDraft>

    context(reads: AuthoredReads)
    fun routes(query: RouteQuery): RouteResult

    context(reads: AuthoredReads)
    fun occurrences(query: LinkInspectionQuery): LinkInspectionResult

    context(reads: AuthoredReads)
    fun follow(occurrence: LinkOccurrence): Availability<DraftBinding>
}

@Serializable
enum class TraversalDirection { Forward, Reverse, Both }

sealed interface RelationSelection {
    data class Family(
        val id: RelationFamilyId,
        val direction: TraversalDirection,
    ) : RelationSelection

    data class Contracts(
        val ids: Set<RelationId>,
        val direction: TraversalDirection,
    ) : RelationSelection

    data class All(
        val direction: TraversalDirection,
    ) : RelationSelection
}

data class TraversalBudget(
    val maxResources: Long = 10_000,
    val maxLinks: Long = 50_000,
    val maxRoutes: Long = 1_000,
    val maxSteps: Long = 100_000,
)

sealed interface UnresolvedLink {
    data class Unfilled(
        val occurrence: LinkOccurrenceId,
    ) : UnresolvedLink

    data class UnavailableTarget(
        val occurrence: LinkOccurrenceId,
        val target: ResourceId,
    ) : UnresolvedLink
}

data class ReachabilityQuery<D : ResourceDraft>(
    val seeds: Set<ResourceId>,
    val links: RelationSelection,
    val type: DraftType<D>,
    val maxDepth: Int? = null,
    val budget: TraversalBudget = TraversalBudget(),
)

data class ReachabilityResult<D : ResourceDraft>(
    val resources: List<D>,
    val unresolved: List<UnresolvedLink>,
    val undecided: List<UndecidedCandidate>,
    val failures: List<EvaluationDiagnostic>,
    val completion: InspectionCompletion,
)

data class GraphEndpoint(
    val resource: ResourceId,
    val endpoint: EndpointId,
    val path: ValuePath?,
)

data class GraphStep(
    val relation: RelationId,
    val from: GraphEndpoint,
    val to: GraphEndpoint,
)

data class RouteQuery(
    val seeds: Set<ResourceId>,
    val target: ResourceId,
    val links: RelationSelection,
    val maxDepth: Int,
    val budget: TraversalBudget = TraversalBudget(),
)

data class RouteResult(
    val paths: List<List<GraphStep>>,
    val unresolved: List<UnresolvedLink>,
    val failures: List<EvaluationDiagnostic>,
    val completion: InspectionCompletion,
)

data class LinkInspectionQuery(
    val sources: Set<ResourceId>,
    val links: RelationSelection,
    val budget: TraversalBudget = TraversalBudget(),
)

data class LinkInspectionResult(
    val occurrences: List<LinkOccurrence>,
    val unresolved: List<UnresolvedLink>,
    val failures: List<EvaluationDiagnostic>,
    val completion: InspectionCompletion,
)

fun RelationFamilyId.forward(): RelationSelection = RelationSelection.Family(this, TraversalDirection.Forward)

fun RelationFamilyId.reverse(): RelationSelection = RelationSelection.Family(this, TraversalDirection.Reverse)

fun RelationId.forward(): RelationSelection = RelationSelection.Contracts(setOf(this), TraversalDirection.Forward)

fun RelationId.reverse(): RelationSelection = RelationSelection.Contracts(setOf(this), TraversalDirection.Reverse)

object ResourceDrafts : DraftType<ResourceDraft> {
    override val match: ResourceTypeMatch = ResourceTypeMatch.AnyResource

    override fun bind(binding: DraftBinding): ResourceDraft = BoundResourceDraft(binding)
}

private class BoundResourceDraft(
    private val binding: DraftBinding,
) : ResourceDraft {
    init {
        require(
            binding.location.path.segments
                .isEmpty(),
        ) { "A resource draft must bind at the resource root." }
    }

    override val id: ResourceId = binding.location.resource
    override val catalog = binding.catalog
    override val readContext: ReadContext = binding.readContext
    override val location: ValueLocation = binding.location
    override val actualType: Availability<TypeUse.Named> =
        when (val actual = binding.actual) {
            is TypeSelection.Complete -> Availability.Available(actual.use)
            is TypeSelection.Pending -> Availability.Unavailable(listOf(location))
        }
}

context(reads: AuthoredReads, graph: GraphReads)
fun <D : ResourceDraft> ResourceId.reachable(
    links: RelationSelection,
    type: DraftType<D>,
    maxDepth: Int? = null,
    budget: TraversalBudget = TraversalBudget(),
): ReachabilityResult<D> = graph.reachable(ReachabilityQuery(setOf(this), links, type, maxDepth, budget))

context(reads: AuthoredReads, graph: GraphReads)
fun ResourceId.routesTo(
    target: ResourceId,
    links: RelationSelection,
    maxDepth: Int,
    budget: TraversalBudget = TraversalBudget(),
): RouteResult = graph.routes(RouteQuery(setOf(this), target, links, maxDepth, budget))

context(reads: AuthoredReads, graph: GraphReads)
fun ResourceId.linkOccurrences(
    links: RelationSelection,
    budget: TraversalBudget = TraversalBudget(),
): LinkInspectionResult = graph.occurrences(LinkInspectionQuery(setOf(this), links, budget))

context(reads: AuthoredReads, graph: GraphReads)
fun LinkOccurrence.follow(): Availability<DraftBinding> = graph.follow(this)
