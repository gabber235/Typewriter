package com.typewritermc.operations

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.ResourceDraft
import com.typewritermc.authoring.record
import com.typewritermc.authoring.requireValid
import com.typewritermc.dsl.TypewriterDsl
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requireValid
import skirout.editor.v1.authoring.CounterpartChoice
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.operation.OperationAvailability
import skirout.editor.v1.resource_operations.PreparationChoice
import skirout.editor.v1.resource_operations.PreparationChoiceAnswer
import skirout.editor.v1.resource_operations.PreparationChoiceId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

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

/**
 * The answers an editor gave to the preparation choices of an earlier attempt. [require] returns the answer to one
 * choice when it names one of its candidates, and otherwise aborts the attempt with that choice.
 */
data class PreparationChoices(
    val answers: List<PreparationChoiceAnswer> = emptyList(),
) {
    fun require(choice: PreparationChoice.Source): LinkOccurrence =
        answers
            .filterIsInstance<PreparationChoiceAnswer.SourceWrapper>()
            .singleOrNull { it.value.choiceId == choice.choiceId }
            ?.value
            ?.occurrence
            ?.takeIf { answer -> choice.candidates.any { it.occurrence == answer } }
            ?: throw NeedsChoices(listOf(PreparationChoice.SourceWrapper(choice)))

    fun require(choice: PreparationChoice.Counterpart): CounterpartChoice =
        answers
            .filterIsInstance<PreparationChoiceAnswer.CounterpartWrapper>()
            .singleOrNull { it.value.choiceId == choice.choiceId }
            ?.value
            ?.counterpart
            ?.takeIf { answer -> choice.candidates.any { it.counterpart.accepts(answer) } }
            ?: throw NeedsChoices(listOf(PreparationChoice.CounterpartWrapper(choice)))
}

/** An existing counterpart must be the offered one; a new one must create a record of the offered type at its location. */
private fun CounterpartChoice.accepts(answer: CounterpartChoice): Boolean =
    when {
        this is CounterpartChoice.ExistingWrapper && answer is CounterpartChoice.ExistingWrapper -> {
            this == answer
        }

        this is CounterpartChoice.NewWrapper && answer is CounterpartChoice.NewWrapper -> {
            value.containing == answer.value.containing &&
                (value.prepared.content as? PreparedContent.RecordWrapper)?.record?.configuration ==
                (answer.value.prepared.content as? PreparedContent.RecordWrapper)?.record?.configuration &&
                answer.value.prepared.content is PreparedContent.RecordWrapper
        }

        else -> {
            false
        }
    }

/** Checks the identity, occurrence and counterpart of an answer an editor sent. */
fun PreparationChoiceAnswer.requireValid(): PreparationChoiceAnswer =
    when (this) {
        is PreparationChoiceAnswer.SourceWrapper -> {
            require(value.choiceId.value.isNotBlank()) { "Operation choices require an identity." }
            apply { value.occurrence.requireValid() }
        }

        is PreparationChoiceAnswer.CounterpartWrapper -> {
            require(value.choiceId.value.isNotBlank()) { "Operation choices require an identity." }
            PreparationChoiceAnswer.createCounterpart(choiceId = value.choiceId, counterpart = value.counterpart.requireValid())
        }

        else -> {
            throw IllegalArgumentException("Unknown operation choice answer.")
        }
    }

/** The identity of the choice this answer belongs to. */
val PreparationChoiceAnswer.choiceId: PreparationChoiceId
    get() =
        when (this) {
            is PreparationChoiceAnswer.SourceWrapper -> value.choiceId
            is PreparationChoiceAnswer.CounterpartWrapper -> value.choiceId
            else -> throw IllegalArgumentException("Unknown operation choice answer.")
        }

/** Aborts one pure attempt. The owner discards its intents and returns choices. */
class NeedsChoices(
    val requests: List<PreparationChoice>,
) : RuntimeException("Operation input requires a choice")

interface OperationIdentities {
    fun resource(key: String): ResourceId

    fun item(key: String): skirout.editor.v1.type_catalog.ItemId
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
    val diagnostic: skirout.editor.v1.expression.EvaluationDiagnostic,
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
        OperationAvailability.ENABLED
    } else {
        OperationAvailability.DisabledWrapper(
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
