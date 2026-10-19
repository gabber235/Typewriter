package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.CompletenessResult
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.authoring.complete
import com.typewritermc.capability.CapabilityId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.NeedsChoices
import com.typewritermc.operations.OperationAvailability
import com.typewritermc.operations.OperationConfirmation
import com.typewritermc.operations.OperationIdentities
import com.typewritermc.operations.OperationInvocation
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.OperationTargets
import com.typewritermc.operations.PreparationChoice
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.ResolvedResourceOperation
import com.typewritermc.operations.ResolvedResourceOperations
import com.typewritermc.operations.ResourceClonePreparation
import com.typewritermc.operations.ResourceLayoutPreparation
import com.typewritermc.operations.ResourceOperationContribution
import com.typewritermc.operations.ResourceOperationDefinition
import com.typewritermc.operations.ResourceOperationId
import com.typewritermc.operations.ResourceRelationPreparation
import com.typewritermc.operations.UnavailableAuthoredValue
import com.typewritermc.operations.UnfinishedOperationInput
import com.typewritermc.operations.asClosedUse
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.services.libs.utils.rethrowExceptional
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeTemplate
import kotlinx.coroutines.CancellationException
import skirout.editor.v1.action.EditorAction
import java.util.UUID

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
    val origin: com.typewritermc.discovery.ProviderOrigin,
    cause: Throwable,
) : IllegalStateException("Resource operation availability failed for ${origin.owner.localIdentity}", cause)

/**
 * Resolves operation availability and prepares edits against the panel confirmed saved observation plus its overlay.
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
        views.capture().use { lease ->
            if (lease.root.catalog.generation != expectedCatalog) throw OperationCatalogChanged(lease.root.catalog.generation)
            val baseline = lease.operationObservation(confirmedObservation, upserts, removals)
            resolve(invocation, baseline, CapturedAuthoringReads(AuthoredReadView.Original(baseline)))
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
            val catalog = baseline.catalog.operations
            val operation = catalog.requireAuthoring(capability)
            val applicable = invocation.applicableIn(baseline, edit.capturedReads)
            val definition =
                applicable.definitions.firstOrNull { definition ->
                    (definition.action as? EditorAction.AuthoringWrapper)
                        ?.value
                        ?.capability
                        ?.value == capability.value
                }
            val available = definition?.evaluateFor(invocation, baseline, edit.capturedReads)
            if (available?.availability != OperationAvailability.Enabled) {
                return OperationPreparationResult.Unavailable(
                    (available?.availability as? OperationAvailability.Disabled)?.reason
                        ?: "This operation does not apply to the captured selection",
                )
            }
            validateOrigin(invocation, baseline, edit.capturedReads)
            operation.input.schema?.let { schema ->
                when (val checked = schema.complete(input ?: DataValue.Unfilled)) {
                    is CompletenessResult.Unfinished -> return OperationPreparationResult.NeedsInput(
                        input,
                        emptyList(),
                        checked.locations.map { it.path },
                    )

                    is CompletenessResult.Invalid -> return OperationPreparationResult.Invalid(checked.problems)

                    is CompletenessResult.Complete -> Unit
                }
            }
            val session = RuntimeOperationPreparation(invocation, choices, edit, baseline)
            try {
                operation.prepare(invocation.targets, input, session)
                OperationPreparationResult.Preview(
                    edit.finish(),
                    session.confirmation(operation.descriptor.presentation.confirmation),
                    session.selection,
                )
            } catch (needed: NeedsChoices) {
                OperationPreparationResult.NeedsInput(input, needed.requests)
            } catch (unfinished: UnfinishedOperationInput) {
                OperationPreparationResult.NeedsInput(input, emptyList(), unfinished.paths)
            } catch (missing: UnavailableAuthoredValue) {
                OperationPreparationResult.Invalid(missing.locations.map { ValueProblem(it, "required_authored_value_missing") })
            } catch (failure: Exception) {
                failure.rethrowExceptional()
                OperationPreparationResult.Failed(failure)
            }
        }

    private data class ApplicableOperations(
        val definitions: List<ResourceOperationDefinition>,
        val primaryContributions: List<ResourceOperationContribution>,
    )

    private fun OperationInvocation.applicableIn(
        view: AuthoringView,
        reads: CapturedAuthoringReads,
    ): ApplicableOperations {
        val catalog = view.catalog.operations
        val targets =
            this.targets.map { id ->
                requireNotNull(view.resources[id]) { "The operation target is unavailable" }
            }
        this.targets.forEach { id ->
            reads.observeInput(InputIdentity.Existence(id))
            reads.observeInput(InputIdentity.Form(ValueLocation(id, ValuePath())))
        }
        val contributions =
            targets.map { record ->
                catalog.contributions.filter { matches(record, it.target, view) }
            }
        val covered =
            contributions
                .map { rows -> rows.flatMap { it.operations }.toSet() }
                .reduce(Set<ResourceOperationId>::intersect)
        return ApplicableOperations(
            definitions =
                catalog.definitions.filter { definition ->
                    definition.id in covered && matches(targets, definition.targets, view)
                },
            primaryContributions = if (targets.size == 1) contributions.single().filter { it.primary != null } else emptyList(),
        )
    }

    private fun ResourceOperationDefinition.evaluateFor(
        invocation: OperationInvocation,
        view: AuthoringView,
        reads: CapturedAuthoringReads,
    ): ResolvedResourceOperation? {
        val action = this.action as? EditorAction.AuthoringWrapper
        val provider =
            action?.let {
                view.catalog.operations.requireAuthoring(CapabilityId(it.value.capability.value))
            }
        val targets = invocation.targets.map(view.resources::getValue)
        if (provider != null && !matches(targets, provider.descriptor.targets, view)) return null
        val availability =
            if (provider == null) {
                OperationAvailability.Enabled
            } else {
                try {
                    val value =
                        provider.builtin?.let { builtin ->
                            BuiltinOperationAvailability(view, reads).availability(builtin, invocation.targets)
                        } ?: provider.availability(invocation.targets, reads)
                    val health = reads.health()
                    check(health.failures.isEmpty() && health.incomplete.isEmpty()) {
                        "Operation availability reads did not produce complete evidence: $health"
                    }
                    value
                } catch (failure: Exception) {
                    failure.rethrowExceptional()
                    throw OperationResolutionFailure(provider.origin, failure)
                }
            }
        return if (availability == OperationAvailability.Hidden) {
            null
        } else {
            ResolvedResourceOperation(this, availability)
        }
    }

    private fun resolve(
        invocation: OperationInvocation,
        view: AuthoringView,
        reads: CapturedAuthoringReads,
    ): ResolvedResourceOperations {
        val applicable = invocation.applicableIn(view, reads)
        val items =
            applicable.definitions
                .mapNotNull { definition ->
                    val callbackReads = CapturedAuthoringReads(AuthoredReadView.Original(view))
                    definition.evaluateFor(invocation, view, callbackReads)
                }.sortedWith(
                    compareBy(
                        { it.definition.presentation.group.ordinal },
                        { it.definition.presentation.order },
                        { it.definition.id.capability.value },
                    ),
                )
        val primary = applicable.primaryIn(items, view)
        val health = reads.health()
        check(health.failures.isEmpty() && health.incomplete.isEmpty()) {
            "Operation availability reads did not produce complete evidence"
        }
        return ResolvedResourceOperations(items, primary)
    }

    private fun ApplicableOperations.primaryIn(
        items: List<ResolvedResourceOperation>,
        view: AuthoringView,
    ): ResourceOperationId? {
        val maximal =
            primaryContributions
                .filter { candidate ->
                    primaryContributions.none { other ->
                        other.target.definition != candidate.target.definition &&
                            view.catalog.checked.isNominalSubtype(other.target.definition, candidate.target.definition)
                    }
                }.mapNotNull { it.primary }
                .distinct()
        require(maximal.size <= 1) { "Resource operations have conflicting primary nominations" }
        return maximal.singleOrNull()?.takeIf { id -> items.any { it.definition.id == id } }
    }

    private fun matches(
        records: List<AuthoringRecord>,
        selector: OperationTargets,
        view: AuthoringView,
    ): Boolean =
        when (selector) {
            is OperationTargets.Single -> records.size == 1 && records.all { matches(it, selector.type, view) }
            is OperationTargets.Selection -> records.isNotEmpty() && records.all { matches(it, selector.type, view) }
            OperationTargets.ContributedSingle -> records.size == 1
            OperationTargets.ContributedSelection -> records.isNotEmpty()
        }

    private fun matches(
        record: AuthoringRecord,
        target: TypeTemplate.Named,
        view: AuthoringView,
    ): Boolean =
        when (val actual = record.configuration) {
            is TypeSelection.Complete -> {
                view.catalog.checked.isReadableAs(actual.use, target.asClosedUse())
            }

            is TypeSelection.Pending -> {
                target.arguments.isEmpty() &&
                    view.catalog.checked.isNominalSubtype(actual.definition, target.definition)
            }
        }

    private fun validateOrigin(
        invocation: OperationInvocation,
        baseline: AuthoringView,
        reads: CapturedAuthoringReads,
    ) {
        invocation.origin.occurrences.forEach { occurrence ->
            require(baseline.links[occurrence.id] == occurrence) { "The captured resource occurrence changed" }
            reads.observeInput(InputIdentity.Value(occurrence.id.location))
            reads.observeInput(InputIdentity.Incoming(occurrence.source, null))
            reads.observeInput(InputIdentity.Incoming(occurrence.target.resource, null))
        }
    }
}

internal class RuntimeOperationPreparation(
    override val invocation: OperationInvocation,
    override val choices: PreparationChoices,
    private val edit: WorkingViewEditContext,
    baseline: AuthoringView,
) : OperationPreparation,
    EditContext by edit {
    override val identities: OperationIdentities =
        object : OperationIdentities {
            override fun resource(key: String) = ResourceId(identity("resource", key))

            override fun item(key: String) = ItemId(identity("item", key))

            private fun identity(
                kind: String,
                key: String,
            ) = UUID.nameUUIDFromBytes("${invocation.invocationId}:$kind:$key".toByteArray()).toString()
        }
    override val relations: ResourceRelationPreparation = OperationRelationPreparation(edit, baseline)
    override val layouts: ResourceLayoutPreparation = OperationLayoutPreparation(edit, baseline)
    override val cloner: ResourceClonePreparation = OperationClonePreparation(edit, baseline)

    override suspend fun deleteSelection(ids: List<ResourceId>) = edit.deleteAll(ids)

    var selection: List<ResourceId>? = null
        private set
    private val confirmations = mutableListOf<OperationConfirmation>()

    override fun selectAfterStaging(ids: List<ResourceId>) {
        require(ids.all { it in edit.session.resources }) { "The result selection contains an absent resource" }
        selection = ids.distinct()
    }

    override fun confirm(confirmation: OperationConfirmation) {
        confirmations += confirmation
    }

    fun confirmation(declared: OperationConfirmation?): OperationConfirmation? {
        val all = (listOfNotNull(declared) + confirmations).distinct()
        return when (all.size) {
            0 -> null
            1 -> all.single()
            else -> OperationConfirmation(all.first().title, all.joinToString("\n\n") { it.message }, all.first().confirmationLabel)
        }
    }
}
