package com.typewritermc.realm.repository

import com.surrealdb.Array
import com.surrealdb.RecordId
import com.surrealdb.Transaction
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutationResult
import com.typewritermc.elements.ElementValueMutator
import com.typewritermc.elements.ElementValuePath
import com.typewritermc.elements.ElementValuePathSegment
import com.typewritermc.elements.ReferenceAssembler
import com.typewritermc.elements.ReferenceDecomposer
import com.typewritermc.elements.ReferenceSlotId
import com.typewritermc.elements.StoredElement
import com.typewritermc.elements.StoredReference
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.library.bookId
import com.typewritermc.library.pageId
import com.typewritermc.library.ref
import com.typewritermc.library.tagId
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.ElementRecordParser
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.records.StoredPageElements
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.utils.DataValueDatabaseCodec
import com.typewritermc.realm.repository.utils.databaseValue
import com.typewritermc.realm.repository.utils.expectedTypeDatabaseValue
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.takeTransaction
import com.typewritermc.realm.repository.utils.toBookId
import com.typewritermc.realm.repository.utils.toElementInstanceId
import com.typewritermc.realm.repository.utils.toPageId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.DataValue
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeGraph

/**
 * Enforces authoring invariants inside a caller owned transaction and accumulates resulting changes.
 *
 * It checks expected values, related records, tag cycles, and reference bookkeeping while tracking indirectly
 * affected pages. It does not commit; rejection must unwind the whole batch.
 */
internal class AuthoringMutation(
    private val transaction: Transaction,
    private val typeGraphs: Map<ElementTypeId, TypeGraph>,
    private val valueMutator: ElementValueMutator,
    private val decomposer: ReferenceDecomposer = ReferenceDecomposer(),
) {
    val changes = mutableListOf<AuthoringResourceChange>()
    var affectsCompilation = false
        private set

    private val affectedPages = linkedSetOf<PageId>()

    fun apply(operation: AuthoringOperation) {
        when (operation) {
            is AuthoringOperation.CreateBook -> createBook(operation)
            is AuthoringOperation.PatchBook -> patchBook(operation)
            is AuthoringOperation.DeleteBook -> deleteBook(operation)
            is AuthoringOperation.CreateTag -> createTag(operation)
            is AuthoringOperation.PatchTag -> patchTag(operation)
            is AuthoringOperation.DeleteTag -> deleteTag(operation)
            is AuthoringOperation.CreatePage -> createPage(operation)
            is AuthoringOperation.PatchPage -> patchPage(operation)
            is AuthoringOperation.DeletePage -> deletePage(operation)
            is AuthoringOperation.CreateElement -> createElement(operation)
            is AuthoringOperation.PatchElement -> patchElement(operation)
            is AuthoringOperation.DuplicateElement -> duplicateElement(operation)
            is AuthoringOperation.DeleteElement -> deleteElement(operation)
        }
    }

    fun indirectResources(): Set<AuthoringResourceRef> {
        val direct = changes.mapTo(hashSetOf(), AuthoringResourceChange::resource)
        return affectedPages
            .mapTo(linkedSetOf()) { AuthoringResourceRef.Page(it) }
            .filterTo(linkedSetOf()) { it !in direct }
    }

    private fun createBook(operation: AuthoringOperation.CreateBook) {
        if (transaction.loadBooks(listOf(operation.id)).isNotEmpty()) invalid("book-already-exists", operation.resource)
        requireRecords(operation.tags.map { it.id }, "tag-not-found", operation.resource)
        transaction
            .query(
                "CREATE ONLY \$book CONTENT { title: \$title, icon: \$icon, color: \$color };",
                mapOf(
                    "book" to operation.id.surrealId(),
                    "title" to operation.title.value,
                    "icon" to operation.icon.wireValue,
                    "color" to operation.color.argb.toLong(),
                ),
            ).take(0)
        transaction.replaceRelations("bears", operation.id.surrealId(), operation.tags.map { it.surrealId() })
        changes += AuthoringResourceChange.UpsertBook(transaction.loadBooks(listOf(operation.id)).single())
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        affectsCompilation = true
    }

    private fun patchBook(operation: AuthoringOperation.PatchBook) {
        val current =
            transaction.loadBooks(listOf(operation.id)).singleOrNull()
                ?: conflict(operation.resource, emptyPath(), null, null)
        val conflicts = mutableListOf<PropertyConflict>()
        operation.title.check(operation.resource, "title", current.title, conflicts, ::stringValue)
        operation.icon.check(operation.resource, "icon", current.icon, conflicts) { stringValue(it.wireValue) }
        operation.color.check(operation.resource, "color", current.color, conflicts) {
            AuthoringPropertyValue.ColorValue(it)
        }
        operation.tags?.let { change ->
            if (change.expected.map(Ref<Tag>::id).toSet() != current.tags.map(Ref<Tag>::id).toSet()) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        fieldPath("tags"),
                        resourceListValue(change.expected),
                        resourceListValue(current.tags),
                    )
            }
        }
        rejectConflicts(conflicts)
        operation.tags?.let { requireRecords(it.value.map(Ref<Tag>::id), "tag-not-found", operation.resource) }
        operation.title?.let {
            transaction
                .query(
                    "UPDATE ONLY \$book SET title = \$value;",
                    mapOf("book" to operation.id.surrealId(), "value" to it.value.value),
                ).take(0)
        }
        operation.icon?.let {
            transaction
                .query(
                    "UPDATE ONLY \$book SET icon = \$value;",
                    mapOf(
                        "book" to operation.id.surrealId(),
                        "value" to it.value.wireValue,
                    ),
                ).take(0)
        }
        operation.color?.let {
            transaction
                .query(
                    "UPDATE ONLY \$book SET color = \$value;",
                    mapOf(
                        "book" to operation.id.surrealId(),
                        "value" to it.value.argb.toLong(),
                    ),
                ).take(0)
        }
        operation.tags?.let {
            transaction.replaceRelations("bears", operation.id.surrealId(), it.value.map(Ref<Tag>::surrealId))
        }
        changes += AuthoringResourceChange.UpsertBook(transaction.loadBooks(listOf(operation.id)).single())
        affectedPages += transaction.pagesInBooks(listOf(operation.id))
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        affectsCompilation = true
    }

    private fun deleteBook(operation: AuthoringOperation.DeleteBook) {
        val pages = transaction.pagesInBooks(listOf(operation.id))
        val elements = transaction.elementIdsInPages(pages)
        affectedPages += pages
        affectedPages +=
            transaction.referringPages(
                listOf(operation.id.surrealId()) +
                    pages.map(PageId::surrealId) +
                    elements.map(ElementInstanceId::surrealId),
            )
        transaction.deleteElements(elements)
        transaction
            .query(
                "DELETE page WHERE id INSIDE \$pages; DELETE ONLY \$book;",
                mapOf("pages" to pages.map(PageId::surrealId), "book" to operation.id.surrealId()),
            ).consumeAll()
        changes += elements.map { AuthoringResourceChange.RemoveElement(it) }
        changes += pages.map { AuthoringResourceChange.RemovePage(it) }
        changes += AuthoringResourceChange.RemoveBook(operation.id)
        affectsCompilation = true
    }

    private fun createTag(operation: AuthoringOperation.CreateTag) {
        if (transaction.loadTags(listOf(operation.id)).isNotEmpty()) invalid("tag-already-exists", operation.resource)
        requireRecords(operation.parents.map(Ref<Tag>::id), "tag-parent-not-found", operation.resource)
        transaction.createTag(operation)
        transaction.replaceRelations("inherits", operation.id.surrealId(), operation.parents.map(Ref<Tag>::surrealId))
        validateTagGraph(operation.resource)
        changes += AuthoringResourceChange.UpsertTag(transaction.loadTags(listOf(operation.id)).single())
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        affectsCompilation = true
    }

    private fun patchTag(operation: AuthoringOperation.PatchTag) {
        val current =
            transaction.loadTags(listOf(operation.id)).singleOrNull()
                ?: conflict(operation.resource, emptyPath(), null, null)
        val conflicts = mutableListOf<PropertyConflict>()
        operation.name.check(operation.resource, "name", current.name, conflicts, ::stringValue)
        operation.color.check(operation.resource, "color", current.color, conflicts) {
            AuthoringPropertyValue.ColorValue(it)
        }
        operation.parents?.let { change ->
            if (change.expected.map(Ref<Tag>::id).toSet() != current.parents.map(Ref<Tag>::id).toSet()) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        fieldPath("parents"),
                        resourceListValue(change.expected),
                        resourceListValue(current.parents),
                    )
            }
        }
        operation.x.check(operation.resource, "placement.x", current.placement.x, conflicts, ::integerValue)
        operation.y.check(operation.resource, "placement.y", current.placement.y, conflicts, ::integerValue)
        operation.width.check(operation.resource, "placement.width", current.placement.width, conflicts, ::integerValue)
        operation.height.check(
            operation.resource,
            "placement.height",
            current.placement.height,
            conflicts,
            ::integerValue,
        )
        rejectConflicts(conflicts)
        if (operation.width?.value?.let { it <= 0 } == true || operation.height?.value?.let { it <= 0 } == true) {
            invalid("tag-placement-invalid", operation.resource)
        }
        operation.parents?.let {
            requireRecords(it.value.map(Ref<Tag>::id), "tag-parent-not-found", operation.resource)
        }
        val updates =
            listOfNotNull(
                operation.name?.let { "name = \$name" },
                operation.color?.let { "color = \$color" },
                operation.x?.let { "placement.x = \$x" },
                operation.y?.let { "placement.y = \$y" },
                operation.width?.let { "placement.width = \$width" },
                operation.height?.let { "placement.height = \$height" },
            )
        if (updates.isNotEmpty()) {
            transaction
                .query(
                    "UPDATE ONLY \$tag SET ${updates.joinToString(", ")};",
                    mapOf(
                        "tag" to operation.id.surrealId(),
                        "name" to operation.name?.value?.value,
                        "color" to
                            operation.color
                                ?.value
                                ?.argb
                                ?.toLong(),
                        "x" to operation.x?.value,
                        "y" to operation.y?.value,
                        "width" to operation.width?.value,
                        "height" to operation.height?.value,
                    ).filterValues { it != null },
                ).take(0)
        }
        operation.parents?.let {
            transaction.replaceRelations("inherits", operation.id.surrealId(), it.value.map(Ref<Tag>::surrealId))
        }
        validateTagGraph(operation.resource)
        changes += AuthoringResourceChange.UpsertTag(transaction.loadTags(listOf(operation.id)).single())
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
    }

    private fun deleteTag(operation: AuthoringOperation.DeleteTag) {
        val tag = operation.id.surrealId()
        val children = transaction.relatedSources("inherits", tag).map(RecordId::toTagId)
        val books = transaction.relatedSources("bears", tag).map(RecordId::toBookId)
        affectedPages += transaction.referringPages(listOf(tag))
        transaction.query("DELETE ONLY \$tag;", mapOf("tag" to tag)).take(0)
        val changedChildren = transaction.loadTags(children)
        val changedBooks = transaction.loadBooks(books)
        changes += changedChildren.map(AuthoringResourceChange::UpsertTag)
        changes += changedBooks.map(AuthoringResourceChange::UpsertBook)
        changes += AuthoringResourceChange.RemoveTag(operation.id)
        affectedPages +=
            transaction.referringPages(
                changedChildren.map { it.id.surrealId() } + changedBooks.map { it.id.surrealId() },
            )
        affectsCompilation = true
    }

    private fun createPage(operation: AuthoringOperation.CreatePage) {
        val page = operation.page
        if (transaction.loadPages(listOf(page.id)).isNotEmpty()) invalid("page-already-exists", operation.resource)
        requireRecords(listOf(page.book.id), "book-not-found", operation.resource)
        transaction
            .query(
                "CREATE ONLY \$page CONTENT { name: \$name, kind: { id: \$kind, revision: \$kind_revision }, " +
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
        changes += AuthoringResourceChange.UpsertPage(transaction.loadPages(listOf(page.id)).single())
        affectedPages += page.id
        affectedPages += transaction.referringPages(listOf(page.id.surrealId()))
        affectsCompilation = true
    }

    private fun patchPage(operation: AuthoringOperation.PatchPage) {
        val current =
            transaction.loadPages(listOf(operation.id)).singleOrNull()
                ?: conflict(operation.resource, emptyPath(), null, null)
        val conflicts = mutableListOf<PropertyConflict>()
        operation.book.check(operation.resource, "book", current.book, conflicts) {
            AuthoringPropertyValue.ResourceValue(it.id)
        }
        operation.name.check(operation.resource, "name", current.name, conflicts, ::stringValue)
        operation.chapter.check(operation.resource, "chapter", current.chapter, conflicts) { stringValue(it.value) }
        operation.priority.check(operation.resource, "priority", current.priority, conflicts, ::integerValue)
        rejectConflicts(conflicts)
        operation.book?.let { requireRecords(listOf(it.value.id), "book-not-found", operation.resource) }
        operation.book?.let {
            transaction
                .query(
                    "DELETE contains_page WHERE out = \$page; RELATE \$book->\$edge->\$page;",
                    mapOf(
                        "page" to operation.id.surrealId(),
                        "book" to it.value.surrealId(),
                        "edge" to relationId("contains_page", it.value.surrealId(), operation.id.surrealId()),
                    ),
                ).consumeAll()
        }
        operation.name?.let {
            transaction
                .query(
                    "UPDATE ONLY \$page SET name = \$value;",
                    mapOf("page" to operation.id.surrealId(), "value" to it.value.value),
                ).take(0)
        }
        operation.chapter?.let {
            transaction
                .query(
                    "UPDATE ONLY \$page SET chapter = \$value;",
                    mapOf(
                        "page" to operation.id.surrealId(),
                        "value" to it.value.value,
                    ),
                ).take(0)
        }
        operation.priority?.let {
            transaction
                .query(
                    "UPDATE ONLY \$page SET priority = \$value;",
                    mapOf("page" to operation.id.surrealId(), "value" to it.value),
                ).take(0)
        }
        changes += AuthoringResourceChange.UpsertPage(transaction.loadPages(listOf(operation.id)).single())
        affectedPages += operation.id
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        affectsCompilation = true
    }

    private fun deletePage(operation: AuthoringOperation.DeletePage) {
        val elements = transaction.elementIdsInPages(listOf(operation.id))
        affectedPages += operation.id
        affectedPages +=
            transaction.referringPages(
                listOf(operation.id.surrealId()) + elements.map(ElementInstanceId::surrealId),
            )
        transaction.deleteElements(elements)
        transaction.query("DELETE ONLY \$page;", mapOf("page" to operation.id.surrealId())).take(0)
        changes += elements.map(AuthoringResourceChange::RemoveElement)
        changes += AuthoringResourceChange.RemovePage(operation.id)
        affectsCompilation = true
    }

    private fun createElement(operation: AuthoringOperation.CreateElement) {
        val element = operation.element
        if (transaction.loadElements(listOf(element.id)).elements.isNotEmpty()) {
            invalid("element-already-exists", operation.resource)
        }
        requireRecords(listOf(element.page.id), "page-not-found", operation.resource)
        val graph = typeGraphs[element.elementType] ?: invalid("element-type-unavailable", operation.resource)
        val stored =
            StoredElement(
                id = element.id,
                elementType = element.elementType,
                schemaRevision = element.schemaRevision,
                name = element.name,
                value = decomposer.decompose(graph, element.value),
                placement = element.placement,
            )
        transaction.createElement(element.page.pageId(), stored)
        changes += AuthoringResourceChange.UpsertElement(transaction.authoringElement(element.id, typeGraphs))
        affectedPages += element.page.pageId()
        affectedPages += transaction.referringPages(listOf(element.id.surrealId()))
        affectsCompilation = true
    }

    private fun patchElement(operation: AuthoringOperation.PatchElement) {
        val loaded = transaction.loadElements(listOf(operation.id))
        val current =
            loaded.elements.singleOrNull()
                ?: conflict(operation.resource, emptyPath(), null, null)
        val currentPage = checkNotNull(loaded.pages[current.id]).toPageId().ref()
        val graph = typeGraphs[current.elementType] ?: invalid("element-type-unavailable", operation.resource)
        val conflicts = mutableListOf<PropertyConflict>()
        operation.page.check(operation.resource, "page", currentPage, conflicts) {
            AuthoringPropertyValue.ResourceValue(it.id)
        }
        operation.name.check(operation.resource, "name", current.name, conflicts, ::stringValue)
        operation.placement.check(
            operation.resource,
            "placement",
            current.placement,
            conflicts,
        ) { AuthoringPropertyValue.PlacementValue(it) }
        var projectedValue = current.value
        operation.valueMutations.forEach { expectedMutation ->
            val mutation = expectedMutation.mutation
            val actual =
                runCatching { valueMutator.read(graph, projectedValue, mutation.path) }
                    .getOrElse { invalid("invalid-value-path", operation.resource, mutation.path) }
            if (actual != expectedMutation.expected) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        mutation.path,
                        AuthoringPropertyValue.DataValueValue(expectedMutation.expected),
                        AuthoringPropertyValue.DataValueValue(actual),
                    )
            } else {
                projectedValue =
                    when (val result = valueMutator.apply(graph, projectedValue, listOf(mutation))) {
                        is ElementValueMutationResult.Success -> result.value
                        is ElementValueMutationResult.Failure -> invalid(result.code, operation.resource, mutation.path)
                    }
            }
        }
        rejectConflicts(conflicts)
        operation.page?.let { requireRecords(listOf(it.value.id), "page-not-found", operation.resource) }
        val nextPage = operation.page?.value ?: currentPage
        operation.page?.let {
            transaction
                .query(
                    "DELETE contains_element WHERE out = \$element; RELATE \$page->\$edge->\$element;",
                    mapOf(
                        "element" to operation.id.surrealId(),
                        "page" to it.value.surrealId(),
                        "edge" to containmentEdgeId(it.value.pageId(), operation.id),
                    ),
                ).consumeAll()
        }
        transaction
            .query(
                "UPDATE ONLY \$element SET name = \$name, value = \$value, placement = \$placement;",
                mapOf(
                    "element" to operation.id.surrealId(),
                    "name" to (operation.name?.value ?: current.name),
                    "value" to DataValueDatabaseCodec.encode(projectedValue.valueWithSlots),
                    "placement" to (operation.placement?.value ?: current.placement).databaseValue(),
                ),
            ).take(0)
        transaction.replaceElementReferences(operation.id, projectedValue.references)
        changes += AuthoringResourceChange.UpsertElement(transaction.authoringElement(operation.id, typeGraphs))
        affectedPages += currentPage.pageId()
        affectedPages += nextPage.pageId()
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        val placementAffectsCompilation =
            operation.placement?.let {
                current.placement !is ElementPlacement.Graph || it.value !is ElementPlacement.Graph
            } == true
        if (
            operation.page != null ||
            operation.name != null ||
            operation.valueMutations.isNotEmpty() ||
            placementAffectsCompilation
        ) {
            affectsCompilation = true
        }
    }

    private fun duplicateElement(operation: AuthoringOperation.DuplicateElement) {
        val loaded = transaction.loadElements(listOf(operation.sourceId))
        val source =
            loaded.elements.singleOrNull()
                ?: conflict(AuthoringResourceRef.Element(operation.sourceId), emptyPath(), null, null)
        val graph =
            typeGraphs[source.elementType]
                ?: invalid("element-type-unavailable", AuthoringResourceRef.Element(source.id))
        val logical = source.logicalValue(graph)
        if (logical != operation.expectedValue) {
            conflict(
                AuthoringResourceRef.Element(source.id),
                fieldPath("value"),
                AuthoringPropertyValue.DataValueValue(operation.expectedValue),
                AuthoringPropertyValue.DataValueValue(logical),
            )
        }
        if (transaction.loadElements(listOf(operation.newId)).elements.isNotEmpty()) {
            invalid("element-already-exists", operation.resource)
        }
        requireRecords(listOf(operation.page.id), "page-not-found", operation.resource)
        val value =
            source.value.copy(
                references =
                    source.value.references.map { reference ->
                        reference.copy(target = operation.referenceRewrites[reference.target] ?: reference.target)
                    },
            )
        transaction.createElement(
            operation.page.pageId(),
            source.copy(
                id = operation.newId,
                name = operation.name,
                value = value,
                placement = operation.placement,
            ),
        )
        changes += AuthoringResourceChange.UpsertElement(transaction.authoringElement(operation.newId, typeGraphs))
        affectedPages += operation.page.pageId()
        affectedPages += transaction.referringPages(listOf(operation.newId.surrealId()))
        affectsCompilation = true
    }

    private fun deleteElement(operation: AuthoringOperation.DeleteElement) {
        val current = transaction.loadElements(listOf(operation.id))
        affectedPages += current.pages.values.map(RecordId::toPageId)
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        transaction.deleteElements(listOf(operation.id))
        changes += AuthoringResourceChange.RemoveElement(operation.id)
        affectsCompilation = true
    }

    private fun validateTagGraph(resource: AuthoringResourceRef) {
        if (transaction.loadTagParentMap().hasCycle()) invalid("tag-inheritance-cycle", resource)
    }

    private fun requireRecords(
        ids: Collection<ResourceId>,
        code: String,
        resource: AuthoringResourceRef,
    ) {
        if (transaction.missing(ids.map(ResourceId::surrealId)).isNotEmpty()) invalid(code, resource)
    }

    private fun rejectConflicts(conflicts: List<PropertyConflict>) {
        if (conflicts.isNotEmpty()) throw AuthoringRejected(AuthoringBatchResult.Conflict(conflicts))
    }

    private fun conflict(
        resource: AuthoringResourceRef,
        path: ElementValuePath,
        expected: AuthoringPropertyValue?,
        actual: AuthoringPropertyValue?,
    ): Nothing =
        throw AuthoringRejected(
            AuthoringBatchResult.Conflict(listOf(PropertyConflict(resource, path, expected, actual))),
        )

    private fun invalid(
        code: String,
        resource: AuthoringResourceRef? = null,
        path: ElementValuePath? = null,
    ): Nothing =
        throw AuthoringRejected(
            AuthoringBatchResult.Invalid(listOf(AuthoringDiagnostic(code, code, resource, path))),
        )
}

private fun <T> ExpectedChange<T>?.check(
    resource: AuthoringResourceRef,
    field: String,
    actual: T,
    conflicts: MutableList<PropertyConflict>,
    propertyValue: (T) -> AuthoringPropertyValue,
) {
    if (this != null && expected != actual) {
        conflicts += PropertyConflict(resource, fieldPath(field), propertyValue(expected), propertyValue(actual))
    }
}

private fun stringValue(value: String): AuthoringPropertyValue = AuthoringPropertyValue.StringValue(value)

private fun stringValue(value: LibraryName): AuthoringPropertyValue = AuthoringPropertyValue.StringValue(value.value)

private fun integerValue(value: Int): AuthoringPropertyValue = AuthoringPropertyValue.IntegerValue(value)

private fun resourceListValue(values: Collection<Ref<*>>): AuthoringPropertyValue =
    AuthoringPropertyValue.ResourcesValue(values.map(Ref<*>::id).sortedBy(ResourceId::referenceString))

private fun fieldPath(field: String): ElementValuePath =
    ElementValuePath(
        field.split('.').map(ElementValuePathSegment::Field),
    )

private fun emptyPath(): ElementValuePath = ElementValuePath()

private fun Transaction.loadBooks(ids: Collection<BookId>): List<Book> {
    if (ids.isEmpty()) return emptyList()
    return BookRecord
        .parseList(
            query(
                "SELECT * FROM book WHERE id INSIDE \$ids ORDER BY id;",
                mapOf("ids" to ids.map(BookId::surrealId)),
            ).take(0),
        ).map(BookRecord::toBook)
}

private fun Transaction.loadPages(ids: Collection<PageId>): List<Page> {
    if (ids.isEmpty()) return emptyList()
    return PageRecord
        .parseList(
            query(
                "SELECT * FROM page WHERE id INSIDE \$ids ORDER BY id;",
                mapOf("ids" to ids.map(PageId::surrealId)),
            ).take(0),
        ).map(PageRecord::toPage)
}

private fun Transaction.loadTags(ids: Collection<TagId>): List<Tag> {
    if (ids.isEmpty()) return emptyList()
    return TagRecord
        .parseList(
            query(
                "SELECT * FROM tag WHERE id INSIDE \$ids ORDER BY id;",
                mapOf("ids" to ids.map(TagId::surrealId)),
            ).take(0),
        ).map(TagRecord::toTag)
}

private fun Transaction.loadElements(ids: Collection<ElementInstanceId>): StoredPageElements {
    if (ids.isEmpty()) return StoredPageElements(emptyList(), emptyMap())
    val result =
        query(
            "LET \$elements = SELECT * FROM element WHERE id INSIDE \$ids ORDER BY id; " +
                "LET \$references = SELECT * FROM element_reference WHERE in INSIDE \$ids ORDER BY in, slot; " +
                "RETURN { elements: \$elements, references: \$references };",
            mapOf("ids" to ids.map(ElementInstanceId::surrealId)),
        ).takeTransaction(2)
            .getObject()
    return ElementRecordParser.parse(result.get("elements"), result.get("references"))
}

private fun Transaction.authoringElement(
    id: ElementInstanceId,
    typeGraphs: Map<ElementTypeId, TypeGraph>,
): AuthoringElement {
    val loaded = loadElements(listOf(id))
    val element = loaded.elements.single()
    val page = checkNotNull(loaded.pages[id]).toPageId().ref()
    val graph = checkNotNull(typeGraphs[element.elementType])
    return element.toAuthoringElement(page, graph)
}

private fun StoredElement.toAuthoringElement(
    page: Ref<Page>,
    graph: TypeGraph,
): AuthoringElement =
    AuthoringElement(
        id,
        page,
        elementType,
        schemaRevision,
        name,
        logicalValue(graph),
        placement,
    )

private fun StoredElement.logicalValue(graph: TypeGraph): DataValue =
    ReferenceAssembler()
        .assemble(graph, value)
        .value

private fun Transaction.createElement(
    pageId: PageId,
    element: StoredElement,
) {
    query(
        "CREATE ONLY \$element CONTENT \$content; RELATE \$page->\$edge->\$element;",
        mapOf(
            "element" to element.id.surrealId(),
            "page" to pageId.surrealId(),
            "edge" to containmentEdgeId(pageId, element.id),
            "content" to
                mapOf(
                    "element_type" to element.elementType.value.toString(),
                    "schema_revision" to element.schemaRevision,
                    "name" to element.name,
                    "value" to DataValueDatabaseCodec.encode(element.value.valueWithSlots),
                    "placement" to element.placement.databaseValue(),
                ),
        ),
    ).consumeAll()
    replaceElementReferences(element.id, element.value.references)
}

private fun Transaction.replaceElementReferences(
    source: ElementInstanceId,
    references: List<StoredReference>,
) {
    query("DELETE element_reference WHERE in = \$source;", mapOf("source" to source.surrealId())).take(0)
    references.forEach { reference ->
        query(
            "RELATE \$source->\$edge->\$target SET slot = \$slot, expected_type = \$expected_type;",
            mapOf(
                "source" to source.surrealId(),
                "edge" to referenceEdgeId(source, reference.slot),
                "target" to reference.target.surrealId(),
                "slot" to reference.slot.value,
                "expected_type" to reference.expectedTypeDatabaseValue(),
            ),
        ).take(0)
    }
}

private fun Transaction.createTag(operation: AuthoringOperation.CreateTag) {
    query(
        "CREATE ONLY \$tag CONTENT { name: \$name, color: \$color, placement: \$placement };",
        mapOf(
            "tag" to operation.id.surrealId(),
            "name" to operation.name.value,
            "color" to operation.color.argb.toLong(),
            "placement" to
                mapOf(
                    "x" to operation.placement.x,
                    "y" to operation.placement.y,
                    "width" to operation.placement.width,
                    "height" to operation.placement.height,
                ),
        ),
    ).take(0)
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

private fun Transaction.missing(ids: Collection<RecordId>): Set<RecordId> {
    if (ids.isEmpty()) return emptySet()
    val existing =
        query("RETURN \$ids.filter(|\$id| record::exists(\$id));", mapOf("ids" to ids.distinct()))
            .take(0)
            .getArray()
            .mapTo(linkedSetOf()) { it.getRecordId() }
    return ids.toSet() - existing
}

private fun Transaction.pagesInBooks(ids: Collection<BookId>): Set<PageId> {
    if (ids.isEmpty()) return emptySet()
    return query(
        "SELECT VALUE out FROM contains_page WHERE in INSIDE \$books;",
        mapOf("books" to ids.map(BookId::surrealId)),
    ).take(0)
        .getArray()
        .mapTo(linkedSetOf()) { it.getRecordId().toPageId() }
}

private fun Transaction.elementIdsInPages(ids: Collection<PageId>): List<ElementInstanceId> {
    if (ids.isEmpty()) return emptyList()
    return query(
        "SELECT VALUE out FROM contains_element WHERE in INSIDE \$pages;",
        mapOf("pages" to ids.map(PageId::surrealId)),
    ).take(0)
        .getArray()
        .map { it.getRecordId().toElementInstanceId() }
}

private fun Transaction.referringPages(targets: Collection<RecordId>): Set<PageId> {
    if (targets.isEmpty()) return emptySet()
    return query("SELECT VALUE in.page FROM element_reference WHERE out INSIDE \$targets;", mapOf("targets" to targets))
        .take(0)
        .getArray()
        .filterNot { it.isNone || it.isNull }
        .mapTo(linkedSetOf()) { it.getRecordId().toPageId() }
}

private fun Transaction.deleteElements(ids: Collection<ElementInstanceId>) {
    if (ids.isEmpty()) return
    query(
        "DELETE element WHERE id INSIDE \$elements;",
        mapOf("elements" to ids.map(ElementInstanceId::surrealId)),
    ).take(0)
}

private fun Transaction.relatedSources(
    table: String,
    target: RecordId,
): List<RecordId> =
    query(
        "SELECT VALUE in FROM type::table(\$table) WHERE out = \$target;",
        mapOf("table" to table, "target" to target),
    ).take(0)
        .getArray()
        .map { it.getRecordId() }

private fun Transaction.loadTagParentMap(): Map<TagId, Set<TagId>> =
    loadTags(query("SELECT VALUE id FROM tag;").take(0).getArray().map { it.getRecordId().toTagId() })
        .associate { tag -> tag.id to tag.parents.mapTo(linkedSetOf()) { it.tagId() } }

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

private fun relationId(
    table: String,
    source: RecordId,
    target: RecordId,
): RecordId = RecordId(table, Array.fromList(listOf(source, target)))

private fun containmentEdgeId(
    pageId: PageId,
    elementId: ElementInstanceId,
): RecordId = RecordId("contains_element", Array.fromList(listOf(pageId.surrealId(), elementId.surrealId())))

private fun referenceEdgeId(
    source: ElementInstanceId,
    slot: ReferenceSlotId,
): RecordId = RecordId("element_reference", Array.fromList(listOf(source.surrealId(), slot.value)))

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) take(index)
}
