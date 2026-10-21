package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

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
