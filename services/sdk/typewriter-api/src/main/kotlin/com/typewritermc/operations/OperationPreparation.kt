package com.typewritermc.operations

import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId

data class OperationOrigin(
    val container: ResourceId? = null,
    val occurrences: List<LinkOccurrence> = emptyList(),
)

data class OperationInvocation(
    val invocationId: String,
    val targets: List<ResourceId>,
    val origin: OperationOrigin = OperationOrigin(),
) {
    init {
        require(invocationId.isNotBlank())
        require(targets.isNotEmpty() && targets.distinct().size == targets.size)
    }
}

sealed interface PreparationChoice {
    val id: String
    val label: String

    data class Source(
        override val id: String,
        override val label: String,
        val candidates: List<LinkOccurrence>,
    ) : PreparationChoice

    data class Counterpart(
        override val id: String,
        override val label: String,
        val source: LinkOccurrence,
        val candidates: List<CounterpartChoice>,
    ) : PreparationChoice
}

sealed interface PreparationChoiceAnswer {
    data class Source(
        val occurrence: LinkOccurrence,
    ) : PreparationChoiceAnswer

    data class Counterpart(
        val counterpart: CounterpartChoice,
    ) : PreparationChoiceAnswer
}

data class PreparationChoices(
    val answers: Map<String, PreparationChoiceAnswer> = emptyMap(),
) {
    fun require(choice: PreparationChoice.Source): LinkOccurrence =
        (answers[choice.id] as? PreparationChoiceAnswer.Source)?.occurrence?.takeIf { it in choice.candidates }
            ?: throw NeedsChoices(listOf(choice))

    fun require(choice: PreparationChoice.Counterpart): CounterpartChoice =
        (answers[choice.id] as? PreparationChoiceAnswer.Counterpart)?.counterpart?.takeIf { answer ->
            choice.candidates.any { candidate ->
                when {
                    candidate is CounterpartChoice.Existing && answer is CounterpartChoice.Existing -> {
                        candidate == answer
                    }

                    candidate is CounterpartChoice.New && answer is CounterpartChoice.New -> {
                        candidate.containing == answer.containing &&
                            (candidate.prepared.content as? com.typewritermc.authoring.PreparedContent.Record)?.record?.configuration ==
                            (answer.prepared.content as? com.typewritermc.authoring.PreparedContent.Record)?.record?.configuration &&
                            answer.prepared.content is com.typewritermc.authoring.PreparedContent.Record
                    }

                    else -> {
                        false
                    }
                }
            }
        }
            ?: throw NeedsChoices(listOf(choice))
}

/** Aborts one pure attempt. The owner discards its intents and returns choices. */
class NeedsChoices(
    val requests: List<PreparationChoice>,
) : RuntimeException("Operation input requires a choice")

interface OperationIdentities {
    fun resource(key: String): ResourceId

    fun item(key: String): com.typewritermc.authoring.ItemId
}

data class PlacementAnchor(
    val x: Double,
    val y: Double,
)

data class CloneResult(
    val selectedCopies: List<ResourceId>,
)

fun interface RelationAssignment {
    context(operation: OperationPreparation)
    suspend fun apply()
}

fun interface PlacementPreparation {
    context(operation: OperationPreparation)
    suspend fun apply()
}

interface ResourceRelationPreparation {
    context(operation: OperationPreparation)
    suspend fun requireMove(
        subjects: List<ResourceDraft>,
        destination: ResourceId,
        origin: OperationOrigin,
        answers: PreparationChoices,
    ): RelationAssignment

    context(operation: OperationPreparation)
    suspend fun linkWith(
        targets: List<ResourceId>,
        target: ResourceId,
        choices: PreparationChoices,
    )

    context(operation: OperationPreparation)
    suspend fun linkWithDuplicate(
        original: ResourceId,
        copy: ResourceId,
        choices: PreparationChoices,
    )
}

interface ResourceLayoutPreparation {
    context(operation: OperationPreparation)
    suspend fun prepareMove(
        subjects: List<ResourceDraft>,
        destination: ResourceId,
        anchor: PlacementAnchor?,
    ): PlacementPreparation
}

interface ResourceClonePreparation {
    context(operation: OperationPreparation)
    suspend fun duplicateOwned(roots: List<ResourceId>): CloneResult
}

/**
 * One pure attempt owns its captured working baseline, tentative edits, choices and proposed UI effects.
 * Reads include local staged changes. Writes remain private until the caller validates and stages the exact preview.
 * Implementations must not flush unrelated drafts or commit while preparing. Callbacks must not retain this context.
 */
interface OperationPreparation : EditContext {
    val invocation: OperationInvocation
    val choices: PreparationChoices
    val identities: OperationIdentities
    val relations: ResourceRelationPreparation
    val layouts: ResourceLayoutPreparation
    val cloner: ResourceClonePreparation

    fun selectAfterStaging(ids: List<ResourceId>)

    fun confirm(confirmation: OperationConfirmation)

    suspend fun deleteSelection(ids: List<ResourceId>)
}
