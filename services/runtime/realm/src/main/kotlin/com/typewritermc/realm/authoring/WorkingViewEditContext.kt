package com.typewritermc.realm.authoring

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.ConnectIntent
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.EditIntent
import com.typewritermc.authoring.EditablePath
import com.typewritermc.authoring.LinkOccurrenceId
import com.typewritermc.authoring.PreparedEdit
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValueProblem
import com.typewritermc.realm.checking.CapturedAuthoringReads
import com.typewritermc.realm.repository.AuthoringPlanningSession
import com.typewritermc.realm.repository.requiredExpectations
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.immutableListCopy
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import java.util.UUID

/** A request owned edit context. Reads see prior writes and expectations witness its working baseline. */
internal class WorkingViewEditContext(
    private val baseline: AuthoringView,
    private val invocationId: String,
    private val working: AuthoredReadView.Working = AuthoredReadView.Working(baseline),
    val capturedReads: CapturedAuthoringReads = CapturedAuthoringReads(working),
) : EditContext,
    AuthoredReads by capturedReads {
    val session = AuthoringPlanningSession(baseline, invocationId)
    private var allocated = 0L
    private var failedWrite: Throwable? = null

    private fun append(intent: EditIntent) {
        try {
            session.append(intent)
            working.replace(session.resources)
        } catch (failure: Exception) {
            failedWrite = failure
            throw failure
        }
    }

    override suspend fun create(
        id: ResourceId,
        record: AuthoringRecord,
    ) = append(EditIntent.CreateResource(id, record))

    override suspend fun delete(id: ResourceId) {
        if (id !in session.resources && id in baseline.resources) return
        append(EditIntent.DeleteResource(id))
    }

    fun deleteAll(ids: List<ResourceId>) {
        try {
            session.deleteAll(ids.filter { it in session.resources || it !in baseline.resources })
            working.replace(session.resources)
        } catch (failure: Exception) {
            failedWrite = failure
            throw failure
        }
    }

    override suspend fun <V> set(
        path: EditablePath<V>,
        value: V,
    ) {
        require(path.binding.readContext === readContext) { "The editable path belongs to another operation observation" }
        val checked =
            when (val result = baseline.catalog.checked.resolve(path.expected)) {
                is Resolution.Ready -> result.value
                is Resolution.Invalid -> error(result.diagnostics.joinToString())
            }

        @Suppress("UNCHECKED_CAST")
        val binding = baseline.catalog.nativeBindings.bind(checked) as NativeBinding<V>
        append(EditIntent.SetValue(path.location, binding.encode(value)))
    }

    override suspend fun <V> clear(path: EditablePath<V>) {
        require(path.binding.readContext === readContext) { "The editable path belongs to another operation observation" }
        append(EditIntent.SetValue(path.location, DataValue.UNFILLED))
    }

    override suspend fun insert(
        path: BoundCollectionPath,
        after: ItemId?,
        value: DataValue,
    ): ItemId {
        val id = ItemId(value = UUID.nameUUIDFromBytes("$invocationId:insert:${path.location}:${allocated++}".toByteArray()).toString())
        append(EditIntent.Insert(path.location, after, ListItem(id = id, value = value)))
        return id
    }

    override suspend fun remove(
        path: BoundCollectionPath,
        item: ItemId,
    ) = append(EditIntent.Remove(path.location, item))

    override suspend fun move(
        path: BoundCollectionPath,
        item: ItemId,
        after: ItemId?,
    ) = append(EditIntent.Move(path.location, item, after))

    override suspend fun connect(intent: ConnectIntent) = append(EditIntent.ConnectRelation(intent))

    override suspend fun disconnect(occurrence: LinkOccurrenceId) = append(EditIntent.DisconnectRelation(occurrence))

    override suspend fun retag(
        at: ValueLocation,
        type: NamedTypeUse,
    ) = append(EditIntent.Retag(at, type))

    override suspend fun checkedSet(
        path: ValueLocation,
        value: DataValue,
    ): CheckedWriteResult =
        try {
            append(EditIntent.SetValue(path, value))
            CheckedWriteResult.Applied
        } catch (failure: IllegalArgumentException) {
            CheckedWriteResult.Rejected(listOf(ValueProblem(path, "operation_write_rejected")))
        }

    fun finish(): PreparedEdit {
        check(failedWrite == null) { "The operation contains a rejected write: ${failedWrite?.message}" }
        val health = capturedReads.health()
        check(health.failures.isEmpty() && health.incomplete.isEmpty()) { "Operation reads did not produce complete evidence: $health" }
        val (edit, plan) = session.finish()
        val required =
            baseline.values.requiredExpectations(
                edit,
                baseline.resources,
                baseline.catalog.relations.mapTo(linkedSetOf()) { it.id },
                plan,
            )
        return edit.copy(expectations = (capturedReads.observations() + required).distinct().immutableListCopy())
    }
}
