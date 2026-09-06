package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.Book
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.ref
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.Color
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph

internal class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    internal val database =
        Surreal().apply {
            connect("memory")
            useNs("realm_repository_test").useDb("realm_repository_test")
        }
    private val graphs = linkedMapOf(TEST_ELEMENT_TYPE to TypeGraph(TypeExpression.Any, emptyList()))
    val elementTypeGraphs = { graphs.toMap() }
    val pageDocuments = SurrealPageDocumentRepository(database) { null }
    val authoring = SurrealAuthoringRepository(database, pageDocuments, elementTypeGraphs)

    init {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.migrate",
            unhandledFailureSlug = ErrorSlug.of("test-realm-migrate-failed"),
        ) {
            SchemaMigrator(database).migrate()
        }
    }

    suspend fun createBook(
        id: String,
        title: String = id,
    ): Book {
        val result =
            authoring.apply(
                AuthoringBatch(
                    BatchId("create-book-$id"),
                    listOf(
                        AuthoringOperation.CreateBook(
                            BookId(id),
                            LibraryName(title),
                            Icon.parse("mdi:book"),
                            Color(0u),
                            emptyList(),
                        ),
                    ),
                ),
            ) as AuthoringBatchResult.Applied
        return (result.change.changes.single() as AuthoringResourceChange.UpsertBook).book
    }

    suspend fun createPage(
        id: String,
        book: BookId,
        kind: PageKindRef,
        name: String = id,
    ): Page {
        val result =
            authoring.apply(
                AuthoringBatch(
                    BatchId("create-page-$id"),
                    listOf(
                        AuthoringOperation.CreatePage(
                            Page(
                                id = PageId(id),
                                book = book.ref(),
                                name = LibraryName(name),
                                kind = kind,
                                chapter = ChapterPath.parse(""),
                                priority = 0,
                            ),
                        ),
                    ),
                ),
            ) as AuthoringBatchResult.Applied
        return (result.change.changes.single() as AuthoringResourceChange.UpsertPage).page
    }

    fun registerElementType(
        type: ElementTypeId,
        graph: TypeGraph,
    ) {
        graphs[type] = graph
    }

    override fun close() {
        try {
            database.close()
        } finally {
            telemetry.close()
        }
    }
}

internal val TEST_ELEMENT_TYPE = ElementTypeId(DeclaredTypeId.parse("20000000000000000000000000000001"))
