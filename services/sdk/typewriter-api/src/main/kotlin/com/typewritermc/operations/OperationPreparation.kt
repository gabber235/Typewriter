package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.LinkOccurrence
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.dsl.TypewriterDsl
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

/**
 * What operation callbacks read: authored values and graph facts of the invocation's working graph. Reads are
 * recorded as observations of the attempt.
 */
interface OperationReads :
    AuthoredReads,
    AuthoringGraphFacts {
    /** [id] bound as a draft of any resource, whatever its type. Operations on every resource read their subjects so. */
    fun resourceDraft(id: ResourceId): ResourceDraft
}

/**
 * One pure attempt owns its captured working baseline, tentative edits, choices and proposed UI effects.
 * Reads include local staged changes. Writes remain private until the caller validates and stages the exact preview.
 * Implementations must not flush unrelated drafts or commit while preparing. Callbacks must not retain this context.
 */
interface OperationPreparation :
    OperationReads,
    EditContext,
    AuthoringGraphEdits {
    val invocation: OperationInvocation
    val choices: PreparationChoices
    val identities: OperationIdentities

    /** Replaces the editor selection with [ids] once the preview is staged. */
    fun selectAfterStaging(ids: List<ResourceId>)
}

/**
 * Availability and candidate callbacks read [subjects] through authored reads and graph facts, never edits.
 * [drafts] binds each subject as the operation's draft type on first use.
 */
@TypewriterDsl
class OperationReadScope<D : ResourceDraft>(
    val subjects: List<ResourceId>,
    drafts: () -> List<D>,
    reads: OperationReads,
) : OperationReads by reads {
    val drafts: List<D> by lazy(drafts)
}

/** Preparation reads like [OperationReadScope] and stages edits, including high level graph edits. */
@TypewriterDsl
class OperationPrepareScope<D : ResourceDraft, I>(
    val subjects: List<ResourceId>,
    drafts: () -> List<D>,
    val input: I,
    preparation: OperationPreparation,
) : OperationPreparation by preparation {
    val drafts: List<D> by lazy(drafts)
}

class UnavailableAuthoredValue(
    val locations: List<ValueLocation>,
) : IllegalStateException("Required authored values are missing")

/** The operation input value is not yet complete at [paths], relative to the input root. */
class UnfinishedOperationInput(
    val paths: List<ValuePath>,
) : IllegalStateException("Operation input is unfinished")

class FailedAuthoredValue(
    val diagnostic: com.typewritermc.expression.EvaluationDiagnostic,
) : IllegalStateException(diagnostic.toString())

/** Enabled when every value is authored, disabled with the missing locations otherwise. */
fun authored(values: Iterable<Availability<*>>): OperationAvailability {
    val missing = mutableListOf<ValueLocation>()
    values.forEach { value ->
        when (value) {
            is Availability.Available -> Unit
            is Availability.Unavailable -> missing += value.locations
            is Availability.Failed -> throw FailedAuthoredValue(value.diagnostic)
        }
    }
    return if (missing.isEmpty()) {
        OperationAvailability.Enabled
    } else {
        OperationAvailability.Disabled(
            "Required authored values are missing: ${missing.joinToString()}",
        )
    }
}

fun <T> requireAuthored(value: Availability<T>): T =
    when (value) {
        is Availability.Available -> value.value
        is Availability.Unavailable -> throw UnavailableAuthoredValue(value.locations)
        is Availability.Failed -> throw FailedAuthoredValue(value.diagnostic)
    }
