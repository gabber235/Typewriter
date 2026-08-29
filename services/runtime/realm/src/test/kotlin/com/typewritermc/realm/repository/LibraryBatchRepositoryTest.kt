package com.typewritermc.realm.repository

import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.PageId
import com.typewritermc.library.PageKindId
import com.typewritermc.library.PageKindRef
import com.typewritermc.library.TagId
import com.typewritermc.library.ref
import com.typewritermc.types.Color
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest

val LibraryBatchRepositoryTest by testSuite {
    test("book batches are atomic and idempotent") {
        runTest {
            RepositoryFixture().use { fixture ->
                val repository = SurrealLibraryBatchRepository(fixture.database)
                val create =
                    CreateBooksCommand(
                        BatchId("create-book-batch"),
                        listOf(
                            BookCreation(BookId("batch-a"), LibraryName("batch_a"), Icon.parse("mdi:book"), Color(0u), emptyList()),
                            BookCreation(BookId("batch-b"), LibraryName("batch_b"), Icon.parse("mdi:book"), Color(0u), emptyList()),
                        ),
                    )

                val first = repository.createBooks(create) as LibraryBatchResult.Success
                val replay = repository.createBooks(create) as LibraryBatchResult.Success
                first.values shouldBe replay.values
                fixture.books.listBooks().count { it.id in setOf(BookId("batch-a"), BookId("batch-b")) } shouldBe 2

                val conflict =
                    repository.updateBooks(
                        UpdateBooksCommand(
                            BatchId("conflicting-book-batch"),
                            listOf(
                                BookUpdate(BookId("batch-a"), 1, LibraryName("changed_a"), Icon.parse("mdi:book"), Color(0u), emptyList()),
                                BookUpdate(BookId("batch-b"), 2, LibraryName("changed_b"), Icon.parse("mdi:book"), Color(0u), emptyList()),
                            ),
                        ),
                    )
                (conflict is LibraryBatchResult.Conflict) shouldBe true
                fixture.books.getBook(BookId("batch-a"))?.title shouldBe LibraryName("batch_a")
            }
        }
    }

    test("successful batches emit one monotonic typed invalidation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val invalidations = mutableListOf<LibraryInvalidation>()
                val repository =
                    SurrealLibraryBatchRepository(
                        fixture.database,
                        encodeLibraryEvents = {
                            invalidations += it
                            emptyList()
                        },
                    )
                val request =
                    CreateBooksCommand(
                        BatchId("invalidation-book-batch"),
                        listOf(
                            BookCreation(
                                BookId("invalidation-book"),
                                LibraryName("invalidation_book"),
                                Icon.parse("mdi:book"),
                                Color(0u),
                                emptyList(),
                            ),
                        ),
                    )

                repository.createBooks(request) as LibraryBatchResult.Success
                repository.createBooks(request) as LibraryBatchResult.Success

                invalidations shouldBe
                    listOf(
                        LibraryInvalidation(
                            BatchId("invalidation-book-batch"),
                            revision = 1,
                            resources = setOf(LibraryResourceKind.BOOK),
                        ),
                    )
            }
        }
    }

    test("tag and page relation replacements remain singular") {
        runTest {
            RepositoryFixture().use { fixture ->
                val repository = SurrealLibraryBatchRepository(fixture.database)
                repository.createBooks(
                    CreateBooksCommand(
                        BatchId("relation-books"),
                        listOf(book("relation-a"), book("relation-b")),
                    ),
                ) as LibraryBatchResult.Success
                repository.createTags(
                    CreateTagsCommand(
                        BatchId("relation-tags"),
                        listOf(
                            tag("parent-a"),
                            tag("parent-b"),
                            tag("child", parents = listOf(TagId("parent-a"))),
                        ),
                    ),
                ) as LibraryBatchResult.Success
                repository.createPages(
                    CreatePagesCommand(
                        BatchId("relation-page"),
                        listOf(
                            PageCreation(
                                PageId("relation-page"),
                                BookId("relation-a").ref(),
                                LibraryName("relation_page"),
                                TEST_PAGE_KIND,
                                ChapterPath.parse(""),
                                0,
                            ),
                        ),
                    ),
                ) as LibraryBatchResult.Success

                repository.updateTags(
                    UpdateTagsCommand(
                        BatchId("replace-tag-parent"),
                        listOf(
                            tagUpdate("child", parents = listOf(TagId("parent-b"))),
                        ),
                    ),
                ) as LibraryBatchResult.Success
                repository.movePages(
                    MovePagesCommand(
                        BatchId("replace-page-book"),
                        listOf(
                            PageMove(
                                PageId("relation-page"),
                                1,
                                BookId("relation-b").ref(),
                                ChapterPath.parse("moved"),
                                2,
                            ),
                        ),
                    ),
                ) as LibraryBatchResult.Success

                fixture.database
                    .query("SELECT VALUE out FROM inherits WHERE in = tag:child;")
                    .take(0)
                    .getArray()
                    .map { it.getRecordId().id.string } shouldBe listOf("parent-b")
                fixture.database
                    .query("SELECT VALUE in FROM contains_page WHERE out = page:`relation-page`;")
                    .take(0)
                    .getArray()
                    .map { it.getRecordId().id.string } shouldBe listOf("relation-b")

                repository.deleteTags(
                    DeleteTagsCommand(
                        BatchId("delete-parent-tag"),
                        listOf(TagDeletionItem(TagId("parent-b"), 1)),
                    ),
                ) as LibraryBatchResult.Success
                repository.deleteBooks(
                    DeleteBooksCommand(
                        BatchId("delete-containing-book"),
                        listOf(BookDeletion(BookId("relation-b"), 1)),
                    ),
                ) as LibraryBatchResult.Success

                fixture.database
                    .query("SELECT * FROM tag:`parent-b`;")
                    .take(0)
                    .getArray()
                    .map { it }
                    .size shouldBe 0
                fixture.database
                    .query("SELECT * FROM inherits WHERE out = tag:`parent-b`;")
                    .take(0)
                    .getArray()
                    .map { it }
                    .size shouldBe 0
                fixture.database
                    .query("SELECT * FROM book:`relation-b`;")
                    .take(0)
                    .getArray()
                    .map { it }
                    .size shouldBe 0
                fixture.database
                    .query("SELECT * FROM page:`relation-page`;")
                    .take(0)
                    .getArray()
                    .map { it }
                    .size shouldBe 0
                fixture.database
                    .query("SELECT * FROM contains_page;")
                    .take(0)
                    .getArray()
                    .map { it }
                    .size shouldBe 0
            }
        }
    }
}

private fun book(id: String) = BookCreation(BookId(id), LibraryName(id.replace('-', '_')), Icon.parse("mdi:book"), Color(0u), emptyList())

private fun tag(
    id: String,
    parents: List<TagId> = emptyList(),
) = TagCreation(TagId(id), LibraryName(id.replace('-', '_')), Color(0u), parents.map { it.ref() }, GridPlacement(0, 0, 1, 1))

private fun tagUpdate(
    id: String,
    parents: List<TagId>,
) = TagUpdate(TagId(id), 1, LibraryName(id.replace('-', '_')), Color(0u), parents.map { it.ref() }, GridPlacement(0, 0, 1, 1))

private val TEST_PAGE_KIND =
    PageKindRef(
        PageKindId(DeclaredTypeId.parse("019d3a87001170008000000000000011")),
        revision = 1,
    )
