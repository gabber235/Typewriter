package com.typewritermc.realm.routes

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutation
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.StoredElement
import com.typewritermc.library.ref
import com.typewritermc.realm.repository.BatchId
import com.typewritermc.realm.repository.CreateElementsCommand
import com.typewritermc.realm.repository.CueTimingUpdate
import com.typewritermc.realm.repository.DeleteElementsCommand
import com.typewritermc.realm.repository.DuplicateElementsCommand
import com.typewritermc.realm.repository.ElementBatchResult
import com.typewritermc.realm.repository.ElementCreation
import com.typewritermc.realm.repository.ElementDeletion
import com.typewritermc.realm.repository.ElementDuplication
import com.typewritermc.realm.repository.ElementPageMove
import com.typewritermc.realm.repository.ElementRepository
import com.typewritermc.realm.repository.ElementValueUpdate
import com.typewritermc.realm.repository.GraphElementMove
import com.typewritermc.realm.repository.GraphElementResize
import com.typewritermc.realm.repository.MoveElementsToPagesCommand
import com.typewritermc.realm.repository.MoveGraphElementsCommand
import com.typewritermc.realm.repository.ResizeGraphElementsCommand
import com.typewritermc.realm.repository.UpdateCueTimingsCommand
import com.typewritermc.realm.repository.UpdateElementValuesCommand
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toResourceId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.skir.SkirDataValueCodec
import com.typewritermc.types.skir.SkirTypeCodec
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.path.DataPath
import skirout.editor.v1.path.DataPathSegment
import skirout.library.v2.authoring.CreateElementsResponse
import skirout.library.v2.authoring.DeleteElementsResponse
import skirout.library.v2.authoring.DuplicateElementsResponse
import skirout.library.v2.authoring.ElementBatchConflict
import skirout.library.v2.authoring.MoveElementsToPagesResponse
import skirout.library.v2.authoring.MoveGraphElementsResponse
import skirout.library.v2.authoring.PageDiagnostic
import skirout.library.v2.authoring.ResizeGraphElementsResponse
import skirout.library.v2.authoring.UpdateCueTimingsResponse
import skirout.library.v2.authoring.UpdateElementValuesResponse
import skirout.library.v2.authoring.ElementPlacement as WirePlacement
import skirout.library.v2.authoring.ElementValueMutation as WireMutation

internal class ElementBatchRoutes(
    private val elements: ElementRepository,
    private val typeGraphs: () -> Map<ElementTypeId, TypeGraph>,
    private val contracts: LibraryContracts,
    private val onCommitted: (ElementBatchResult.Success, Boolean) -> Unit = { _, _ -> },
    private val decomposer: ReferenceDecomposer = ReferenceDecomposer(),
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            unary(contracts.createElements) { call ->
                val graphs = typeGraphs()
                invalidRequest {
                    elements.createElements(
                        request {
                            CreateElementsCommand(
                                BatchId(call.request.batchId),
                                call.request.elements.map { element ->
                                    val type = ElementTypeId(DeclaredTypeId.parse(element.elementType))
                                    val graph =
                                        requireNotNull(graphs[type]) {
                                            "Element type is unavailable: ${element.elementType}"
                                        }
                                    ElementCreation(
                                        element.page.toPageId().ref(),
                                        StoredElement(
                                            id = element.id.toElementInstanceId(),
                                            revision = ElementRevision(1),
                                            elementType = type,
                                            schemaRevision = element.schemaRevision,
                                            name = element.name,
                                            value =
                                                decomposer.decompose(
                                                    graph,
                                                    SkirDataValueCodec.decode(element.value).getOrThrow(),
                                                ),
                                            placement = element.placement.toDomain(),
                                        ),
                                    )
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true)
                    .toCreateResponse()
            }
            unary(contracts.updateElementValues) { call ->
                invalidRequest {
                    elements.updateElementValues(
                        request {
                            UpdateElementValuesCommand(
                                BatchId(call.request.batchId),
                                call.request.updates.map { update ->
                                    ElementValueUpdate(
                                        update.id.toElementInstanceId(),
                                        update.expectedRevision,
                                        update.name,
                                        update.mutations.map(WireMutation::toDomain),
                                    )
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true).toUpdateResponse()
            }
            unary(contracts.moveElementsToPages) { call ->
                invalidRequest {
                    elements.moveElementsToPages(
                        request {
                            MoveElementsToPagesCommand(
                                BatchId(call.request.batchId),
                                call.request.moves.map {
                                    ElementPageMove(
                                        it.id.toElementInstanceId(),
                                        it.expectedRevision,
                                        it.page.toPageId().ref(),
                                        it.placement.toDomain(),
                                    )
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true).toPageMoveResponse()
            }
            unary(contracts.moveGraphElements) { call ->
                invalidRequest {
                    elements.moveGraphElements(
                        request {
                            MoveGraphElementsCommand(
                                BatchId(call.request.batchId),
                                call.request.moves.map {
                                    GraphElementMove(it.id.toElementInstanceId(), it.expectedRevision, it.x, it.y)
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = false).toGraphMoveResponse()
            }
            unary(contracts.resizeGraphElements) { call ->
                invalidRequest {
                    elements.resizeGraphElements(
                        request {
                            ResizeGraphElementsCommand(
                                BatchId(call.request.batchId),
                                call.request.resizes.map {
                                    GraphElementResize(it.id.toElementInstanceId(), it.expectedRevision, it.width, it.height)
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = false).toResizeResponse()
            }
            unary(contracts.updateCueTimings) { call ->
                invalidRequest {
                    elements.updateCueTimings(
                        request {
                            UpdateCueTimingsCommand(
                                BatchId(call.request.batchId),
                                call.request.updates.map {
                                    CueTimingUpdate(it.id.toElementInstanceId(), it.expectedRevision, it.placement.toDomain())
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true).toTimingResponse()
            }
            unary(contracts.deleteElements) { call ->
                invalidRequest {
                    elements.deleteElements(
                        request {
                            DeleteElementsCommand(
                                BatchId(call.request.batchId),
                                call.request.deletions.map {
                                    ElementDeletion(it.id.toElementInstanceId(), it.expectedRevision)
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true).toDeleteResponse()
            }
            unary(contracts.duplicateElements) { call ->
                invalidRequest {
                    elements.duplicateElements(
                        request {
                            DuplicateElementsCommand(
                                BatchId(call.request.batchId),
                                call.request.elements.map { duplicate ->
                                    ElementDuplication(
                                        sourceId = duplicate.sourceId.toElementInstanceId(),
                                        expectedRevision = duplicate.expectedRevision,
                                        newId = duplicate.newId.toElementInstanceId(),
                                        page = duplicate.page.toPageId().ref(),
                                        name = duplicate.name,
                                        placement = duplicate.placement.toDomain(),
                                        referenceRewrites =
                                            duplicate.referenceRewrites.associate {
                                                it.source.toResourceId() to it.target.toResourceId()
                                            },
                                    )
                                },
                            )
                        },
                    )
                }.notify(affectsCompilation = true).toDuplicateResponse()
            }
        }

    private fun ElementBatchResult.notify(affectsCompilation: Boolean): ElementBatchResult =
        also { result ->
            if (result is ElementBatchResult.Success) onCommitted(result, affectsCompilation)
        }

    private suspend fun invalidRequest(block: suspend () -> ElementBatchResult): ElementBatchResult =
        try {
            block()
        } catch (error: InvalidRequestException) {
            ElementBatchResult.ValidationFailure(
                listOf(
                    com.typewritermc.realm.repository
                        .ElementBatchDiagnostic(error.cause?.message ?: "invalid_request"),
                ),
            )
        }

    private fun <T> request(block: () -> T): T =
        try {
            block()
        } catch (error: IllegalArgumentException) {
            throw InvalidRequestException(error)
        }
}

private class InvalidRequestException(
    cause: IllegalArgumentException,
) : RuntimeException(cause)

private fun WireMutation.toDomain(): ElementValueMutation =
    when (this) {
        is WireMutation.SetValueWrapper -> {
            ElementValueMutation.SetValue(value.path.toDomain(), SkirDataValueCodec.decode(value.value).getOrThrow())
        }

        is WireMutation.InsertListItemsWrapper -> {
            ElementValueMutation.InsertListItems(
                value.path.toDomain(),
                value.index,
                value.values.map { SkirDataValueCodec.decode(it).getOrThrow() },
            )
        }

        is WireMutation.RemoveListItemsWrapper -> {
            ElementValueMutation.RemoveListItems(value.path.toDomain(), value.index, value.count)
        }

        is WireMutation.ReorderListItemsWrapper -> {
            ElementValueMutation.ReorderListItems(
                value.path.toDomain(),
                value.sourceIndex,
                value.count,
                value.destinationIndex,
            )
        }

        is WireMutation.DuplicateListItemsWrapper -> {
            ElementValueMutation.DuplicateListItems(
                value.path.toDomain(),
                value.sourceIndex,
                value.count,
                value.destinationIndex,
            )
        }

        is WireMutation.PutMapEntriesWrapper -> {
            ElementValueMutation.PutMapEntries(
                value.path.toDomain(),
                value.entries.map {
                    DataMapEntry(
                        SkirDataValueCodec.decode(it.key).getOrThrow(),
                        SkirDataValueCodec.decode(it.value).getOrThrow(),
                    )
                },
            )
        }

        is WireMutation.RemoveMapEntriesWrapper -> {
            ElementValueMutation.RemoveMapEntries(
                value.path.toDomain(),
                value.keys.map { SkirDataValueCodec.decode(it).getOrThrow() },
            )
        }

        is WireMutation.ReplaceConcreteTypeWrapper -> {
            ElementValueMutation.ReplaceConcreteType(
                value.path.toDomain(),
                SkirTypeCodec.decode(value.concreteType).getOrThrow(),
                SkirDataValueCodec.decode(value.value).getOrThrow(),
            )
        }

        is WireMutation.Unknown -> {
            error("Unknown element value mutation")
        }
    }

private fun DataPath.toDomain(): ElementValuePath =
    ElementValuePath(
        segments.map {
            when (it) {
                is DataPathSegment.FieldWrapper -> {
                    ElementValuePathSegment.Field(it.value.fieldName)
                }

                is DataPathSegment.IndexWrapper -> {
                    ElementValuePathSegment.Index(it.value.index)
                }

                is DataPathSegment.MapKeyWrapper -> {
                    ElementValuePathSegment.MapKey(SkirDataValueCodec.decode(it.value.key).getOrThrow())
                }

                is DataPathSegment.Unknown -> {
                    error("Unknown data path segment")
                }
            }
        },
    )

private fun WirePlacement.toDomain(): ElementPlacement =
    when (this) {
        is WirePlacement.GraphV1Wrapper -> ElementPlacement.Graph(value.x, value.y, value.width, value.height)
        is WirePlacement.TimelineEntryV1Wrapper -> ElementPlacement.TimelineEntry(value.trackIndex)
        is WirePlacement.TimelineSegmentV1Wrapper -> ElementPlacement.TimelineSegment(value.startFrame, value.endFrame)
        is WirePlacement.TimelineKeyframeV1Wrapper -> ElementPlacement.TimelineKeyframe(value.frame)
        is WirePlacement.Unknown -> error("Unknown element placement")
    }

private data class WireBatchResult(
    val batchId: String? = null,
    val affectedPages: List<skirout.kernel.v1.record_id.RecordId> = emptyList(),
    val conflicts: List<ElementBatchConflict> = emptyList(),
    val diagnostics: List<PageDiagnostic> = emptyList(),
)

private fun ElementBatchResult.toWireResult(): WireBatchResult =
    when (this) {
        is ElementBatchResult.Success -> {
            WireBatchResult(batchId.value, affectedPages.map { it.toSkirRecordId() })
        }

        is ElementBatchResult.Conflict -> {
            WireBatchResult(
                conflicts =
                    conflicts.map {
                        ElementBatchConflict(
                            id = it.id.toWireId(),
                            expectedRevision = it.expectedRevision,
                            actualRevision = it.actual?.revision?.value,
                        )
                    },
            )
        }

        is ElementBatchResult.ValidationFailure -> {
            WireBatchResult(
                diagnostics =
                    diagnostics.map {
                        PageDiagnostic(
                            code = it.code,
                            message = it.code,
                            element = it.elementId?.toWireId(),
                            slot = null,
                            target = it.pageId?.toSkirRecordId(),
                        )
                    },
            )
        }
    }

private fun ElementInstanceId.toWireId() =
    com.typewritermc.types
        .ResourceId("element", value.toHexString())
        .toSkirRecordId()

private fun ElementBatchResult.toCreateResponse(): CreateElementsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> CreateElementsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> CreateElementsResponse.ConflictWrapper(it.conflicts)
            else -> CreateElementsResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toUpdateResponse(): UpdateElementValuesResponse =
    toWireResult().let {
        when {
            it.batchId != null -> UpdateElementValuesResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> UpdateElementValuesResponse.ConflictWrapper(it.conflicts)
            else -> UpdateElementValuesResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toPageMoveResponse(): MoveElementsToPagesResponse =
    toWireResult().let {
        when {
            it.batchId != null -> MoveElementsToPagesResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> MoveElementsToPagesResponse.ConflictWrapper(it.conflicts)
            else -> MoveElementsToPagesResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toGraphMoveResponse(): MoveGraphElementsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> MoveGraphElementsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> MoveGraphElementsResponse.ConflictWrapper(it.conflicts)
            else -> MoveGraphElementsResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toResizeResponse(): ResizeGraphElementsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> ResizeGraphElementsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> ResizeGraphElementsResponse.ConflictWrapper(it.conflicts)
            else -> ResizeGraphElementsResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toTimingResponse(): UpdateCueTimingsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> UpdateCueTimingsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> UpdateCueTimingsResponse.ConflictWrapper(it.conflicts)
            else -> UpdateCueTimingsResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toDeleteResponse(): DeleteElementsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> DeleteElementsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> DeleteElementsResponse.ConflictWrapper(it.conflicts)
            else -> DeleteElementsResponse.InvalidWrapper(it.diagnostics)
        }
    }

private fun ElementBatchResult.toDuplicateResponse(): DuplicateElementsResponse =
    toWireResult().let {
        when {
            it.batchId != null -> DuplicateElementsResponse.createSuccess(batchId = it.batchId, affectedPages = it.affectedPages)
            it.conflicts.isNotEmpty() -> DuplicateElementsResponse.ConflictWrapper(it.conflicts)
            else -> DuplicateElementsResponse.InvalidWrapper(it.diagnostics)
        }
    }
