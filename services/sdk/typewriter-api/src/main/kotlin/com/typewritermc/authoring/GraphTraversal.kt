package com.typewritermc.authoring

import com.typewritermc.checking.DraftType
import com.typewritermc.checking.InspectionCompletion
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.ResourceTypeMatch
import com.typewritermc.checking.UndecidedCandidate
import com.typewritermc.expression.EvaluationDiagnostic
import com.typewritermc.types.ResourceId
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

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

fun RelationFamilyId.forward(): RelationSelection = RelationSelection.Family(this, TraversalDirection.FORWARD)

fun RelationFamilyId.reverse(): RelationSelection = RelationSelection.Family(this, TraversalDirection.REVERSE)

fun RelationId.forward(): RelationSelection = RelationSelection.Contracts(setOf(this), TraversalDirection.FORWARD)

fun RelationId.reverse(): RelationSelection = RelationSelection.Contracts(setOf(this), TraversalDirection.REVERSE)

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

    override val id: ResourceId = binding.location.resource.toResourceId()
    override val catalog = binding.catalog
    override val readContext: ReadContext = binding.readContext
    override val location: ValueLocation = binding.location
    override val actualType: Availability<NamedTypeUse> =
        when (val actual = binding.actual) {
            is TypeSelection.CompleteWrapper -> Availability.Available(actual.use)
            is TypeSelection.PendingWrapper -> Availability.Unavailable(listOf(location))
            else -> unknownVariant(actual)
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
fun LinkOccurrence.follow(): Availability<DraftBinding> = graph.follow(this)
