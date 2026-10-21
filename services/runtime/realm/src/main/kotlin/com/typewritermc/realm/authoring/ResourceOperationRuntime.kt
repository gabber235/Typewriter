package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.PlacementAnchor
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ResourceDrafts
import com.typewritermc.authoring.complete
import com.typewritermc.authoring.definition
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.use
import com.typewritermc.checking.InputIdentity
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.operations.AuthoringGraphFacts
import com.typewritermc.operations.BoundResourceOperation
import com.typewritermc.operations.NeedsChoices
import com.typewritermc.operations.OperationIdentities
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.OperationReads
import com.typewritermc.operations.PreparationChoice
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.UnavailableAuthoredValue
import com.typewritermc.operations.UnfinishedOperationInput
import com.typewritermc.operations.asClosedUse
import com.typewritermc.operations.requireAuthored
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.AuthoringPlanRejected
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.template
import com.typewritermc.types.toResourceId
import com.typewritermc.types.unknownVariant
import com.typewritermc.types.use
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.operation.OperationCardinality
import skirout.editor.v1.operation.OperationConfirmation
import skirout.editor.v1.operation.ResolvedResourceOperation
import skirout.editor.v1.operation.ResolvedResourceOperations
import skirout.editor.v1.resource_operations.DropCandidates
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CapabilityId
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import java.util.UUID
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

internal sealed interface OperationPreparationResult {
    data class Preview(
        val edit: PreparedEdit,
        val confirmation: OperationConfirmation?,
        val selection: List<ResourceId>?,
    ) : OperationPreparationResult

    data class NeedsInput(
        val input: DataValue?,
        val choices: List<PreparationChoice>,
        val missing: List<ValuePath> = emptyList(),
    ) : OperationPreparationResult

    data class Invalid(
        val problems: List<ValueProblem>,
    ) : OperationPreparationResult

    data class Unavailable(
        val reason: String,
    ) : OperationPreparationResult

    data class Failed(
        val cause: Throwable,
    ) : OperationPreparationResult
}

internal class OperationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The operation catalog changed")

internal class OperationResolutionFailure(
    val origin: ProviderOrigin,
    cause: Throwable,
) : IllegalStateException("Resource operation availability failed for ${origin.owner.localIdentity}", cause)

/**
 * Resolves operation availability and drop candidates, and prepares edits, against the panel confirmed saved
 * observation plus its overlay.
 *
 * The captured catalog and observation must still match before callbacks run. Preparation stages writes in
 * [WorkingViewEditContext] and returns an expectation bearing preview, input request, or failure. It never persists
 * the panel overlay or preview; committing the resulting edit goes through the authoring repository.
 */
internal class ResourceOperationRuntime(
    private val views: AuthoringViewStore,
) {
    fun resolve(
        invocation: OperationInvocation,
        expectedCatalog: CatalogGeneration,
        confirmedObservation: String,
        upserts: Map<ResourceId, AuthoringRecord>,
        removals: Set<ResourceId>,
    ): ResolvedResourceOperations =
        observe(expectedCatalog, confirmedObservation, upserts, removals) { view ->
            val operations =
                invocation
                    .applicableIn(view, CapturedAuthoringReads(AuthoredReadView.Original(view)))
                    .mapNotNull { operation ->
                        val reads = CapturedAuthoringReads(AuthoredReadView.Original(view))
                        val availability = operation.evaluate(invocation.targets, RealmOperationReads(reads), reads)
                        if (availability == OperationAvailability.HIDDEN) {
                            null
                        } else {
                            ResolvedResourceOperation(definition = operation.definition, availability = availability)
                        }
                    }.sortedWith(
                        compareBy(
                            { it.definition.presentation.group.kind.ordinal },
                            { it.definition.presentation.order },
                            { it.definition.capability.value },
                        ),
                    )
            ResolvedResourceOperations(operations = operations)
        }

    /**
     * Destinations each enabled operation with a drop field accepts for the dragged [invocation] targets, from its
     * declared candidates and accepts check. Preparation never runs; a list longer than [DROP_CANDIDATE_LIMIT] is
     * capped and marked incomplete.
     */
    fun resolveDropCandidates(
        invocation: OperationInvocation,
        expectedCatalog: CatalogGeneration,
        confirmedObservation: String,
        upserts: Map<ResourceId, AuthoringRecord>,
        removals: Set<ResourceId>,
    ): List<DropCandidates> =
        observe(expectedCatalog, confirmedObservation, upserts, removals) { view ->
            invocation
                .applicableIn(view, CapturedAuthoringReads(AuthoredReadView.Original(view)))
                .mapNotNull { operation ->
                    val field = operation.dropField ?: return@mapNotNull null
                    val captured = CapturedAuthoringReads(AuthoredReadView.Original(view))
                    val reads = RealmOperationReads(captured)
                    if (operation.evaluate(invocation.targets, reads, captured) != OperationAvailability.ENABLED) return@mapNotNull null
                    val destinations =
                        operation.guarded(captured) {
                            field
                                .acceptedCandidates(invocation.targets, reads)
                                .filterIsInstance<ResourceId>()
                                .filterNot { it in invocation.targets }
                                .distinct()
                                .take(DROP_CANDIDATE_LIMIT + 1)
                                .toList()
                        }
                    DropCandidates(
                        operation = operation.definition.id,
                        destinations = destinations.take(DROP_CANDIDATE_LIMIT).map { SkirResourceId(value = it.value) },
                        complete = destinations.size <= DROP_CANDIDATE_LIMIT,
                    )
                }
        }

    suspend fun prepare(
        invocation: OperationInvocation,
        expectedCatalog: CatalogGeneration,
        capability: CapabilityId,
        confirmedObservation: String,
        upserts: Map<ResourceId, AuthoringRecord>,
        removals: Set<ResourceId>,
        input: DataValue?,
        choices: PreparationChoices,
    ): OperationPreparationResult =
        views.capture().use { lease ->
            if (lease.root.catalog.generation != expectedCatalog) throw OperationCatalogChanged(lease.root.catalog.generation)
            val baseline = lease.operationObservation(confirmedObservation, upserts, removals)
            val edit = WorkingViewEditContext(baseline, invocation.invocationId)
            val operation = baseline.catalog.operations.requireAuthoring(capability)
            if (operation !in invocation.applicableIn(baseline, edit.capturedReads)) {
                return OperationPreparationResult.Unavailable("This operation does not apply to the captured selection")
            }
            val session = RuntimeOperationPreparation(invocation, choices, edit)
            when (val available = operation.evaluate(invocation.targets, session, edit.capturedReads)) {
                OperationAvailability.ENABLED -> Unit

                is OperationAvailability.DisabledWrapper -> return OperationPreparationResult.Unavailable(available.value)

                OperationAvailability.HIDDEN -> return OperationPreparationResult.Unavailable(
                    "This operation does not apply to the captured selection",
                )

                else -> error("Unknown operation availability.")
            }
            validateOrigin(invocation, baseline, edit.capturedReads)
            operation.input.schema?.let { schema ->
                when (val checked = schema.complete(input ?: DataValue.UNFILLED)) {
                    is CompletenessResult.Unfinished -> return OperationPreparationResult.NeedsInput(
                        input,
                        emptyList(),
                        checked.locations.map { it.path },
                    )

                    is CompletenessResult.Invalid -> return OperationPreparationResult.Invalid(checked.problems)

                    is CompletenessResult.Complete -> Unit
                }
            }
            try {
                operation.prepare(invocation.targets, input, session)
                OperationPreparationResult.Preview(edit.finish(), operation.definition.presentation.confirmation, session.selection)
            } catch (needed: NeedsChoices) {
                OperationPreparationResult.NeedsInput(input, needed.requests)
            } catch (unfinished: UnfinishedOperationInput) {
                OperationPreparationResult.NeedsInput(input, emptyList(), unfinished.paths)
            } catch (missing: UnavailableAuthoredValue) {
                OperationPreparationResult.Invalid(
                    missing.locations.map { ValueProblem(location = it, code = "required_authored_value_missing") },
                )
            } catch (rejected: AuthoringPlanRejected) {
                OperationPreparationResult.Invalid(rejected.problems)
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                OperationPreparationResult.Failed(failure)
            }
        }

    /** Runs [body] against the caller's working observation once its catalog and saved observation are confirmed. */
    private fun <T> observe(
        expectedCatalog: CatalogGeneration,
        confirmedObservation: String,
        upserts: Map<ResourceId, AuthoringRecord>,
        removals: Set<ResourceId>,
        body: (AuthoringView) -> T,
    ): T =
        views.capture().use { lease ->
            if (lease.root.catalog.generation != expectedCatalog) throw OperationCatalogChanged(lease.root.catalog.generation)
            body(lease.operationObservation(confirmedObservation, upserts, removals))
        }

    /** Availability of this operation for [subjects]; a callback failure or incomplete read is a resolution failure. */
    private fun BoundResourceOperation.evaluate(
        subjects: List<ResourceId>,
        reads: OperationReads,
        captured: CapturedAuthoringReads,
    ): OperationAvailability = guarded(captured) { availability(subjects, reads) }

    private fun validateOrigin(
        invocation: OperationInvocation,
        baseline: AuthoringView,
        reads: CapturedAuthoringReads,
    ) {
        invocation.origin.occurrences.forEach { occurrence ->
            require(baseline.links[occurrence.id] == occurrence) { "The captured resource occurrence changed" }
            reads.observeInput(InputIdentity.Value(occurrence.id.location))
            reads.observeInput(InputIdentity.Incoming(occurrence.source.toResourceId(), null))
            reads.observeInput(InputIdentity.Incoming(occurrence.target.resource.toResourceId(), null))
        }
    }
}

/** The catalog operations whose targets cover the whole selection; the targets' existence and types are recorded as read. */
internal fun OperationInvocation.applicableIn(
    view: AuthoringView,
    reads: CapturedAuthoringReads,
): List<BoundResourceOperation> {
    val records = targets.map { id -> requireNotNull(view.resources[id]) { "The operation target is unavailable" } }
    targets.forEach { id ->
        reads.observeInput(InputIdentity.Existence(id))
        reads.observeInput(InputIdentity.Form(ValueLocation.of(id)))
    }
    return view.catalog.operations.operations
        .filter { it.covers(records, view) }
}

/** Runs [body] for this operation and checks its reads; a failure or incomplete read is a resolution failure. */
internal fun <T> BoundResourceOperation.guarded(
    captured: CapturedAuthoringReads,
    body: () -> T,
): T =
    try {
        body().also {
            val health = captured.health()
            check(health.failures.isEmpty() && health.incomplete.isEmpty()) {
                "Operation reads did not produce complete evidence: $health"
            }
        }
    } catch (failure: Exception) {
        failure.rethrowExceptional()
        throw OperationResolutionFailure(origin, failure)
    }

private fun BoundResourceOperation.covers(
    records: List<AuthoringRecord>,
    view: AuthoringView,
): Boolean {
    val count =
        when (definition.targets.cardinality) {
            OperationCardinality.SINGLE -> records.size == 1
            OperationCardinality.SELECTION -> records.isNotEmpty()
            else -> false
        }
    return count &&
        when (val subject = target) {
            ResourceTarget.AnyResource -> true
            is ResourceTarget.Type -> records.all { it.matches(subject.template, view) }
        }
}

private fun AuthoringRecord.matches(
    target: NamedTypeTemplate,
    view: AuthoringView,
): Boolean =
    when (val actual = configuration) {
        is TypeSelection.CompleteWrapper -> {
            view.catalog.checked.isReadableAs(actual.use.use, target.asClosedUse().use)
        }

        is TypeSelection.PendingWrapper -> {
            target.arguments.isEmpty() &&
                view.catalog.checked.isNominalSubtype(actual.definition, target.definition)
        }

        else -> {
            unknownVariant(actual)
        }
    }

/** The most destinations one operation offers for a drag; longer lists are capped and marked incomplete. */
internal const val DROP_CANDIDATE_LIMIT = 200

/** Operation reads of one captured graph without edits: authored reads and graph facts. */
internal class RealmOperationReads(
    private val captured: CapturedAuthoringReads,
) : OperationReads,
    AuthoredReads by captured,
    AuthoringGraphFacts by RealmGraphFacts(RelationReads(captured)) {
    override fun resourceDraft(id: ResourceId): ResourceDraft = captured.resourceDraft(id)
}

/** One preparation attempt: authored reads, graph facts and edits, all staged into [edit]. */
internal class RuntimeOperationPreparation(
    override val invocation: OperationInvocation,
    override val choices: PreparationChoices,
    private val edit: WorkingViewEditContext,
    relations: RelationReads = RelationReads(edit.capturedReads),
) : OperationPreparation,
    EditContext by edit,
    AuthoringGraphFacts by RealmGraphFacts(relations) {
    private val relationEdits = OperationRelationPreparation(relations)
    private val layouts = OperationLayoutPreparation(relations)
    private val cloner = OperationClonePreparation(relations, relationEdits, layouts)

    override val identities: OperationIdentities =
        object : OperationIdentities {
            override fun resource(key: String) = ResourceId(identity("resource", key))

            override fun item(key: String) = ItemId(value = identity("item", key))

            private fun identity(
                kind: String,
                key: String,
            ) = UUID.nameUUIDFromBytes("${invocation.invocationId}:$kind:$key".toByteArray()).toString()
        }

    var selection: List<ResourceId>? = null
        private set

    override fun resourceDraft(id: ResourceId): ResourceDraft = edit.capturedReads.resourceDraft(id)

    override fun selectAfterStaging(ids: List<ResourceId>) {
        require(ids.all { it in edit.session.resources }) { "The result selection contains an absent resource" }
        selection = ids.distinct()
    }

    override suspend fun delete(ids: List<ResourceId>) = edit.deleteAll(ids)

    override suspend fun duplicate(roots: List<ResourceId>): List<ResourceId> = cloner.duplicateOwned(roots)

    override suspend fun move(
        ids: List<ResourceId>,
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ) {
        val moved = relationEdits.move(ids, destination)
        with(layouts) { moved.placeIn(destination, anchor) }
    }

    override suspend fun link(
        ids: List<ResourceId>,
        target: ResourceId,
    ) = relationEdits.link(ids, target)

    override suspend fun unlink(
        ids: List<ResourceId>,
        target: ResourceId,
    ) = relationEdits.unlink(ids, target)
}

/** [id] bound as a draft of any resource; an unreadable binding fails the read. */
private fun CapturedAuthoringReads.resourceDraft(id: ResourceId): ResourceDraft = ResourceDrafts.bind(requireAuthored(resourceBinding(id)))
