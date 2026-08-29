package com.typewritermc.realm.repository

import com.surrealdb.Array
import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementRevision
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutationResult
import com.typewritermc.elements.ElementValueMutator
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredElementValue
import com.typewritermc.elements.StoredReference
import com.typewritermc.library.PageId
import com.typewritermc.library.pageId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.RealmOutbox
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.records.ElementRecordParser
import com.typewritermc.realm.repository.records.StoredPageElements
import com.typewritermc.realm.repository.utils.DataValueDatabaseCodec
import com.typewritermc.realm.repository.utils.advanceCollaborationRevision
import com.typewritermc.realm.repository.utils.databaseValue
import com.typewritermc.realm.repository.utils.expectedTypeDatabaseValue
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.types.TypeGraph
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

class SurrealElementRepository(
    private val database: Surreal,
    private val typeGraph: () -> Map<ElementTypeId, TypeGraph>,
    private val valueMutator: ElementValueMutator = ElementValueMutator(),
    private val outbox: RealmOutbox = SurrealRealmOutbox(database),
    private val encodeEvents: (PageInvalidation) -> List<OutboxEvent> = { emptyList() },
) : ElementRepository {
    override suspend fun getPageElements(pageId: PageId): List<StoredElement> =
        database.inTransaction { transaction -> loadPage(transaction, pageId).elements }

    override suspend fun createElements(command: CreateElementsCommand): ElementBatchResult =
        executeBatch(command.batchId, "create_elements", command, affectsCompilation = true) batch@{ transaction ->
            val existing = load(transaction, command.elements.map { it.element.id })
            if (existing.elements.isNotEmpty()) {
                return@batch ElementBatchResult.ValidationFailure(
                    existing.elements.map { ElementBatchDiagnostic("element-already-exists", elementId = it.id) },
                )
            }
            val missingPages = missingPages(transaction, command.elements.map { it.page.pageId() })
            if (missingPages.isNotEmpty()) return@batch missingPages.failure()

            command.elements.forEach { creation -> create(transaction, creation.page.pageId(), creation.element) }
            val created = load(transaction, command.elements.map { it.element.id }).elements
            ElementBatchResult.Success(command.batchId, created, command.elements.mapTo(linkedSetOf()) { it.page.pageId() })
        }

    override suspend fun updateElementValues(command: UpdateElementValuesCommand): ElementBatchResult =
        executeBatch(command.batchId, "update_element_values", command, affectsCompilation = true) batch@{ transaction ->
            val current = load(transaction, command.updates.map(ElementValueUpdate::id))
            conflicts(command.updates, current, ElementValueUpdate::id, ElementValueUpdate::expectedRevision)?.let {
                return@batch it
            }
            val graphs = typeGraph()
            val projected =
                command.updates.map { update ->
                    val element = current.elements.single { it.id == update.id }
                    val graph =
                        graphs[element.elementType]
                            ?: return@batch ElementBatchResult.ValidationFailure(
                                listOf(ElementBatchDiagnostic("element-type-unavailable", elementId = update.id)),
                            )
                    when (val result = valueMutator.apply(graph, element.value, update.mutations)) {
                        is ElementValueMutationResult.Success -> {
                            update to result.value
                        }

                        is ElementValueMutationResult.Failure -> {
                            return@batch ElementBatchResult.ValidationFailure(
                                listOf(ElementBatchDiagnostic(result.code, elementId = update.id)),
                            )
                        }
                    }
                }
            projected.forEach { (update, value) ->
                transaction
                    .query(
                        "UPDATE ONLY \$element SET revision += 1, name = \$name, value = \$value;",
                        mapOf(
                            "element" to update.id.surrealId(),
                            "name" to update.name,
                            "value" to DataValueDatabaseCodec.encode(value.valueWithSlots),
                        ),
                    ).take(0)
                replaceReferences(transaction, update.id, value.references)
            }
            success(command.batchId, transaction, command.updates.map(ElementValueUpdate::id), current)
        }

    override suspend fun moveElementsToPages(command: MoveElementsToPagesCommand): ElementBatchResult =
        executeBatch(command.batchId, "move_elements_to_pages", command, affectsCompilation = true) batch@{ transaction ->
            val current = load(transaction, command.moves.map(ElementPageMove::id))
            conflicts(command.moves, current, ElementPageMove::id, ElementPageMove::expectedRevision)?.let {
                return@batch it
            }
            val missingPages = missingPages(transaction, command.moves.map { it.page.pageId() })
            if (missingPages.isNotEmpty()) return@batch missingPages.failure()

            command.moves.forEach { move ->
                transaction
                    .query(
                        "DELETE contains_element WHERE out = \$element; " +
                            "RELATE \$page->\$edge->\$element; " +
                            "UPDATE ONLY \$element SET revision += 1, placement = \$placement;",
                        mapOf(
                            "element" to move.id.surrealId(),
                            "page" to move.page.surrealId(),
                            "edge" to containmentEdgeId(move.page.pageId(), move.id),
                            "placement" to move.placement.databaseValue(),
                        ),
                    ).consumeAll()
            }
            success(command.batchId, transaction, command.moves.map(ElementPageMove::id), current)
        }

    override suspend fun moveGraphElements(command: MoveGraphElementsCommand): ElementBatchResult =
        executeBatch(command.batchId, "move_graph_elements", command, affectsCompilation = false) batch@{ transaction ->
            val current = load(transaction, command.moves.map(GraphElementMove::id))
            conflicts(command.moves, current, GraphElementMove::id, GraphElementMove::expectedRevision)?.let {
                return@batch it
            }
            current.elements.filter { it.placement !is ElementPlacement.Graph }.takeIf(List<*>::isNotEmpty)?.let {
                return@batch it.placementFailure()
            }
            command.moves.forEach { move ->
                transaction
                    .query(
                        "UPDATE ONLY \$element SET revision += 1, placement.x = \$x, placement.y = \$y;",
                        mapOf("element" to move.id.surrealId(), "x" to move.x, "y" to move.y),
                    ).take(0)
            }
            success(command.batchId, transaction, command.moves.map(GraphElementMove::id), current)
        }

    override suspend fun resizeGraphElements(command: ResizeGraphElementsCommand): ElementBatchResult =
        executeBatch(command.batchId, "resize_graph_elements", command, affectsCompilation = false) batch@{ transaction ->
            val current = load(transaction, command.resizes.map(GraphElementResize::id))
            conflicts(command.resizes, current, GraphElementResize::id, GraphElementResize::expectedRevision)?.let {
                return@batch it
            }
            current.elements.filter { it.placement !is ElementPlacement.Graph }.takeIf(List<*>::isNotEmpty)?.let {
                return@batch it.placementFailure()
            }
            command.resizes.forEach { resize ->
                transaction
                    .query(
                        "UPDATE ONLY \$element SET revision += 1, placement.width = \$width, placement.height = \$height;",
                        mapOf(
                            "element" to resize.id.surrealId(),
                            "width" to resize.width,
                            "height" to resize.height,
                        ),
                    ).take(0)
            }
            success(command.batchId, transaction, command.resizes.map(GraphElementResize::id), current)
        }

    override suspend fun updateCueTimings(command: UpdateCueTimingsCommand): ElementBatchResult =
        executeBatch(command.batchId, "update_cue_timings", command, affectsCompilation = true) batch@{ transaction ->
            val current = load(transaction, command.updates.map(CueTimingUpdate::id))
            conflicts(command.updates, current, CueTimingUpdate::id, CueTimingUpdate::expectedRevision)?.let {
                return@batch it
            }
            val mismatches =
                command.updates.filter { update ->
                    val actual = current.elements.single { it.id == update.id }.placement
                    actual::class != update.placement::class || actual is ElementPlacement.Graph
                }
            if (mismatches.isNotEmpty()) {
                return@batch ElementBatchResult.ValidationFailure(
                    mismatches.map { ElementBatchDiagnostic("placement-kind-mismatch", elementId = it.id) },
                )
            }
            command.updates.forEach { update ->
                transaction
                    .query(
                        "UPDATE ONLY \$element SET revision += 1, placement = \$placement;",
                        mapOf("element" to update.id.surrealId(), "placement" to update.placement.databaseValue()),
                    ).take(0)
            }
            success(command.batchId, transaction, command.updates.map(CueTimingUpdate::id), current)
        }

    override suspend fun deleteElements(command: DeleteElementsCommand): ElementBatchResult =
        executeBatch(command.batchId, "delete_elements", command, affectsCompilation = true) batch@{ transaction ->
            val current = load(transaction, command.deletions.map(ElementDeletion::id))
            conflicts(command.deletions, current, ElementDeletion::id, ElementDeletion::expectedRevision)?.let {
                return@batch it
            }
            val affectedPages = current.pageIds() + loadReferringPageIds(transaction, command.deletions.map(ElementDeletion::id))
            command.deletions.forEach { deletion ->
                transaction
                    .query(
                        "DELETE element_reference WHERE in = \$element; " +
                            "DELETE contains_element WHERE out = \$element; " +
                            "DELETE ONLY \$element;",
                        mapOf("element" to deletion.id.surrealId()),
                    ).consumeAll()
            }
            ElementBatchResult.Success(command.batchId, emptyList(), affectedPages)
        }

    override suspend fun duplicateElements(command: DuplicateElementsCommand): ElementBatchResult =
        executeBatch(command.batchId, "duplicate_elements", command, affectsCompilation = true) batch@{ transaction ->
            val current = load(transaction, command.duplications.map(ElementDuplication::sourceId))
            conflicts(
                command.duplications,
                current,
                ElementDuplication::sourceId,
                ElementDuplication::expectedRevision,
            )?.let { return@batch it }
            val destinations = load(transaction, command.duplications.map(ElementDuplication::newId))
            if (destinations.elements.isNotEmpty()) {
                return@batch ElementBatchResult.ValidationFailure(
                    destinations.elements.map { ElementBatchDiagnostic("element-already-exists", elementId = it.id) },
                )
            }
            val missingPages = missingPages(transaction, command.duplications.map { it.page.pageId() })
            if (missingPages.isNotEmpty()) return@batch missingPages.failure()

            command.duplications.forEach { duplication ->
                val source = current.elements.single { it.id == duplication.sourceId }
                val duplicatedValue =
                    source.value.copy(
                        references =
                            source.value.references.map { reference ->
                                reference.copy(target = duplication.referenceRewrites[reference.target] ?: reference.target)
                            },
                    )
                create(
                    transaction,
                    duplication.page.pageId(),
                    source.copy(
                        id = duplication.newId,
                        revision = ElementRevision(1),
                        name = duplication.name,
                        value = duplicatedValue,
                        placement = duplication.placement,
                    ),
                )
            }
            val created = load(transaction, command.duplications.map(ElementDuplication::newId))
            ElementBatchResult.Success(
                command.batchId,
                created.elements,
                command.duplications.mapTo(linkedSetOf()) { it.page.pageId() },
            )
        }

    private fun create(
        transaction: Transaction,
        pageId: PageId,
        element: StoredElement,
    ) {
        transaction
            .query(
                "CREATE ONLY \$element CONTENT \$content; RELATE \$page->\$edge->\$element;",
                mapOf(
                    "element" to element.id.surrealId(),
                    "page" to pageId.surrealId(),
                    "edge" to containmentEdgeId(pageId, element.id),
                    "content" to
                        mapOf(
                            "revision" to element.revision.value,
                            "element_type" to element.elementType.value.toString(),
                            "schema_revision" to element.schemaRevision,
                            "name" to element.name,
                            "value" to DataValueDatabaseCodec.encode(element.value.valueWithSlots),
                            "placement" to element.placement.databaseValue(),
                        ),
                ),
            ).consumeAll()
        replaceReferences(transaction, element.id, element.value.references)
    }

    private fun replaceReferences(
        transaction: Transaction,
        source: ElementInstanceId,
        references: List<StoredReference>,
    ) {
        transaction
            .query(
                "DELETE element_reference WHERE in = \$source;",
                mapOf("source" to source.surrealId()),
            ).take(0)
        references.forEach { reference ->
            transaction
                .query(
                    "RELATE \$source->\$edge->\$target SET slot = \$slot, expected_type = \$expected_type;",
                    mapOf(
                        "source" to source.surrealId(),
                        "edge" to referenceEdgeId(source, reference),
                        "target" to reference.target.surrealId(),
                        "slot" to reference.slot.value,
                        "expected_type" to reference.expectedTypeDatabaseValue(),
                    ),
                ).take(0)
        }
    }

    private fun loadPage(
        transaction: Transaction,
        pageId: PageId,
    ): StoredPageElements {
        val result =
            transaction
                .query(
                    "LET \$elements = SELECT * FROM element WHERE page = \$page ORDER BY id; " +
                        "LET \$references = SELECT * FROM element_reference WHERE in INSIDE \$elements.id ORDER BY in, slot; " +
                        "RETURN { elements: \$elements, references: \$references };",
                    mapOf("page" to pageId.surrealId()),
                ).takeTransaction(2)
                .getObject()
        return ElementRecordParser.parse(result.get("elements"), result.get("references"))
    }

    private fun load(
        transaction: Transaction,
        ids: Collection<ElementInstanceId>,
    ): StoredPageElements {
        if (ids.isEmpty()) return StoredPageElements(emptyList(), emptyMap())
        val result =
            transaction
                .query(
                    "LET \$elements = SELECT * FROM element WHERE id INSIDE \$ids ORDER BY id; " +
                        "LET \$references = SELECT * FROM element_reference WHERE in INSIDE \$ids ORDER BY in, slot; " +
                        "RETURN { elements: \$elements, references: \$references };",
                    mapOf("ids" to ids.map(ElementInstanceId::surrealId)),
                ).takeTransaction(2)
                .getObject()
        return ElementRecordParser.parse(result.get("elements"), result.get("references"))
    }

    private fun missingPages(
        transaction: Transaction,
        pages: Collection<PageId>,
    ): Set<PageId> {
        val distinct = pages.toSet()
        if (distinct.isEmpty()) return emptySet()
        val existing =
            transaction
                .query(
                    "SELECT VALUE id FROM page WHERE id INSIDE \$pages;",
                    mapOf("pages" to distinct.map(PageId::surrealId)),
                ).take(0)
                .getArray()
                .map { it.getRecordId().toPageId() }
                .toSet()
        return distinct - existing
    }

    private fun loadReferringPageIds(
        transaction: Transaction,
        targets: Collection<ElementInstanceId>,
    ): Set<PageId> =
        transaction
            .query(
                "SELECT VALUE in.page FROM element_reference WHERE out INSIDE \$targets;",
                mapOf("targets" to targets.map(ElementInstanceId::surrealId)),
            ).take(0)
            .getArray()
            .filterNot { it.isNone || it.isNull }
            .mapTo(linkedSetOf()) { it.getRecordId().toPageId() }

    private fun <Item> conflicts(
        items: List<Item>,
        current: StoredPageElements,
        id: (Item) -> ElementInstanceId,
        revision: (Item) -> Long,
    ): ElementBatchResult.Conflict? {
        val currentById = current.elements.associateBy(StoredElement::id)
        val conflicts =
            items.mapNotNull { item ->
                val actual = currentById[id(item)]
                if (actual?.revision?.value == revision(item)) null else ElementConflict(id(item), revision(item), actual)
            }
        return conflicts.takeIf(List<*>::isNotEmpty)?.let { ElementBatchResult.Conflict(it) }
    }

    private fun success(
        batchId: BatchId,
        transaction: Transaction,
        ids: List<ElementInstanceId>,
        previous: StoredPageElements,
    ): ElementBatchResult.Success {
        val updated = load(transaction, ids)
        return ElementBatchResult.Success(batchId, updated.elements, previous.pageIds() + updated.pageIds())
    }

    private inline fun <reified Request> executeBatch(
        batchId: BatchId,
        operation: String,
        request: Request,
        affectsCompilation: Boolean,
        crossinline mutation: (Transaction) -> ElementBatchResult,
    ): ElementBatchResult {
        val result =
            database.inTransaction { transaction ->
                val requestHash = canonicalBatchJson.encodeToString(request).sha256()
                replay(transaction, batchId, operation, requestHash)?.let { return@inTransaction it }
                mutation(transaction).also { result ->
                    if (affectsCompilation && result is ElementBatchResult.Success) {
                        transaction
                            .query("UPDATE ONLY authoring_head:current SET revision += 1;")
                            .take(0)
                    }
                    if (result is ElementBatchResult.Success) {
                        val revision = transaction.advanceCollaborationRevision()
                        outbox.enqueue(
                            transaction,
                            encodeEvents(PageInvalidation(result.batchId, revision, result.affectedPages, affectsCompilation)),
                        )
                    }
                    transaction
                        .query(
                            "CREATE ONLY \$batch CONTENT { operation: \$operation, request_hash: \$request_hash, result: \$result };",
                            mapOf(
                                "batch" to RecordId("authoring_batch", batchId.value),
                                "operation" to operation,
                                "request_hash" to requestHash,
                                "result" to ElementBatchResultCodec.encode(result),
                            ),
                        ).take(0)
                }
            }
        if (result is ElementBatchResult.Success) outbox.signalPending()
        return result
    }

    private fun replay(
        transaction: Transaction,
        batchId: BatchId,
        operation: String,
        requestHash: String,
    ): ElementBatchResult? {
        val value =
            transaction
                .query(
                    "SELECT operation, request_hash, result FROM ONLY \$batch;",
                    mapOf("batch" to RecordId("authoring_batch", batchId.value)),
                ).take(0)
        if (value.isNone || value.isNull) return null
        val stored = value.getObject()
        if (stored.get("operation").getString() != operation || stored.get("request_hash").getString() != requestHash) {
            return ElementBatchResult.ValidationFailure(listOf(ElementBatchDiagnostic("batch-id-reused")))
        }
        return ElementBatchResultCodec.decode(batchId, stored.get("result").getString())
    }
}

private fun Set<PageId>.failure(): ElementBatchResult.ValidationFailure =
    ElementBatchResult.ValidationFailure(map { ElementBatchDiagnostic("page-not-found", pageId = it) })

private fun List<StoredElement>.placementFailure(): ElementBatchResult.ValidationFailure =
    ElementBatchResult.ValidationFailure(map { ElementBatchDiagnostic("placement-kind-mismatch", elementId = it.id) })

private fun StoredPageElements.pageIds(): Set<PageId> = pages.values.mapTo(linkedSetOf()) { it.toPageId() }

private fun containmentEdgeId(
    pageId: PageId,
    elementId: ElementInstanceId,
): RecordId =
    RecordId(
        "contains_element",
        Array.fromList(listOf(pageId.surrealId(), elementId.surrealId())),
    )

private fun referenceEdgeId(
    source: ElementInstanceId,
    reference: StoredReference,
): RecordId = referenceEdgeId(source, reference.slot)

private fun referenceEdgeId(
    source: ElementInstanceId,
    slot: ReferenceSlotId,
): RecordId =
    RecordId(
        "element_reference",
        Array.fromList(listOf(source.surrealId(), slot.value)),
    )

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) take(index)
}

private fun String.sha256(): String =
    MessageDigest
        .getInstance("SHA-256")
        .digest(toByteArray())
        .joinToString("") { "%02x".format(it.toInt() and 0xff) }

private val canonicalBatchJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "_kind"
    }
