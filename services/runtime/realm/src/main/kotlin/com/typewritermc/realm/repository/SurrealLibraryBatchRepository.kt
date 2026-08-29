package com.typewritermc.realm.repository

import com.surrealdb.Array
import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.library.tagId
import com.typewritermc.realm.outbox.OutboxEvent
import com.typewritermc.realm.outbox.RealmOutbox
import com.typewritermc.realm.outbox.SurrealRealmOutbox
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.utils.advanceCollaborationRevision
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.types.ResourceId
import kotlinx.serialization.KSerializer
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.long
import java.security.MessageDigest

class SurrealLibraryBatchRepository(
    private val database: Surreal,
    private val outbox: RealmOutbox = SurrealRealmOutbox(database),
    private val encodePageEvents: (PageInvalidation) -> List<OutboxEvent> = { emptyList() },
    private val encodeLibraryEvents: (LibraryInvalidation) -> List<OutboxEvent> = { emptyList() },
) : LibraryBatchRepository {
    override suspend fun createBooks(command: CreateBooksCommand): LibraryBatchResult<Book> =
        execute(command.batchId, "create_books", command, Book.serializer(), LibraryResourceKind.BOOK, true) { transaction ->
            transaction.existingIds("book", command.books.map { it.id.surrealId() }).takeIf { it.isNotEmpty() }?.let {
                return@execute LibraryBatchResult.Invalid(listOf("book-already-exists"))
            }
            val missingTags = transaction.missing(command.books.flatMap(BookCreation::tags).map { it.surrealId() })
            if (missingTags.isNotEmpty()) return@execute LibraryBatchResult.Invalid(listOf("tag-not-found"))
            command.books.forEach { book ->
                transaction
                    .query(
                        "CREATE ONLY \$book CONTENT { revision: 1, title: \$title, icon: \$icon, color: \$color };",
                        mapOf(
                            "book" to book.id.surrealId(),
                            "title" to book.title.value,
                            "icon" to book.icon.wireValue,
                            "color" to book.color.argb.toLong(),
                        ),
                    ).take(0)
                transaction.replaceRelations("bears", book.id.surrealId(), book.tags.map { it.surrealId() })
            }
            val created = transaction.loadBooks(command.books.map(BookCreation::id))
            val affected = transaction.referringPages(command.books.map { it.id.surrealId() })
            LibraryBatchResult.Success(command.batchId, created, affected)
        }

    override suspend fun updateBooks(command: UpdateBooksCommand): LibraryBatchResult<Book> =
        execute(command.batchId, "update_books", command, Book.serializer(), LibraryResourceKind.BOOK, true) { transaction ->
            val current = transaction.loadBooks(command.books.map(BookUpdate::id))
            conflicts(command.books, current.associateBy(Book::id), BookUpdate::id, BookUpdate::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            if (transaction.missing(command.books.flatMap(BookUpdate::tags).map { it.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("tag-not-found"))
            }
            command.books.forEach { book ->
                transaction
                    .query(
                        "UPDATE ONLY \$book SET revision += 1, title = \$title, icon = \$icon, color = \$color;",
                        mapOf(
                            "book" to book.id.surrealId(),
                            "title" to book.title.value,
                            "icon" to book.icon.wireValue,
                            "color" to book.color.argb.toLong(),
                        ),
                    ).take(0)
                transaction.replaceRelations("bears", book.id.surrealId(), book.tags.map { it.surrealId() })
            }
            val affected = transaction.pagesInBooks(command.books.map(BookUpdate::id))
            LibraryBatchResult.Success(command.batchId, transaction.loadBooks(command.books.map(BookUpdate::id)), affected)
        }

    override suspend fun deleteBooks(command: DeleteBooksCommand): LibraryBatchResult<Book> =
        execute(command.batchId, "delete_books", command, Book.serializer(), LibraryResourceKind.BOOK, true) { transaction ->
            val current = transaction.loadBooks(command.books.map(BookDeletion::id))
            conflicts(command.books, current.associateBy(Book::id), BookDeletion::id, BookDeletion::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            val pages = transaction.pagesInBooks(command.books.map(BookDeletion::id))
            val elements = transaction.elementIdsInPages(pages)
            val affected = pages + transaction.referringPages(elements)
            transaction.deleteElements(elements)
            transaction
                .query(
                    "DELETE page WHERE id INSIDE \$pages; DELETE book WHERE id INSIDE \$books;",
                    mapOf(
                        "pages" to pages.map(PageId::surrealId),
                        "books" to command.books.map { it.id.surrealId() },
                    ),
                ).consumeAll()
            LibraryBatchResult.Success(command.batchId, emptyList(), affected)
        }

    override suspend fun createPages(command: CreatePagesCommand): LibraryBatchResult<Page> =
        execute(command.batchId, "create_pages", command, Page.serializer(), LibraryResourceKind.PAGE, true) { transaction ->
            if (transaction.existingIds("page", command.pages.map { it.id.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("page-already-exists"))
            }
            if (transaction.missing(command.pages.map { it.book.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("book-not-found"))
            }
            command.pages.forEach { page ->
                transaction
                    .query(
                        "CREATE ONLY \$page CONTENT { revision: 1, name: \$name, kind: { id: \$kind, revision: \$kind_revision }, " +
                            "chapter: \$chapter, priority: \$priority }; RELATE \$book->\$edge->\$page;",
                        mapOf(
                            "page" to page.id.surrealId(),
                            "book" to page.book.surrealId(),
                            "edge" to relationId("contains_page", page.book.surrealId(), page.id.surrealId()),
                            "name" to page.name.value,
                            "kind" to
                                page.kind.id.value
                                    .toString(),
                            "kind_revision" to page.kind.revision,
                            "chapter" to page.chapter.value,
                            "priority" to page.priority,
                        ),
                    ).consumeAll()
            }
            val affected =
                command.pages.mapTo(linkedSetOf(), PageCreation::id) +
                    transaction.referringPages(command.pages.map { it.id.surrealId() })
            LibraryBatchResult.Success(command.batchId, transaction.loadPages(command.pages.map(PageCreation::id)), affected)
        }

    override suspend fun updatePages(command: UpdatePagesCommand): LibraryBatchResult<Page> =
        execute(command.batchId, "update_pages", command, Page.serializer(), LibraryResourceKind.PAGE, true) { transaction ->
            val current = transaction.loadPages(command.pages.map(PageUpdate::id))
            conflicts(command.pages, current.associateBy(Page::id), PageUpdate::id, PageUpdate::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            command.pages.forEach { page ->
                transaction
                    .query(
                        "UPDATE ONLY \$page SET revision += 1, name = \$name, chapter = \$chapter, priority = \$priority;",
                        mapOf(
                            "page" to page.id.surrealId(),
                            "name" to page.name.value,
                            "chapter" to page.chapter.value,
                            "priority" to page.priority,
                        ),
                    ).take(0)
            }
            LibraryBatchResult.Success(
                command.batchId,
                transaction.loadPages(command.pages.map(PageUpdate::id)),
                command.pages.mapTo(linkedSetOf(), PageUpdate::id),
            )
        }

    override suspend fun movePages(command: MovePagesCommand): LibraryBatchResult<Page> =
        execute(command.batchId, "move_pages", command, Page.serializer(), LibraryResourceKind.PAGE, true) { transaction ->
            val current = transaction.loadPages(command.pages.map(PageMove::id))
            conflicts(command.pages, current.associateBy(Page::id), PageMove::id, PageMove::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            if (transaction.missing(command.pages.map { it.book.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("book-not-found"))
            }
            command.pages.forEach { page ->
                transaction
                    .query(
                        "DELETE contains_page WHERE out = \$page; RELATE \$book->\$edge->\$page; " +
                            "UPDATE ONLY \$page SET revision += 1, chapter = \$chapter, priority = \$priority;",
                        mapOf(
                            "page" to page.id.surrealId(),
                            "book" to page.book.surrealId(),
                            "edge" to relationId("contains_page", page.book.surrealId(), page.id.surrealId()),
                            "chapter" to page.chapter.value,
                            "priority" to page.priority,
                        ),
                    ).consumeAll()
            }
            LibraryBatchResult.Success(
                command.batchId,
                transaction.loadPages(command.pages.map(PageMove::id)),
                command.pages.mapTo(linkedSetOf(), PageMove::id),
            )
        }

    override suspend fun deletePages(command: DeletePagesCommand): LibraryBatchResult<Page> =
        execute(command.batchId, "delete_pages", command, Page.serializer(), LibraryResourceKind.PAGE, true) { transaction ->
            val current = transaction.loadPages(command.pages.map(PageDeletion::id))
            conflicts(command.pages, current.associateBy(Page::id), PageDeletion::id, PageDeletion::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            val pages = command.pages.mapTo(linkedSetOf(), PageDeletion::id)
            val elements = transaction.elementIdsInPages(pages)
            val affected = pages + transaction.referringPages(elements)
            transaction.deleteElements(elements)
            transaction
                .query(
                    "DELETE page WHERE id INSIDE \$pages;",
                    mapOf("pages" to pages.map(PageId::surrealId)),
                ).take(0)
            LibraryBatchResult.Success(command.batchId, emptyList(), affected)
        }

    override suspend fun createTags(command: CreateTagsCommand): LibraryBatchResult<Tag> =
        execute(command.batchId, "create_tags", command, Tag.serializer(), LibraryResourceKind.TAG, true) { transaction ->
            if (transaction.existingIds("tag", command.tags.map { it.id.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("tag-already-exists"))
            }
            val available =
                transaction.existingIds("tag", command.tags.flatMap(TagCreation::parents).map { it.surrealId() }) +
                    command.tags.map { it.id.surrealId() }
            val required = command.tags.flatMap(TagCreation::parents).mapTo(linkedSetOf()) { it.surrealId() }
            if (!available.containsAll(required)) return@execute LibraryBatchResult.Invalid(listOf("tag-parent-not-found"))
            val parentMap = transaction.loadTagParentMap().toMutableMap()
            command.tags.forEach { tag -> parentMap[tag.id] = tag.parents.mapTo(linkedSetOf()) { it.tagId() } }
            if (parentMap.hasCycle()) return@execute LibraryBatchResult.Invalid(listOf("tag-inheritance-cycle"))
            command.tags.forEach { tag ->
                transaction.createTag(tag.id, tag.name.value, tag.color.argb.toLong(), tag.placement)
                transaction.replaceRelations("inherits", tag.id.surrealId(), tag.parents.map { it.surrealId() })
            }
            val affected = transaction.referringPages(command.tags.map { it.id.surrealId() })
            LibraryBatchResult.Success(command.batchId, transaction.loadTags(command.tags.map(TagCreation::id)), affected)
        }

    override suspend fun updateTags(command: UpdateTagsCommand): LibraryBatchResult<Tag> =
        execute(command.batchId, "update_tags", command, Tag.serializer(), LibraryResourceKind.TAG, false) { transaction ->
            val current = transaction.loadTags(command.tags.map(TagUpdate::id))
            conflicts(command.tags, current.associateBy(Tag::id), TagUpdate::id, TagUpdate::expectedRevision) { it.revision.value }
                ?.let { return@execute it }
            if (transaction.missing(command.tags.flatMap(TagUpdate::parents).map { it.surrealId() }).isNotEmpty()) {
                return@execute LibraryBatchResult.Invalid(listOf("tag-parent-not-found"))
            }
            val parentMap = transaction.loadTagParentMap().toMutableMap()
            command.tags.forEach { tag -> parentMap[tag.id] = tag.parents.mapTo(linkedSetOf()) { it.tagId() } }
            if (parentMap.hasCycle()) return@execute LibraryBatchResult.Invalid(listOf("tag-inheritance-cycle"))
            command.tags.forEach { tag ->
                transaction
                    .query(
                        "UPDATE ONLY \$tag SET revision += 1, name = \$name, color = \$color, placement = \$placement;",
                        mapOf(
                            "tag" to tag.id.surrealId(),
                            "name" to tag.name.value,
                            "color" to tag.color.argb.toLong(),
                            "placement" to tag.placement.databaseValue(),
                        ),
                    ).take(0)
                transaction.replaceRelations("inherits", tag.id.surrealId(), tag.parents.map { it.surrealId() })
            }
            val affected = transaction.referringPages(command.tags.map { it.id.surrealId() })
            LibraryBatchResult.Success(command.batchId, transaction.loadTags(command.tags.map(TagUpdate::id)), affected)
        }

    override suspend fun deleteTags(command: DeleteTagsCommand): LibraryBatchResult<Tag> =
        execute(command.batchId, "delete_tags", command, Tag.serializer(), LibraryResourceKind.TAG, true) { transaction ->
            val current = transaction.loadTags(command.tags.map(TagDeletionItem::id))
            conflicts(
                command.tags,
                current.associateBy(Tag::id),
                TagDeletionItem::id,
                TagDeletionItem::expectedRevision,
            ) { it.revision.value }
                ?.let { return@execute it }
            val ids = command.tags.map { it.id.surrealId() }
            val affected = transaction.referringPages(ids)
            transaction
                .query(
                    "LET \$children = SELECT VALUE in FROM inherits WHERE out INSIDE \$tags; " +
                        "LET \$books = SELECT VALUE in FROM bears WHERE out INSIDE \$tags; " +
                        "UPDATE \$children SET revision += 1; UPDATE \$books SET revision += 1; " +
                        "DELETE tag WHERE id INSIDE \$tags;",
                    mapOf("tags" to ids),
                ).consumeAll()
            LibraryBatchResult.Success(command.batchId, emptyList(), affected)
        }

    private inline fun <reified Request, T> execute(
        batchId: BatchId,
        operation: String,
        request: Request,
        serializer: KSerializer<T>,
        resourceKind: LibraryResourceKind,
        affectsCompilation: Boolean,
        crossinline mutation: (Transaction) -> LibraryBatchResult<T>,
    ): LibraryBatchResult<T> {
        val result =
            database.inTransaction { transaction ->
                val hash = canonicalBatchJson.encodeToString(request).sha256()
                replay(transaction, batchId, operation, hash, serializer)?.let { return@inTransaction it }
                mutation(transaction).also { value ->
                    if (value is LibraryBatchResult.Success) {
                        if (affectsCompilation) transaction.query("UPDATE ONLY authoring_head:current SET revision += 1;").take(0)
                        val revision = transaction.advanceCollaborationRevision()
                        outbox.enqueue(
                            transaction,
                            encodePageEvents(PageInvalidation(batchId, revision, value.affectedPages, affectsCompilation)) +
                                encodeLibraryEvents(LibraryInvalidation(batchId, revision, setOf(resourceKind))),
                        )
                    }
                    transaction
                        .query(
                            "CREATE ONLY \$batch CONTENT { operation: \$operation, request_hash: \$hash, result: \$result };",
                            mapOf(
                                "batch" to RecordId("authoring_batch", batchId.value),
                                "operation" to operation,
                                "hash" to hash,
                                "result" to encodeResult(value, serializer),
                            ),
                        ).take(0)
                }
            }
        if (result is LibraryBatchResult.Success) outbox.signalPending()
        return result
    }

    private fun <T> replay(
        transaction: Transaction,
        batchId: BatchId,
        operation: String,
        hash: String,
        serializer: KSerializer<T>,
    ): LibraryBatchResult<T>? {
        val value =
            transaction
                .query(
                    "SELECT operation, request_hash, result FROM ONLY \$batch;",
                    mapOf("batch" to RecordId("authoring_batch", batchId.value)),
                ).take(0)
        if (value.isNone || value.isNull) return null
        val stored = value.getObject()
        if (stored.get("operation").getString() != operation || stored.get("request_hash").getString() != hash) {
            return LibraryBatchResult.Invalid(listOf("batch-id-reused"))
        }
        return decodeResult(batchId, stored.get("result").getString(), serializer)
    }
}

private fun Transaction.loadBooks(ids: Collection<BookId>): List<Book> =
    BookRecord
        .parseList(query("SELECT * FROM book WHERE id INSIDE \$ids ORDER BY id;", mapOf("ids" to ids.map(BookId::surrealId))).take(0))
        .map(BookRecord::toBook)

private fun Transaction.loadPages(ids: Collection<PageId>): List<Page> =
    PageRecord
        .parseList(query("SELECT * FROM page WHERE id INSIDE \$ids ORDER BY id;", mapOf("ids" to ids.map(PageId::surrealId))).take(0))
        .map(PageRecord::toPage)

private fun Transaction.loadTags(ids: Collection<TagId>): List<Tag> =
    TagRecord
        .parseList(query("SELECT * FROM tag WHERE id INSIDE \$ids ORDER BY id;", mapOf("ids" to ids.map(TagId::surrealId))).take(0))
        .map(TagRecord::toTag)

private fun Transaction.existingIds(
    table: String,
    ids: Collection<RecordId>,
): Set<RecordId> {
    if (ids.isEmpty()) return emptySet()
    return query("SELECT VALUE id FROM type::table(\$table) WHERE id INSIDE \$ids;", mapOf("table" to table, "ids" to ids))
        .take(0)
        .getArray()
        .mapTo(linkedSetOf()) { it.getRecordId() }
}

private fun Transaction.missing(ids: Collection<RecordId>): Set<RecordId> = ids.toSet() - existingIdsByRecords(ids)

private fun Transaction.existingIdsByRecords(ids: Collection<RecordId>): Set<RecordId> {
    if (ids.isEmpty()) return emptySet()
    return query("RETURN \$ids.filter(|\$id| record::exists(\$id));", mapOf("ids" to ids.distinct()))
        .take(0)
        .getArray()
        .mapTo(linkedSetOf()) { it.getRecordId() }
}

private fun Transaction.pagesInBooks(ids: Collection<BookId>): Set<PageId> {
    if (ids.isEmpty()) return emptySet()
    return query("SELECT VALUE out FROM contains_page WHERE in INSIDE \$books;", mapOf("books" to ids.map(BookId::surrealId)))
        .take(0)
        .getArray()
        .mapTo(linkedSetOf()) { it.getRecordId().toPageId() }
}

private fun Transaction.elementIdsInPages(ids: Collection<PageId>): List<RecordId> {
    if (ids.isEmpty()) return emptyList()
    return query("SELECT VALUE out FROM contains_element WHERE in INSIDE \$pages;", mapOf("pages" to ids.map(PageId::surrealId)))
        .take(0)
        .getArray()
        .map { it.getRecordId() }
}

private fun Transaction.referringPages(targets: Collection<RecordId>): Set<PageId> {
    if (targets.isEmpty()) return emptySet()
    return query("SELECT VALUE in.page FROM element_reference WHERE out INSIDE \$targets;", mapOf("targets" to targets))
        .take(0)
        .getArray()
        .filterNot { it.isNone || it.isNull }
        .mapTo(linkedSetOf()) { it.getRecordId().toPageId() }
}

private fun Transaction.deleteElements(ids: Collection<RecordId>) {
    if (ids.isEmpty()) return
    query("DELETE element WHERE id INSIDE \$elements;", mapOf("elements" to ids)).take(0)
}

private fun Transaction.replaceRelations(
    table: String,
    source: RecordId,
    targets: Collection<RecordId>,
) {
    query("DELETE type::table(\$table) WHERE in = \$source;", mapOf("table" to table, "source" to source)).take(0)
    targets.distinct().forEach { target ->
        query(
            "RELATE \$source->\$edge->\$target;",
            mapOf("source" to source, "edge" to relationId(table, source, target), "target" to target),
        ).take(0)
    }
}

private fun Transaction.loadTagParentMap(): Map<TagId, Set<TagId>> =
    loadTags(
        query("SELECT VALUE id FROM tag;").take(0).getArray().map { TagId(it.getRecordId().id.string) },
    ).associate { tag -> tag.id to tag.parents.mapTo(linkedSetOf()) { TagId(it.id.key) } }

private fun Map<TagId, Set<TagId>>.hasCycle(): Boolean {
    val visiting = mutableSetOf<TagId>()
    val visited = mutableSetOf<TagId>()

    fun visit(id: TagId): Boolean {
        if (id in visiting) return true
        if (!visited.add(id)) return false
        visiting += id
        val cycle = get(id).orEmpty().any(::visit)
        visiting -= id
        return cycle
    }
    return keys.any(::visit)
}

private fun Transaction.createTag(
    id: TagId,
    name: String,
    color: Long,
    placement: com.typewritermc.library.GridPlacement,
) {
    query(
        "CREATE ONLY \$tag CONTENT { revision: 1, name: \$name, color: \$color, placement: \$placement };",
        mapOf("tag" to id.surrealId(), "name" to name, "color" to color, "placement" to placement.databaseValue()),
    ).take(0)
}

private fun com.typewritermc.library.GridPlacement.databaseValue(): Map<String, Int> =
    mapOf("x" to x, "y" to y, "width" to width, "height" to height)

private fun relationId(
    table: String,
    source: RecordId,
    target: RecordId,
): RecordId = RecordId(table, Array.fromList(listOf(source, target)))

private fun <Item, Id, Value> conflicts(
    items: List<Item>,
    current: Map<Id, Value>,
    id: (Item) -> Id,
    expected: (Item) -> Long,
    revision: (Value) -> Long,
): LibraryBatchResult.Conflict<Value>? {
    val values =
        items.mapNotNull { item ->
            val actual = current[id(item)]
            if (actual != null && revision(actual) == expected(item)) {
                null
            } else {
                LibraryResourceConflict(id(item).resourceId(), expected(item), actual)
            }
        }
    return values.takeIf { it.isNotEmpty() }?.let { LibraryBatchResult.Conflict(it) }
}

private fun Any?.resourceId(): ResourceId =
    when (this) {
        is BookId -> ResourceId("book", key)
        is PageId -> ResourceId("page", key)
        is TagId -> ResourceId("tag", key)
        else -> error("Unsupported library resource id")
    }

private fun <T> encodeResult(
    result: LibraryBatchResult<T>,
    serializer: KSerializer<T>,
): String {
    val root =
        when (result) {
            is LibraryBatchResult.Success -> {
                JsonObject(
                    mapOf(
                        "kind" to JsonPrimitive("success"),
                        "values" to json.encodeToJsonElement(ListSerializer(serializer), result.values),
                        "affected_pages" to json.encodeToJsonElement(ListSerializer(PageId.serializer()), result.affectedPages.toList()),
                    ),
                )
            }

            is LibraryBatchResult.Conflict -> {
                JsonObject(
                    mapOf(
                        "kind" to JsonPrimitive("conflict"),
                        "conflicts" to
                            JsonArray(
                                result.conflicts.map { conflict ->
                                    JsonObject(
                                        mapOf(
                                            "id" to json.encodeToJsonElement(ResourceId.serializer(), conflict.id),
                                            "expected" to JsonPrimitive(conflict.expectedRevision),
                                            "actual" to
                                                (conflict.actual?.let { json.encodeToJsonElement(serializer, it) } ?: JsonNull),
                                        ),
                                    )
                                },
                            ),
                    ),
                )
            }

            is LibraryBatchResult.Invalid -> {
                JsonObject(
                    mapOf("kind" to JsonPrimitive("invalid"), "diagnostics" to JsonArray(result.diagnostics.map(::JsonPrimitive))),
                )
            }
        }
    return root.toString()
}

private fun <T> decodeResult(
    batchId: BatchId,
    encoded: String,
    serializer: KSerializer<T>,
): LibraryBatchResult<T> {
    val root = json.parseToJsonElement(encoded).jsonObject
    return when (root.getValue("kind").jsonPrimitive.content) {
        "success" -> {
            LibraryBatchResult.Success(
                batchId,
                json.decodeFromJsonElement(ListSerializer(serializer), root.getValue("values")),
                json.decodeFromJsonElement(ListSerializer(PageId.serializer()), root.getValue("affected_pages")).toSet(),
            )
        }

        "conflict" -> {
            LibraryBatchResult.Conflict(
                root.getValue("conflicts").jsonArray.map { value ->
                    val conflict = value.jsonObject
                    LibraryResourceConflict(
                        json.decodeFromJsonElement(ResourceId.serializer(), conflict.getValue("id")),
                        conflict.getValue("expected").jsonPrimitive.long,
                        conflict.getValue("actual").takeUnless { it is JsonNull }?.let {
                            json.decodeFromJsonElement(serializer, it)
                        },
                    )
                },
            )
        }

        "invalid" -> {
            LibraryBatchResult.Invalid(root.getValue("diagnostics").jsonArray.map { it.jsonPrimitive.content })
        }

        else -> {
            error("Unknown stored library batch result")
        }
    }
}

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) take(index)
}

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }

private val canonicalBatchJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "_kind"
    }

private val json = Json { encodeDefaults = true }
