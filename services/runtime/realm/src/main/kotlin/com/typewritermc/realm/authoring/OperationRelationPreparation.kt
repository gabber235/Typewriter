package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.item
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationConfirmation
import com.typewritermc.operations.OperationOrigin
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.PreparationChoice
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.operations.RelationAssignment
import com.typewritermc.operations.ResourceRelationPreparation
import com.typewritermc.realm.repository.CounterpartBinding
import com.typewritermc.realm.repository.DeclaredLinkEvidence
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointId
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.ResolvedRepresentation
import com.typewritermc.types.ownsResources

/** Checks exact endpoints and prepares links through the same session used by menu and drag. */
internal class OperationRelationPreparation(
    private val edit: WorkingViewEditContext,
    private val baseline: AuthoringView,
) : ResourceRelationPreparation {
    context(operation: OperationPreparation)
    override suspend fun requireMove(
        subjects: List<ResourceDraft>,
        destination: ResourceId,
        origin: OperationOrigin,
        answers: PreparationChoices,
    ): RelationAssignment {
        val selectedSources =
            subjects.mapNotNull { subject ->
                val captured = origin.occurrences.singleOrNull { it.target.resource == subject.id }
                val membership =
                    captured ?: ResourceValueMapper.discover(edit.session.resources).singleOrNull { occurrence ->
                        val relation = contract(occurrence.id.endpoint)
                        occurrence.target.resource == subject.id && occurrence.id.endpoint == relation.first.id &&
                            relation.ownsResources
                    } ?: error("The resource does not have one exact owner occurrence")
                require(ResourceValueMapper.discover(edit.session.resources).contains(membership)) { "The source ownership changed" }
                observe(membership)
                if (membership.source == destination) return@mapNotNull null
                val inverse = membership.target.opposite ?: error("The source ownership has no exact inverse")
                val relation = contract(membership.id.endpoint)
                val endpoint = if (relation.first.id == membership.id.endpoint) relation.second.id else relation.first.id
                val source =
                    LinkOccurrence(
                        LinkOccurrenceId(endpoint, ValueLocation(subject.id, inverse)),
                        subject.id,
                        LinkTarget(membership.source, membership.id.location.path),
                    )
                require(accepts(source, destination)) { "The destination does not accept this resource" }
                source
            }
        val intents = assignCounterparts(selectedSources, destination, answers)
        return RelationAssignment { intents.forEach { operation.connect(it) } }
    }

    context(operation: OperationPreparation)
    override suspend fun linkWith(
        targets: List<ResourceId>,
        target: ResourceId,
        choices: PreparationChoices,
    ) {
        val sourcesToAdd = mutableListOf<LinkOccurrence>()
        val removals = mutableListOf<LinkOccurrenceId>()
        targets.forEach { id ->
            val candidates = sources(id, target, operation)
            require(candidates.isNotEmpty()) { "The resource has no compatible reference to the target" }
            val selected =
                if (candidates.size == 1) {
                    candidates.single()
                } else {
                    choices.require(PreparationChoice.Source("link-source:$id:$target", "Choose source reference", candidates))
                }
            observe(selected)
            val existing = ResourceValueMapper.discover(edit.session.resources).singleOrNull { it.id == selected.id }
            if (existing?.target?.resource == selected.target.resource) {
                removals += existing.id
            } else {
                sourcesToAdd += selected
            }
        }
        // Each linked resource offers its own counterpart slots, so assignments are independent per linked resource.
        val additions =
            sourcesToAdd
                .groupBy { it.target.resource }
                .flatMap { (linked, sources) -> assignCounterparts(sources, linked, choices) }
        if (additions.isNotEmpty() && removals.isNotEmpty()) {
            operation.confirm(
                OperationConfirmation(
                    "Change these links?",
                    "This operation adds links for some resources and removes links for others.",
                    "Change links",
                ),
            )
        }
        removals.forEach { operation.disconnect(it) }
        additions.forEach { operation.connect(it) }
    }

    context(operation: OperationPreparation)
    override suspend fun linkWithDuplicate(
        original: ResourceId,
        copy: ResourceId,
        choices: PreparationChoices,
    ) {
        val candidates =
            sources(original, copy, operation).filter { source ->
                val actual =
                    edit.session.resources
                        .getValue(original)
                        .configuration as? TypeSelection.Complete
                val copied =
                    edit.session.resources
                        .getValue(copy)
                        .configuration as? TypeSelection.Complete
                actual?.use == copied?.use && ResourceValueMapper.discover(edit.session.resources).none { it.id == source.id }
            }
        require(candidates.isNotEmpty()) { "No compatible reference has capacity for a copy" }
        val source =
            if (candidates.size == 1) {
                candidates.single()
            } else {
                choices.require(PreparationChoice.Source("clone-link:$original", "Choose reference to the copy", candidates))
            }
        val linked = source.target.resource
        operation.connect(ConnectIntent(source, linked, counterpartFor(source, linked, choices)))
    }

    /**
     * Link occurrences that would connect [subject] and [target] through each non owning relation.
     *
     * Bindings live at each relation's first endpoint. The dragged side (the subject) holds the link first; the target
     * holds it only when the subject declares no binding for that relation, so a tag dropped onto a book is written to
     * the book's tags while a tag dropped onto a tag gains the target as a parent.
     */
    private fun sources(
        subject: ResourceId,
        target: ResourceId,
        operation: OperationPreparation,
    ): List<LinkOccurrence> {
        val current = ResourceValueMapper.discover(edit.session.resources).associateBy { it.id }
        return baseline.catalog.relations
            .filterNot { it.ownsResources }
            .flatMap { relation ->
                val endpoint = relation.first.id
                listOf(subject to target, target to subject).firstNotNullOfOrNull { (holder, linked) ->
                    val evidence = holder.bindingEvidence(endpoint)
                    if (evidence.isEmpty()) null else holder.occurrencesLinking(linked, endpoint, evidence, current, operation)
                } ?: emptyList()
            }.distinctBy { it.id }
    }

    /** Bindings this resource declares for [endpoint]; the evidence is recorded as read before anyone inspects it. */
    private fun ResourceId.bindingEvidence(endpoint: EndpointId): DeclaredLinkEvidence =
        ResourceValueMapper.declaredEvidence(endpoint, this, recordOf(this), baseline.catalog.checked).also { evidence ->
            evidence.memberships.forEach { edit.capturedReads.observeInput(InputIdentity.Membership(it)) }
            evidence.forms.forEach { edit.capturedReads.observeInput(InputIdentity.Form(it)) }
        }

    /** Occurrences on this resource's [endpoint] bindings that already link [linked] or have room to link it. */
    private fun ResourceId.occurrencesLinking(
        linked: ResourceId,
        endpoint: EndpointId,
        evidence: DeclaredLinkEvidence,
        current: Map<LinkOccurrenceId, LinkOccurrence>,
        operation: OperationPreparation,
    ): List<LinkOccurrence> {
        val record = recordOf(this)
        val locations = evidence.values.toMutableList()
        val collection =
            ResourceValueMapper.counterpartBinding(endpoint, this, record, baseline.catalog.checked) as? CounterpartBinding.Collection
        if (collection != null && locations.none { current[LinkOccurrenceId(endpoint, it)]?.target?.resource == linked }) {
            locations += collection.location.item(operation.identities.item("source:$this:$endpoint:$linked"))
        }
        return locations.mapNotNull { at ->
            val present = current[LinkOccurrenceId(endpoint, at)]
            val value = record.valueAt(at.path)
            if (present != null && present.target.resource != linked) return@mapNotNull null
            if (present == null && value != null && !value.unfilled()) return@mapNotNull null
            val occurrence = present ?: LinkOccurrence(LinkOccurrenceId(endpoint, at), this, LinkTarget(linked, null))
            occurrence.takeIf { accepts(it, linked) }
        }
    }

    private fun recordOf(id: ResourceId) = edit.session.resources[id] ?: error("The linked resource is unavailable")

    private fun accepts(
        source: LinkOccurrence,
        target: ResourceId,
    ): Boolean {
        val sourceRecord = edit.session.resources[source.source] ?: return false
        val destination = edit.session.resources[target] ?: return false
        val actual = (destination.configuration as? TypeSelection.Complete)?.use ?: return false
        val expected =
            ResourceValueMapper.expectedTarget(source, sourceRecord, baseline.catalog.checked) ?: run {
                val type = sourceRecord.authoredTypeAt(source.id.location.path, baseline.catalog.checked) ?: return false
                val checked = baseline.catalog.checked.resolve(type) as? Resolution.Ready ?: return false
                (checked.value.schema.representation as? ResolvedRepresentation.Link)?.target ?: return false
            }
        return baseline.catalog.checked.isReadableAs(actual, expected)
    }

    internal fun counterpartFor(
        source: LinkOccurrence,
        target: ResourceId,
        answers: PreparationChoices,
    ): CounterpartChoice? {
        val candidates = counterpartCandidates(source, target)
        if (candidates.size == 1) return candidates.single()
        return answers.require(
            PreparationChoice.Counterpart(
                "counterpart:${source.id}:$target",
                "Choose inverse counterpart",
                source,
                candidates.filterNotNull(),
            ),
        )
    }

    private fun assignCounterparts(
        sources: List<LinkOccurrence>,
        target: ResourceId,
        answers: PreparationChoices,
    ): List<ConnectIntent> {
        val candidates = sources.map { counterpartCandidates(it, target) }

        fun slot(choice: CounterpartChoice?): LinkOccurrenceId? = (choice as? CounterpartChoice.Existing)?.occurrence?.id
        var attempts = 0

        fun feasible(
            index: Int,
            reserved: Set<LinkOccurrenceId>,
        ): Boolean {
            require(++attempts <= 100_000) { "The counterpart assignment exceeds the operation planning budget" }
            if (index == sources.size) return true
            return candidates[index].any { choice ->
                val key = slot(choice)
                (key == null || key !in reserved) && feasible(index + 1, if (key == null) reserved else reserved + key)
            }
        }
        require(feasible(0, emptySet())) { "The destination cannot accept the complete resource selection" }
        val reserved = mutableSetOf<LinkOccurrenceId>()
        return sources.mapIndexed { index, source ->
            val valid =
                candidates[index].filter { candidate ->
                    val key = slot(candidate)
                    (key == null || key !in reserved) && feasible(index + 1, if (key == null) reserved else reserved + key)
                }
            val choice =
                if (valid.size ==
                    1
                ) {
                    valid.single()
                } else {
                    answers.require(
                        PreparationChoice.Counterpart(
                            "counterpart:${source.id}:$target",
                            "Choose inverse counterpart",
                            source,
                            valid.filterNotNull(),
                        ),
                    )
                }
            slot(choice)?.let(reserved::add)
            ConnectIntent(source, target, choice)
        }
    }

    private fun counterpartCandidates(
        source: LinkOccurrence,
        target: ResourceId,
    ): List<CounterpartChoice?> {
        val relation = contract(source.id.endpoint)
        val opposite = if (relation.first.id == source.id.endpoint) relation.second.id else relation.first.id
        val record = edit.session.resources[target] ?: error("The relation destination is unavailable")
        val binding = ResourceValueMapper.counterpartBinding(opposite, target, record, baseline.catalog.checked)
        if (binding is CounterpartBinding.Missing) return listOf(null)
        if (binding is CounterpartBinding.Collection) return listOf(null)
        val locations =
            when (binding) {
                is CounterpartBinding.Scalar -> listOf(binding.location)
                else -> ResourceValueMapper.declaredLocations(opposite, target, record, baseline.catalog.checked)
            }
        val current = ResourceValueMapper.discover(edit.session.resources).associateBy { it.id }
        val candidates: MutableList<CounterpartChoice> =
            locations
                .filter { at ->
                    val old = current[LinkOccurrenceId(opposite, at)]
                    (old?.target?.resource == source.source && old.target.opposite == source.id.location.path) ||
                        record.valueAt(at.path)?.unfilled() != false
                }.mapTo(
                    mutableListOf(),
                ) { at ->
                    CounterpartChoice.Existing(
                        LinkOccurrence(LinkOccurrenceId(opposite, at), target, LinkTarget(source.source, source.id.location.path)),
                    )
                }
        if (binding is CounterpartBinding.ExplicitChoice) {
            val evidence = ResourceValueMapper.declaredEvidence(opposite, target, record, baseline.catalog.checked)
            evidence.memberships.forEach { containing ->
                edit.capturedReads.observeInput(InputIdentity.Membership(containing))
                val collectionType = record.authoredTypeAt(containing.path, baseline.catalog.checked) ?: return@forEach
                val checked = baseline.catalog.checked.resolve(collectionType) as? Resolution.Ready ?: return@forEach
                val sequence = checked.value.schema.representation as? ResolvedRepresentation.Sequence ?: return@forEach
                val itemType = sequence.item as? TypeUse.Named ?: return@forEach
                val itemSchema = baseline.catalog.checked.resolve(itemType) as? Resolution.Ready ?: return@forEach
                if (itemSchema.value.schema.representation !is ResolvedRepresentation.Record) return@forEach
                val prepared =
                    DefaultInitializationRuntime(baseline.catalog.checked, baseline.catalog.nativeBindings).prepareNow(
                        InitializationRequest(
                            baseline.catalog.generation,
                            PreparationTarget.Record(TypeSelection.Complete(itemType)),
                            null,
                        ),
                    )
                val materialized = (prepared.content as? PreparedContent.Record)?.record ?: return@forEach
                if (ResourceValueMapper.declaredLocations(opposite, target, materialized, baseline.catalog.checked).size == 1) {
                    candidates += CounterpartChoice.New(containing, prepared)
                }
            }
        }
        require(candidates.isNotEmpty()) { "No compatible inverse counterpart has capacity" }
        return candidates
    }

    private fun contract(endpoint: EndpointId) = baseline.catalog.relations.single { it.first.id == endpoint || it.second.id == endpoint }

    private fun observe(source: LinkOccurrence) {
        edit.capturedReads.observeInput(InputIdentity.Value(source.id.location))
        edit.capturedReads.observeInput(InputIdentity.Incoming(source.source, null))
        edit.capturedReads.observeInput(InputIdentity.Incoming(source.target.resource, null))
    }
}

private fun DeclaredLinkEvidence.isEmpty(): Boolean = values.isEmpty() && memberships.isEmpty() && forms.isEmpty()

private fun DataValue.unfilled(): Boolean =
    when (this) {
        DataValue.Unfilled, DataValue.Null -> true
        is DataValue.Named -> payload.unfilled()
        else -> false
    }
