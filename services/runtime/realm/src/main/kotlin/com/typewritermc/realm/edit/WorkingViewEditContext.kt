package com.typewritermc.realm.edit

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.CheckedWriteResult
import com.typewritermc.authoring.EditContext
import com.typewritermc.authoring.EditablePath
import com.typewritermc.realm.authoring.AuthoredReadView
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.CapturedAuthoringReads
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.immutableListCopy
import com.typewritermc.types.toResourceId
import com.typewritermc.types.toSkir
import skirout.editor.v1.authoring.ConnectIntent
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.authoring.LinkOccurrenceId
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.diagnostic.ValueProblem
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.ValueLocation
import java.util.UUID
import com.typewritermc.types.ResourceId as AuthorResourceId

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
        id: AuthorResourceId,
        record: AuthoringRecord,
    ) = append(EditIntent.createCreateResource(id = id.toSkir(), record = record))

    override suspend fun delete(id: AuthorResourceId) {
        val resource = id.toSkir()
        if (resource !in session.resources && resource in baseline.resources) return
        append(EditIntent.createDeleteResource(id = resource))
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
        append(EditIntent.createSetValue(at = path.location, value = binding.encode(value)))
    }

    override suspend fun <V> clear(path: EditablePath<V>) {
        require(path.binding.readContext === readContext) { "The editable path belongs to another operation observation" }
        append(EditIntent.createSetValue(at = path.location, value = DataValue.UNFILLED))
    }

    override suspend fun insert(
        path: BoundCollectionPath,
        after: ItemId?,
        value: DataValue,
    ): ItemId {
        val id =
            ItemId(
                value =
                    UUID
                        .nameUUIDFromBytes(
                            "$invocationId:insert:${ValueLocation.serializer.toJsonCode(path.location)}:${allocated++}".toByteArray(),
                        ).toString(),
            )
        append(EditIntent.createInsert(at = path.location, after = after, item = ListItem(id = id, value = value)))
        return id
    }

    override suspend fun remove(
        path: BoundCollectionPath,
        item: ItemId,
    ) = append(EditIntent.createRemove(at = path.location, item = item))

    override suspend fun move(
        path: BoundCollectionPath,
        item: ItemId,
        after: ItemId?,
    ) = append(EditIntent.createMove(at = path.location, item = item, after = after))

    override suspend fun connect(intent: ConnectIntent) = append(EditIntent.ConnectRelationWrapper(intent))

    override suspend fun disconnect(occurrence: LinkOccurrenceId) = append(EditIntent.DisconnectRelationWrapper(occurrence))

    override suspend fun retag(
        at: ValueLocation,
        type: NamedTypeUse,
    ) = append(EditIntent.createRetag(at = at, type = type))

    override suspend fun checkedSet(
        path: ValueLocation,
        value: DataValue,
    ): CheckedWriteResult =
        try {
            append(EditIntent.createSetValue(at = path, value = value))
            CheckedWriteResult.Applied
        } catch (failure: IllegalArgumentException) {
            CheckedWriteResult.Rejected(listOf(ValueProblem(location = path, code = "operation_write_rejected")))
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
