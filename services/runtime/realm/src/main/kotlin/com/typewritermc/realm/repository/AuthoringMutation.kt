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
import com.typewritermc.elements.elementId
import com.typewritermc.elements.elementName
import com.typewritermc.elements.withElementId
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
import com.typewritermc.types.ReferenceFamily
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import com.typewritermc.types.referenceFamily

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
    private val dirtyElements = linkedSetOf<ElementInstanceId>()

    val dirtyElementIds: Set<ElementInstanceId>
        get() = dirtyElements

    /**
     * Applies one operation to the open transaction and records its observable effects.
     *
     * This method deliberately does not commit. A later rejection still rolls back earlier operations in the same
     * batch through the transaction owner.
     */
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

    /**
     * Returns resources whose projected views changed through containment or references without a direct mutation.
     *
     * Direct resources are excluded so callers can process each resource through exactly one change category.
     */
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
        transaction.replaceResourceReferences(
            operation.id.surrealId(),
            "tags",
            operation.tags.map { it.surrealId() },
        )
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
            transaction.replaceResourceReferences(
                operation.id.surrealId(),
                "tags",
                it.value.map(Ref<Tag>::surrealId),
            )
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
        elements.forEach(::markElementRemoved)
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
        transaction.replaceResourceReferences(
            operation.id.surrealId(),
            "parents",
            operation.parents.map(Ref<Tag>::surrealId),
        )
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
            transaction.replaceResourceReferences(
                operation.id.surrealId(),
                "parents",
                it.value.map(Ref<Tag>::surrealId),
            )
        }
        validateTagGraph(operation.resource)
        changes += AuthoringResourceChange.UpsertTag(transaction.loadTags(listOf(operation.id)).single())
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
    }

    private fun deleteTag(operation: AuthoringOperation.DeleteTag) {
        val tag = operation.id.surrealId()
        val children = transaction.relatedSources("parents", tag).map(RecordId::toTagId)
        val books = transaction.relatedSources("tags", tag).map(RecordId::toBookId)
        affectedPages += transaction.referringPages(listOf(tag))
        transaction
            .query(
                "DELETE resource_reference WHERE target = \$tag AND " +
                    "(string::starts_with(slot, 'parents:') OR string::starts_with(slot, 'tags:')); " +
                    "DELETE ONLY \$tag;",
                mapOf("tag" to tag),
            ).consumeAll()
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
        elements.forEach(::markElementRemoved)
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
                value = decomposer.decompose(graph, element.value.withElementId(element.id)),
                placement = element.placement,
            )
        validateElementReferences(
            operation.resource,
            element.page.pageId(),
            graph,
            stored.value.references,
        )
        transaction.createElement(element.page.pageId(), stored)
        markElementDirty(element.id)
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
        val currentGraph = typeGraphs[current.elementType] ?: invalid("element-type-unavailable", operation.resource)
        val conflicts = mutableListOf<PropertyConflict>()
        operation.page.check(operation.resource, "page", currentPage, conflicts) {
            AuthoringPropertyValue.ResourceValue(it.id)
        }
        operation.placement.check(
            operation.resource,
            "placement",
            current.placement,
            conflicts,
        ) { AuthoringPropertyValue.PlacementValue(it) }
        val currentLogicalValue = current.logicalValue(currentGraph)
        operation.elementType?.let { change ->
            if (change.expectedElementType != current.elementType) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        fieldPath("elementType"),
                        AuthoringPropertyValue.StringValue(change.expectedElementType.value.toString()),
                        AuthoringPropertyValue.StringValue(current.elementType.value.toString()),
                    )
            }
            if (change.expectedSchemaRevision != current.schemaRevision) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        fieldPath("schemaRevision"),
                        AuthoringPropertyValue.IntegerValue(change.expectedSchemaRevision),
                        AuthoringPropertyValue.IntegerValue(current.schemaRevision),
                    )
            }
            if (change.expectedValue != currentLogicalValue) {
                conflicts +=
                    PropertyConflict(
                        operation.resource,
                        fieldPath("value"),
                        AuthoringPropertyValue.DataValueValue(change.expectedValue),
                        AuthoringPropertyValue.DataValueValue(currentLogicalValue),
                    )
            }
        }
        var projectedValue = current.value
        operation.valueMutations.forEach { expectedMutation ->
            val mutation = expectedMutation.mutation
            if (mutation.path.segments.firstOrNull() == ElementValuePathSegment.Field("id")) {
                invalid("immutable-element-id", operation.resource, mutation.path)
            }
            val actual =
                runCatching { valueMutator.read(currentGraph, projectedValue, mutation.path) }
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
                    when (val result = valueMutator.apply(currentGraph, projectedValue, listOf(mutation))) {
                        is ElementValueMutationResult.Success -> result.value
                        is ElementValueMutationResult.Failure -> invalid(result.code, operation.resource, mutation.path)
                    }
            }
        }
        rejectConflicts(conflicts)
        val nextElementType = operation.elementType?.elementType ?: current.elementType
        val nextSchemaRevision = operation.elementType?.schemaRevision ?: current.schemaRevision
        val nextGraph = typeGraphs[nextElementType] ?: invalid("element-type-unavailable", operation.resource)
        operation.elementType?.let { change ->
            projectedValue = decomposer.decompose(nextGraph, change.value.withElementId(operation.id))
        }
        operation.page?.let { requireRecords(listOf(it.value.id), "page-not-found", operation.resource) }
        val nextPage = operation.page?.value ?: currentPage
        validateElementReferences(
            operation.resource,
            nextPage.pageId(),
            nextGraph,
            projectedValue.references,
            if (operation.page == null) current.value.references else emptyList(),
        )
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
                "UPDATE ONLY \$element SET element_type = \$element_type, schema_revision = \$schema_revision, " +
                    "value = \$value, placement = \$placement;",
                mapOf(
                    "element" to operation.id.surrealId(),
                    "element_type" to nextElementType.value.toString(),
                    "schema_revision" to nextSchemaRevision,
                    "value" to DataValueDatabaseCodec.encode(projectedValue.valueWithSlots),
                    "placement" to (operation.placement?.value ?: current.placement).databaseValue(),
                ),
            ).take(0)
        transaction.replaceElementReferences(operation.id, projectedValue.references)
        changes += AuthoringResourceChange.UpsertElement(transaction.authoringElement(operation.id, typeGraphs))
        markElementDirty(operation.id)
        affectedPages += currentPage.pageId()
        affectedPages += nextPage.pageId()
        affectedPages += transaction.referringPages(listOf(operation.id.surrealId()))
        val placementAffectsCompilation =
            operation.placement?.let {
                current.placement !is ElementPlacement.Graph || it.value !is ElementPlacement.Graph
            } == true
        if (
            operation.page != null ||
            operation.valueMutations.isNotEmpty() ||
            operation.elementType != null ||
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
        var duplicateValue =
            decomposer.decompose(
                graph,
                logical.withElementId(operation.newId),
            )
        operation.valueMutations.forEach { mutation ->
            if (mutation.path.segments.firstOrNull() == ElementValuePathSegment.Field("id")) {
                invalid("immutable-element-id", operation.resource, mutation.path)
            }
            duplicateValue =
                when (val result = valueMutator.apply(graph, duplicateValue, listOf(mutation))) {
                    is ElementValueMutationResult.Success -> result.value
                    is ElementValueMutationResult.Failure -> invalid(result.code, operation.resource, mutation.path)
                }
        }
        val value =
            duplicateValue.copy(
                references =
                    source.value.references.map { reference ->
                        reference.copy(target = operation.referenceRewrites[reference.target] ?: reference.target)
                    },
            )
        validateElementReferences(
            operation.resource,
            operation.page.pageId(),
            graph,
            value.references,
        )
        transaction.createElement(
            operation.page.pageId(),
            source.copy(
                id = operation.newId,
                value = value,
                placement = operation.placement,
            ),
        )
        markElementDirty(operation.newId)
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
        markElementRemoved(operation.id)
        changes += AuthoringResourceChange.RemoveElement(operation.id)
        affectsCompilation = true
    }

    private fun markElementDirty(id: ElementInstanceId) {
        dirtyElements += id
    }

    private fun markElementRemoved(id: ElementInstanceId) {
        dirtyElements -= id
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

    private fun validateElementReferences(
        resource: AuthoringResourceRef,
        sourcePage: PageId,
        graph: TypeGraph,
        references: List<StoredReference>,
        retained: List<StoredReference> = emptyList(),
    ) {
        val retainedBySlot = retained.associateBy(StoredReference::slot)
        val changed = references.filter { retainedBySlot[it.slot] != it }
        if (changed.isEmpty()) return
        val catalog = TypeCatalog(graph.definitions)
        val sourceBook = transaction.pageBook(sourcePage) ?: invalid("page-not-found", resource)
        changed.forEach { reference ->
            val targetType =
                (reference.expectedType as? TypeExpression.Named)?.reference
                    ?: invalid("reference-target-type-invalid", resource)
            val family =
                runCatching { catalog.referenceFamily(targetType) }
                    .getOrElse { invalid("reference-target-type-invalid", resource) }
            if (reference.target.table != family.table) invalid("reference-target-type-mismatch", resource)
            val target = reference.target.surrealId()
            if (transaction.missing(listOf(target)).isNotEmpty()) invalid("reference-target-not-found", resource)
            if (family == ReferenceFamily.PAGE || family == ReferenceFamily.ELEMENT) {
                val targetBook =
                    transaction.targetBook(target, family) ?: invalid("reference-target-not-found", resource)
                if (targetBook != sourceBook) invalid("reference-cross-book", resource)
            }
        }
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
                "SELECT *, (SELECT VALUE target FROM resource_reference " +
                    "WHERE source = \$parent.id AND string::starts_with(slot, 'tags:')) AS tags " +
                    "FROM book WHERE id INSIDE \$ids ORDER BY id;",
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
                "SELECT *, (SELECT VALUE target FROM resource_reference " +
                    "WHERE source = \$parent.id AND string::starts_with(slot, 'parents:')) AS parent_tags " +
                    "FROM tag WHERE id INSIDE \$ids ORDER BY id;",
                mapOf("ids" to ids.map(TagId::surrealId)),
            ).take(0),
        ).map(TagRecord::toTag)
}

private fun Transaction.loadElements(ids: Collection<ElementInstanceId>): StoredPageElements {
    if (ids.isEmpty()) return StoredPageElements(emptyList(), emptyMap())
    val result =
        query(
            "LET \$elements = SELECT * FROM element WHERE id INSIDE \$ids ORDER BY id; " +
                "LET \$references = SELECT * FROM resource_reference WHERE source INSIDE \$ids ORDER BY source, slot; " +
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
        logicalValue(graph),
        placement,
    )

private fun StoredElement.logicalValue(graph: TypeGraph): DataValue {
    val logical =
        ReferenceAssembler()
            .assemble(graph, value)
            .value
    check(logical.elementId() == id) { "Element payload id ${logical.elementId().value} does not match ${id.value}." }
    logical.elementName()
    return logical
}

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
    query("DELETE resource_reference WHERE source = \$source;", mapOf("source" to source.surrealId())).take(0)
    references.forEach { reference ->
        query(
            "CREATE ONLY \$reference CONTENT { source: \$source, target: \$target, " +
                "slot: \$slot, expected_type: \$expected_type };",
            mapOf(
                "source" to source.surrealId(),
                "reference" to resourceReferenceId(source.surrealId(), reference.slot.value),
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

private fun Transaction.replaceResourceReferences(
    source: RecordId,
    slotPrefix: String,
    targets: Collection<RecordId>,
) {
    query(
        "DELETE resource_reference WHERE source = \$source AND string::starts_with(slot, \$prefix);",
        mapOf("source" to source, "prefix" to "$slotPrefix:"),
    ).take(0)
    targets.distinct().forEach { target ->
        val slot = "$slotPrefix:$target"
        query(
            "CREATE ONLY \$reference CONTENT { source: \$source, target: \$target, " +
                "slot: \$slot, expected_type: 'tag' };",
            mapOf(
                "reference" to resourceReferenceId(source, slot),
                "source" to source,
                "target" to target,
                "slot" to slot,
            ),
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

private fun Transaction.pageBook(page: PageId): RecordId? {
    val value = query("SELECT VALUE book FROM ONLY \$page;", mapOf("page" to page.surrealId())).take(0)
    return value.takeUnless { it.isNone || it.isNull }?.getRecordId()
}

private fun Transaction.targetBook(
    target: RecordId,
    family: ReferenceFamily,
): RecordId? {
    val field = if (family == ReferenceFamily.PAGE) "book" else "page.book"
    val value = query("SELECT VALUE $field FROM ONLY \$target;", mapOf("target" to target)).take(0)
    return value.takeUnless { it.isNone || it.isNull }?.getRecordId()
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
    return query(
        "SELECT VALUE source.page FROM resource_reference " +
            "WHERE target INSIDE \$targets;",
        mapOf("targets" to targets),
    ).take(0)
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
    slotPrefix: String,
    target: RecordId,
): List<RecordId> =
    query(
        "SELECT VALUE source FROM resource_reference " +
            "WHERE target = \$target AND string::starts_with(slot, \$prefix);",
        mapOf("target" to target, "prefix" to "$slotPrefix:"),
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

private fun resourceReferenceId(
    source: RecordId,
    slot: String,
): RecordId = RecordId("resource_reference", Array.fromList(listOf(source, slot)))

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) take(index)
}
