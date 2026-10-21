package com.typewritermc.realm.authoring

import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.record
import com.typewritermc.checking.InputIdentity
import com.typewritermc.operations.OperationPreparation
import com.typewritermc.operations.PreparationChoice
import com.typewritermc.operations.PreparationChoices
import com.typewritermc.realm.repository.CounterpartBinding
import com.typewritermc.realm.repository.ResourceValueMapper
import com.typewritermc.realm.repository.valueAt
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ResolvedRepresentation
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse

/** Prepares ownership transfers and links through the same session used by menus and drops. */
internal class OperationRelationPreparation(
    private val relations: RelationReads,
) {
    /**
     * Transfers ownership of [subjects] to [destination] through the ownership each holds today, and returns the
     * subjects that changed owner. Subjects already owned by the destination are left as they are. A subject with an
     * inverse field is relinked from that field; a subject without one is released by its old owner and taken into
     * one of the destination's own owning slots.
     */
    context(operation: OperationPreparation)
    suspend fun move(
        subjects: List<ResourceId>,
        destination: ResourceId,
    ): List<ResourceId> {
        val inverse = mutableListOf<LinkOccurrence>()
        val ownerSide = mutableListOf<Pair<LinkOccurrence, LinkOccurrence>>()
        val moved = mutableListOf<ResourceId>()
        subjects.forEach { subject ->
            val membership =
                relations.ownership(subject, operation.invocation.origin)
                    ?: error("The resource does not have one exact owner occurrence")
            if (membership.source == destination) return@forEach
            val sources = relations.ownerSources(subject, membership, destination, operation.identities::item)
            require(sources.isNotEmpty()) { "The destination does not accept this resource" }
            val source =
                sources.singleOrNull() ?: operation.choices.require(
                    PreparationChoice.Source("owner-source:$subject:$destination", "Choose owning reference", sources),
                )
            relations.observe(source)
            moved += subject
            if (source.source == subject) inverse += source else ownerSide += membership to source
        }
        assignCounterparts(inverse, destination, operation.choices).forEach { operation.connect(it) }
        ownerSide.forEach { (membership, source) ->
            val subject = membership.target.resource
            operation.disconnect(membership.id)
            operation.connect(
                ConnectIntent(source = source, target = subject, counterpart = counterpartFor(source, subject, operation.choices)),
            )
        }
        return moved
    }

    /** Links each of [subjects] with [target], the dragged side first. Already linked subjects are left unchanged. */
    context(operation: OperationPreparation)
    suspend fun link(
        subjects: List<ResourceId>,
        target: ResourceId,
    ) {
        val additions =
            subjects.mapNotNull { subject ->
                val candidates = relations.linkSources(subject, target, operation.identities::item)
                require(candidates.isNotEmpty()) { "The resource has no compatible reference to the target" }
                if (candidates.any { relations.links[it.id] == it }) return@mapNotNull null
                val selected =
                    if (candidates.size == 1) {
                        candidates.single()
                    } else {
                        operation.choices.require(
                            PreparationChoice.Source("link-source:$subject:$target", "Choose source reference", candidates),
                        )
                    }
                relations.observe(selected)
                selected
            }
        // Each linked resource offers its own counterpart slots, so assignments are independent per linked resource.
        additions
            .groupBy { it.target.resource }
            .flatMap { (linked, sources) -> assignCounterparts(sources, linked, operation.choices) }
            .forEach { operation.connect(it) }
    }

    /** Removes every non owning link between each of [subjects] and [target], whichever side holds it. */
    context(operation: OperationPreparation)
    suspend fun unlink(
        subjects: List<ResourceId>,
        target: ResourceId,
    ) {
        subjects.forEach { subject ->
            relations.linksBetween(subject, target).forEach { occurrence ->
                // Disconnecting one side also clears its inverse, which then no longer appears among the links.
                if (relations.links[occurrence.id] != occurrence) return@forEach
                relations.observe(occurrence)
                operation.disconnect(occurrence.id)
            }
        }
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
                "counterpart:${LinkOccurrenceId.serializer.toJsonCode(source.id)}:$target",
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

        fun slot(choice: CounterpartChoice?): LinkOccurrenceId? = (choice as? CounterpartChoice.ExistingWrapper)?.value?.id
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
                if (valid.size == 1) {
                    valid.single()
                } else {
                    answers.require(
                        PreparationChoice.Counterpart(
                            "counterpart:${LinkOccurrenceId.serializer.toJsonCode(source.id)}:$target",
                            "Choose inverse counterpart",
                            source,
                            valid.filterNotNull(),
                        ),
                    )
                }
            slot(choice)?.let(reserved::add)
            ConnectIntent(source = source, target = target, counterpart = choice)
        }
    }

    private fun counterpartCandidates(
        source: LinkOccurrence,
        target: ResourceId,
    ): List<CounterpartChoice?> {
        val catalog = relations.catalog
        val relation = relations.contract(source.id.endpoint)
        val opposite = if (relation.first.id == source.id.endpoint) relation.second.id else relation.first.id
        val record = relations.resources[target] ?: error("The relation destination is unavailable")
        val binding = ResourceValueMapper.counterpartBinding(opposite, target, record, catalog.checked)
        if (binding is CounterpartBinding.Missing) return listOf(null)
        if (binding is CounterpartBinding.Collection) return listOf(null)
        val locations =
            when (binding) {
                is CounterpartBinding.Scalar -> listOf(binding.location)
                else -> ResourceValueMapper.declaredLocations(opposite, target, record, catalog.checked)
            }
        val current = relations.links
        val candidates: MutableList<CounterpartChoice> =
            locations
                .filter { at ->
                    val old = current[LinkOccurrenceId(endpoint = opposite, location = at)]
                    (old?.target?.resource == source.source && old.target.opposite == source.id.location.path) ||
                        record.valueAt(at.path)?.unfilled() != false
                }.mapTo(mutableListOf()) { at ->
                    CounterpartChoice.ExistingWrapper(
                        LinkOccurrence(
                            id = LinkOccurrenceId(endpoint = opposite, location = at),
                            source = target,
                            target = LinkTarget(resource = source.source, opposite = source.id.location.path),
                        ),
                    )
                }
        if (binding is CounterpartBinding.ExplicitChoice) {
            val evidence = ResourceValueMapper.declaredEvidence(opposite, target, record, catalog.checked)
            evidence.memberships.forEach { containing ->
                relations.reads.observeInput(InputIdentity.Membership(containing))
                val collectionType = record.authoredTypeAt(containing.path, catalog.checked) ?: return@forEach
                val checked = catalog.checked.resolve(collectionType) as? Resolution.Ready ?: return@forEach
                val sequence = checked.value.schema.representation as? ResolvedRepresentation.SequenceWrapper ?: return@forEach
                val itemType = sequence.value.item as? TypeUse.NamedWrapper ?: return@forEach
                val itemSchema = catalog.checked.resolve(itemType) as? Resolution.Ready ?: return@forEach
                if (itemSchema.value.schema.representation !is ResolvedRepresentation.RecordWrapper) return@forEach
                val prepared =
                    DefaultInitializationRuntime(catalog.checked, catalog.nativeBindings).prepareNow(
                        ValuePreparationRequest(
                            catalog = catalog.generation,
                            target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(itemType.value)),
                            suppliedValue = null,
                        ),
                    )
                val materialized = (prepared.content as? PreparedContent.RecordWrapper)?.record ?: return@forEach
                if (ResourceValueMapper.declaredLocations(opposite, target, materialized, catalog.checked).size == 1) {
                    candidates += CounterpartChoice.createNew(containing = containing, prepared = prepared)
                }
            }
        }
        require(candidates.isNotEmpty()) { "No compatible inverse counterpart has capacity" }
        return candidates
    }
}
