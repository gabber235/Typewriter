package com.typewritermc.realm.authoring

import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.CounterpartChoice
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.types.ResourceId

internal interface RelationOperations {
    suspend fun connect(
        intent: ConnectIntent,
        context: EditContext,
    ): RelationEditResult

    suspend fun disconnect(
        occurrence: LinkOccurrenceId,
        context: EditContext,
    ): RelationEditResult

    suspend fun delete(
        resource: ResourceId,
        context: EditContext,
    ): RelationEditResult
}

internal sealed interface RelationEditResult {
    data object Prepared : RelationEditResult

    data class ChooseCounterpart(
        val locations: List<ValueLocation>,
        val creatableAt: List<ValueLocation>,
    ) : RelationEditResult

    data class Rejected(
        val problems: List<ValueProblem>,
    ) : RelationEditResult
}

internal data class DeletionPlan(
    val resources: Set<ResourceId>,
    val repairs: List<com.typewritermc.authoring.EditIntent>,
)

/** Records relation decisions in the same ordered edit as ordinary value changes. */
internal object DefaultRelationOperations : RelationOperations {
    override suspend fun connect(
        intent: ConnectIntent,
        context: EditContext,
    ): RelationEditResult {
        val choice = intent.counterpart
        if (intent.source.source == intent.target && choice is CounterpartChoice.Existing) {
            val counterpart = choice.occurrence
            if (counterpart.id == intent.source.id) {
                return RelationEditResult.Rejected(
                    listOf(ValueProblem(intent.source.id.location, "self_link_requires_distinct_occurrences")),
                )
            }
        }
        context.connect(intent)
        return RelationEditResult.Prepared
    }

    override suspend fun disconnect(
        occurrence: LinkOccurrenceId,
        context: EditContext,
    ): RelationEditResult {
        context.disconnect(occurrence)
        return RelationEditResult.Prepared
    }

    override suspend fun delete(
        resource: ResourceId,
        context: EditContext,
    ): RelationEditResult {
        context.delete(resource)
        return RelationEditResult.Prepared
    }
}

internal suspend fun LinkOccurrenceId.disconnectUsing(
    owner: RelationOperations,
    context: EditContext,
): RelationEditResult = owner.disconnect(this, context)
