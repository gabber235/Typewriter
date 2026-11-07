package com.typewritermc.realm.authoring

import com.typewritermc.authoring.RelationSelection
import com.typewritermc.authoring.links
import com.typewritermc.checking.InputIdentity
import com.typewritermc.formula.graph.GraphKey
import com.typewritermc.formula.graph.InputKey
import com.typewritermc.formula.graph.Query
import com.typewritermc.formula.graph.QueryReads
import com.typewritermc.formula.graph.TrackedGraph
import com.typewritermc.formula.graph.UntrackedEnvironment
import com.typewritermc.realm.catalog.ExtensionCatalog
import com.typewritermc.realm.catalog.code
import com.typewritermc.types.ownsResources
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.TypeUse
import skirout.kernel.v1.resource_id.ResourceId

/** What realm queries read: one immutable view, and services that stay the same for the realm's lifetime. */
class RealmEnvironment internal constructor(
    val view: AuthoringView,
    val services: RealmServices,
)

/**
 * Built once with the view store. A check in a pass and a reader in a commit's fork read through the same ones. The
 * realm passes the check runtime's predicate evaluator; without it, a selection predicate cannot be evaluated.
 */
class RealmServices(
    val predicates: SelectionPredicateEvaluator = MissingSelectionPredicateEvaluator,
    val limits: ViewReadLimits = ViewReadLimits(),
)

typealias AuthoringGraph = TrackedGraph<RealmEnvironment>
typealias RealmQuery<T> = Query<RealmEnvironment, T>
typealias RealmReads = QueryReads<RealmEnvironment>

// Private to this file: a query reads records, links and ids through Fact, ProjectionAt or tracked(), so its evidence
// is complete.
private data class ResourceInput(
    val id: ResourceId,
) : InputKey<RealmEnvironment, AuthoringRecord?> {
    override fun read(environment: RealmEnvironment) = environment.view.resources[id]
}

/** This resource's slice of the view's stored links. */
private data class LinksInput(
    val resource: ResourceId,
) : InputKey<RealmEnvironment, LinkSlice> {
    override fun read(environment: RealmEnvironment) = environment.view.linkSlice(resource)
}

private data object ResourceIdsInput : InputKey<RealmEnvironment, Set<ResourceId>> {
    override fun read(environment: RealmEnvironment) = environment.view.resources.keys
}

/** One read fact. Its value is the commit guard expectations for that fact, which is how evidence is built. */
data class Fact(
    val identity: InputIdentity,
) : RealmQuery<List<EditExpectation>> {
    @OptIn(UntrackedEnvironment::class)
    context(reads: RealmReads)
    override fun compute(): List<EditExpectation> {
        val view = reads.environment.view
        return when (identity) {
            // Incoming's value comes from the judged projection, so a retyped end reruns it, not only a stored change.
            is InputIdentity.Incoming -> {
                val judged = reads.read(ProjectionAt(identity.resource))
                view.catalog.relations.filter { identity.relation == null || it.id == identity.relation }.map { contract ->
                    EditExpectation.links(
                        identity.resource,
                        contract.id,
                        TraversalDirection.BOTH,
                        judged.projections.filterTo(linkedSetOf()) {
                            it.contract == contract.id && (it.first == identity.resource || it.second == identity.resource)
                        },
                    )
                }
            }

            is InputIdentity.Selection -> {
                reads.read(ResourceIdsInput)
                view.expectations(identity)
            }

            is InputIdentity.Catalog -> {
                // Only a new generation changes it, and a new generation resets the graph.
                emptyList()
            }

            else -> {
                reads.read(ResourceInput(identity.resource()))
                view.expectations(identity)
            }
        }
    }
}

private fun InputIdentity.resource(): ResourceId =
    when (this) {
        is InputIdentity.Value -> at.resource
        is InputIdentity.Form -> at.resource
        is InputIdentity.Membership -> at.resource
        is InputIdentity.Order -> at.resource
        is InputIdentity.Existence -> resource
        is InputIdentity.Resource -> resource
        is InputIdentity.Types -> resource
        is InputIdentity.Incoming -> resource
        is InputIdentity.Selection, is InputIdentity.Catalog -> error("$this reads no single resource.")
    }

/** Judges one resource's slice of links through the tracked reader, so every record and declaration it read is its evidence. */
internal data class ProjectionAt(
    val resource: ResourceId,
) : RealmQuery<ResourceProjection> {
    context(reads: RealmReads)
    override fun compute(): ResourceProjection = tracked().judge(resource, reads.read(LinksInput(resource)))
}

/** What a graph read needs at one node in one selection. A graph read reads it only at the nodes it visits. */
internal data class LinksAt(
    val resource: ResourceId,
    val selection: RelationSelection,
) : RealmQuery<NodeLinks> {
    context(reads: RealmReads)
    override fun compute(): NodeLinks = tracked().linksAt(resource, reads.read(ProjectionAt(resource)), selection)
}

/** The links [resource] itself stores, unjudged: they change only with its record. */
internal data class OwnLinks(
    val resource: ResourceId,
) : RealmQuery<List<LinkOccurrence>> {
    context(reads: RealmReads)
    override fun compute(): List<LinkOccurrence> = reads.read(LinksInput(resource)).own
}

// The only opt ins outside Fact. Each builds a tracked reader, or reads what only a new generation changes, and a new
// generation resets the graph.

/** Authored reads recorded on the running query: the one reader a query uses for records, ids and links. */
@OptIn(UntrackedEnvironment::class)
context(reads: RealmReads)
internal fun tracked(): CapturedAuthoringReads =
    CapturedAuthoringReads(
        AuthoredReadView.Original(reads.environment.view),
        TrackedRecorder(reads),
        reads.environment.services.predicates,
        reads.environment.services.limits,
    )

/** The extensions of this view's code catalog. */
@OptIn(UntrackedEnvironment::class)
context(reads: RealmReads)
internal val extensions: ExtensionCatalog get() = reads.environment.view.catalog.code.extensions

/** The code types formulas name by their display name. */
@OptIn(UntrackedEnvironment::class)
context(reads: RealmReads)
internal val formulaTypeNames: Map<String, List<TypeUse>> get() = reads.environment.view.catalog.code.formulaTypeNames

/** The relations of the view's catalog that own resources. */
@OptIn(UntrackedEnvironment::class)
context(reads: RealmReads)
internal val ownershipRelations: List<RelationContract>
    get() =
        reads.environment.view.catalog.relations
            .filter { it.ownsResources }

/** The generation of the view's catalog. */
@OptIn(UntrackedEnvironment::class)
context(reads: RealmReads)
internal val generation get() = reads.environment.view.catalog.generation

/**
 * Everything this query read at this revision, current even when a query below reran with an equal result. Which
 * checks exist is not what a check read, so it does not enter [stopAt]'s queries.
 */
context(reads: RealmReads)
internal fun RealmQuery<*>.factsRead(stopAt: (GraphKey<*>) -> Boolean): List<EditExpectation> =
    reads
        .readsOf(this, stopAt)
        .filterIsInstance<Fact>()
        .flatMap { reads.read(it) }
        .distinct()

/** Records each read as a fact of the running query, and reads graph links through the graph. */
internal class TrackedRecorder(
    private val reads: RealmReads,
) : ObservationRecorder {
    override fun observe(identity: InputIdentity) {
        reads.read(Fact(identity))
    }

    override fun graphLinks(reads: CapturedAuthoringReads): GraphLinks =
        GraphLinks { resource, selection -> this.reads.read(LinksAt(resource, selection)) }
}

/** A lease on one view and reads pinned to it, taken together. The view's catalog stays open with the lease. */
class PinnedReads internal constructor(
    private val lease: AuthoringLease,
    val reads: RealmReads,
) : AutoCloseable {
    val view: AuthoringView get() = lease.root

    override fun close() = lease.close()
}

/**
 * The inputs whose value may differ between [before] and this view of the same generation. Reference comparisons
 * only, so install runs it under the view lock: an untouched record and an untouched slice keep their identity.
 */
internal fun AuthoringView.changesFrom(before: AuthoringView): Set<InputKey<RealmEnvironment, *>> =
    buildSet {
        (resources.keys + before.resources.keys)
            .filter { resources[it] !== before.resources[it] }
            .forEach { add(ResourceInput(it)) }
        if (resources.keys != before.resources.keys) add(ResourceIdsInput)
        (linkSlices.keys + before.linkSlices.keys)
            .filter { linkSlices[it] !== before.linkSlices[it] }
            .forEach { add(LinksInput(it)) }
    }
