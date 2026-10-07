package com.typewritermc.authoring

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeUse
import kotlinx.serialization.Serializable

data class PreparedEdit(
    val catalog: CatalogGeneration,
    val expectations: List<EditExpectation>,
    val intents: List<EditIntent>,
)

@Serializable
sealed interface EditIntent {
    @Serializable
    data class CreateResource(
        val id: ResourceId,
        val record: AuthoringRecord,
    ) : EditIntent

    @Serializable
    data class DeleteResource(
        val id: ResourceId,
    ) : EditIntent

    @Serializable
    data class SetValue(
        val at: ValueLocation,
        val value: DataValue,
    ) : EditIntent

    @Serializable
    data class Insert(
        val at: ValueLocation,
        val after: ItemId?,
        val item: ListItem,
    ) : EditIntent

    @Serializable
    data class Remove(
        val at: ValueLocation,
        val item: ItemId,
    ) : EditIntent

    @Serializable
    data class Move(
        val at: ValueLocation,
        val item: ItemId,
        val after: ItemId?,
    ) : EditIntent

    @Serializable
    data class ConnectRelation(
        val intent: ConnectIntent,
    ) : EditIntent

    @Serializable
    data class DisconnectRelation(
        val occurrence: LinkOccurrenceId,
    ) : EditIntent

    @Serializable
    data class Retag(
        val at: ValueLocation,
        val type: TypeUse.Named,
    ) : EditIntent

    @Serializable
    data class ConfigureResource(
        val resource: ResourceId,
        val configuration: TypeSelection,
    ) : EditIntent
}

@Serializable
data class ConnectIntent(
    val source: LinkOccurrence,
    val target: ResourceId,
    val counterpart: CounterpartChoice?,
)

class EditablePath<Value> internal constructor(
    val binding: DraftBinding,
    val relative: ValuePath,
    val expected: TypeUse,
) {
    val location: ValueLocation = binding.location.append(relative)
}

@RequiresOptIn(
    level = RequiresOptIn.Level.ERROR,
    message = "Generated draft editors are the public typed editing surface.",
)
@Retention(AnnotationRetention.BINARY)
@Target(AnnotationTarget.FUNCTION)
annotation class GeneratedEditApi

@GeneratedEditApi
fun <Value> DraftBinding.exactEditablePath(
    relative: ValuePath,
    expected: TypeUse,
): EditablePath<Value> = EditablePath(this, relative, expected)

@Serializable
sealed interface CounterpartChoice {
    @Serializable
    data class Existing(
        val occurrence: LinkOccurrence,
    ) : CounterpartChoice

    @Serializable
    data class New(
        val containing: ValueLocation,
        val prepared: PreparedCreation,
    ) : CounterpartChoice
}

interface EditContext : AuthoredReads {
    suspend fun create(
        id: ResourceId,
        record: AuthoringRecord,
    )

    suspend fun delete(id: ResourceId)

    suspend fun <V> set(
        path: EditablePath<V>,
        value: V,
    )

    suspend fun <V> clear(path: EditablePath<V>)

    suspend fun insert(
        path: BoundCollectionPath,
        after: ItemId?,
        value: DataValue,
    ): ItemId

    suspend fun remove(
        path: BoundCollectionPath,
        item: ItemId,
    )

    suspend fun move(
        path: BoundCollectionPath,
        item: ItemId,
        after: ItemId?,
    )

    suspend fun connect(intent: ConnectIntent)

    suspend fun disconnect(occurrence: LinkOccurrenceId)

    suspend fun retag(
        at: ValueLocation,
        type: TypeUse.Named,
    )

    suspend fun checkedSet(
        path: ValueLocation,
        value: DataValue,
    ): CheckedWriteResult
}

sealed interface CheckedWriteResult {
    data object Applied : CheckedWriteResult

    data class Rejected(
        val problems: List<ValueProblem>,
    ) : CheckedWriteResult
}

sealed interface PreparedEditResult {
    val initializationFindings: List<LocatedInitializationDiagnostic>

    data class Prepared(
        val edit: PreparedEdit,
        override val initializationFindings: List<LocatedInitializationDiagnostic> = emptyList(),
    ) : PreparedEditResult

    data class NeedsInput(
        val locations: List<ValueLocation>,
        override val initializationFindings: List<LocatedInitializationDiagnostic> = emptyList(),
    ) : PreparedEditResult

    data class Rejected(
        val problems: List<ValueProblem>,
        override val initializationFindings: List<LocatedInitializationDiagnostic> = emptyList(),
    ) : PreparedEditResult
}

sealed interface CommitResult {
    data object Committed : CommitResult

    data class Conflict(
        val values: List<ExpectationConflict>,
    ) : CommitResult

    data class Rejected(
        val problems: List<ValueProblem>,
    ) : CommitResult

    data class CatalogChanged(
        val actual: CatalogGeneration,
    ) : CommitResult
}
