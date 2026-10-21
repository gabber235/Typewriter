package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import skirout.editor.v1.authoring.LinkOccurrence
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

/** An edit proposal carrying its catalog generation, observed preconditions, and ordered intents for later acceptance. */
data class PreparedEdit(
    val catalog: CatalogGeneration,
    val expectations: List<EditExpectation>,
    val intents: List<EditIntent>,
)

sealed interface EditIntent {
    data class CreateResource(
        val id: ResourceId,
        val record: AuthoringRecord,
    ) : EditIntent

    data class DeleteResource(
        val id: ResourceId,
    ) : EditIntent

    data class SetValue(
        val at: ValueLocation,
        val value: DataValue,
    ) : EditIntent

    data class Insert(
        val at: ValueLocation,
        val after: ItemId?,
        val item: ListItem,
    ) : EditIntent

    data class Remove(
        val at: ValueLocation,
        val item: ItemId,
    ) : EditIntent

    data class Move(
        val at: ValueLocation,
        val item: ItemId,
        val after: ItemId?,
    ) : EditIntent

    data class ConnectRelation(
        val intent: ConnectIntent,
    ) : EditIntent

    data class DisconnectRelation(
        val occurrence: LinkOccurrenceId,
    ) : EditIntent

    data class Retag(
        val at: ValueLocation,
        val type: NamedTypeUse,
    ) : EditIntent

    data class ConfigureResource(
        val resource: ResourceId,
        val configuration: TypeSelection,
    ) : EditIntent
}

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

@GeneratedSdkApi
fun <Value> DraftBinding.exactEditablePath(
    relative: ValuePath,
    expected: TypeUse,
): EditablePath<Value> = EditablePath(this, relative, expected)

sealed interface CounterpartChoice {
    data class Existing(
        val occurrence: LinkOccurrence,
    ) : CounterpartChoice

    data class New(
        val containing: ValueLocation,
        val prepared: PreparedValue,
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
        type: NamedTypeUse,
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
