package com.typewritermc.realm.repository

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.ElementPlacement
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.library.BookId
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Page
import com.typewritermc.library.PageId
import com.typewritermc.library.TagId
import com.typewritermc.library.ref
import com.typewritermc.realm.TestPageKinds
import com.typewritermc.realm.routes.toLibrary
import com.typewritermc.types.Color
import com.typewritermc.types.DataValue
import com.typewritermc.types.DeclaredTypeId
import com.typewritermc.types.Icon
import com.typewritermc.types.TypeExpression
import com.typewritermc.types.TypeGraph
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest

val AuthoringRepositoryTest by testSuite {
    test("related creates persist opaque element identities and roll back together") {
        runTest {
            for (reject in listOf(false, true)) {
                RepositoryFixture().use { fixture ->
                    val type =
                        ElementTypeId(
                            DeclaredTypeId.parse("40000000000000000000000000000001"),
                        )
                    fixture.registerElementType(type, TypeGraph(TypeExpression.Any, emptyList()))
                    val id = ElementInstanceId("kd9pn4fa2s7m8q3v6x0z")
                    val base = mixedCreateBatch("related")
                    val operations =
                        base.operations +
                            AuthoringOperation.CreateElement(
                                AuthoringElement(
                                    id = id,
                                    page = PageId("related_page").ref(),
                                    elementType = type,
                                    schemaRevision = 1,
                                    name = "element",
                                    value = DataValue.StringValue("content"),
                                    placement = ElementPlacement.Graph(0, 0, 2, 1),
                                ),
                            )
                    val batch =
                        base.copy(
                            operations =
                                if (reject) {
                                    operations +
                                        AuthoringOperation.PatchPage(
                                            PageId("missing"),
                                            priority = ExpectedChange(0, 1),
                                        )
                                } else {
                                    operations
                                },
                        )
                    val result = fixture.authoring.apply(batch)
                    val document = fixture.pageDocuments.getPageDocument(PageId("related_page"))
                    if (reject) {
                        result.shouldBeInstanceOf<AuthoringBatchResult.Conflict>()
                        document shouldBe null
                        val library = fixture.authoring.snapshot(setOf(AuthoringSnapshotScope.Library))
                        (library.slices.single() as AuthoringSnapshotSlice.Library).books shouldBe emptyList()
                    } else {
                        result.shouldBeInstanceOf<AuthoringBatchResult.Applied>()
                        requireNotNull(document).elements.single().id shouldBe id
                        fixture.authoring.apply(batch) shouldBe result
                    }
                }
            }
        }
    }

    test("mixed batches are atomic, sequenced, and idempotent") {
        runTest {
            RepositoryFixture().use { fixture ->
                val batch = mixedCreateBatch("mixed")

                val first = fixture.authoring.apply(batch) as AuthoringBatchResult.Applied
                val replay = fixture.authoring.apply(batch) as AuthoringBatchResult.Applied
                val snapshot =
                    fixture.authoring.snapshot(
                        setOf(AuthoringSnapshotScope.Library, AuthoringSnapshotScope.Book(BookId("mixed_book"))),
                    )

                replay shouldBe first
                snapshot.sequence shouldBe first.change.sequence
                first.change.changes.map { it.resource } shouldContainExactly
                    listOf(
                        AuthoringResourceRef.Tag(TagId("mixed_tag")),
                        AuthoringResourceRef.Book(BookId("mixed_book")),
                        AuthoringResourceRef.Page(PageId("mixed_page")),
                    )
                (snapshot.slices[0] as AuthoringSnapshotSlice.Library).books.single().id shouldBe BookId("mixed_book")
                (snapshot.slices[1] as AuthoringSnapshotSlice.Book).pages.single().id shouldBe PageId("mixed_page")
            }
        }
    }

    test("independent fields merge while stale fields conflict with canonical values") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.createBook("merge_book", "before")

                fixture.authoring
                    .apply(
                        AuthoringBatch(
                            BatchId("change-title"),
                            listOf(
                                AuthoringOperation.PatchBook(
                                    BookId("merge_book"),
                                    title = ExpectedChange(LibraryName("before"), LibraryName("after")),
                                ),
                            ),
                        ),
                    ).shouldBeInstanceOf<AuthoringBatchResult.Applied>()
                fixture.authoring
                    .apply(
                        AuthoringBatch(
                            BatchId("change-icon"),
                            listOf(
                                AuthoringOperation.PatchBook(
                                    BookId("merge_book"),
                                    icon = ExpectedChange(Icon.parse("mdi:book"), Icon.parse("mdi:star")),
                                ),
                            ),
                        ),
                    ).shouldBeInstanceOf<AuthoringBatchResult.Applied>()

                val conflict =
                    fixture.authoring.apply(
                        AuthoringBatch(
                            BatchId("stale-title"),
                            listOf(
                                AuthoringOperation.PatchBook(
                                    BookId("merge_book"),
                                    title = ExpectedChange(LibraryName("before"), LibraryName("stale")),
                                ),
                            ),
                        ),
                    ) as AuthoringBatchResult.Conflict

                conflict.conflicts.single().actual shouldBe AuthoringPropertyValue.StringValue("after")
                val snapshot = fixture.authoring.snapshot(setOf(AuthoringSnapshotScope.Library))
                val book = (snapshot.slices.single() as AuthoringSnapshotSlice.Library).books.single()
                book.title shouldBe LibraryName("after")
                book.icon shouldBe Icon.parse("mdi:star")
            }
        }
    }

    test("later rejection rolls back earlier operations and sequence advancement") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.createBook("atomic_book", "before")
                val before = fixture.authoring.snapshot(setOf(AuthoringSnapshotScope.Library)).sequence

                val result =
                    fixture.authoring.apply(
                        AuthoringBatch(
                            BatchId("atomic-rejection"),
                            listOf(
                                AuthoringOperation.PatchBook(
                                    BookId("atomic_book"),
                                    title = ExpectedChange(LibraryName("before"), LibraryName("after")),
                                ),
                                AuthoringOperation.CreatePage(
                                    Page(
                                        id = PageId("orphan_page"),
                                        book = BookId("missing_book").ref(),
                                        name = LibraryName("orphan"),
                                        kind = TestPageKinds.STATIC.toLibrary(),
                                        chapter = ChapterPath.parse(""),
                                        priority = 0,
                                    ),
                                ),
                            ),
                        ),
                    )

                result.shouldBeInstanceOf<AuthoringBatchResult.Invalid>()
                val snapshot =
                    fixture.authoring.snapshot(
                        setOf(
                            AuthoringSnapshotScope.Library,
                            AuthoringSnapshotScope.Book(BookId("missing_book")),
                        ),
                    )
                val library = snapshot.slices[0] as AuthoringSnapshotSlice.Library
                val missingBook = snapshot.slices[1] as AuthoringSnapshotSlice.Book
                library.books.single { it.id == BookId("atomic_book") }.title shouldBe LibraryName("before")
                missingBook.pages shouldBe emptyList()
                snapshot.sequence shouldBe before
            }
        }
    }

    test("page lifecycle reports documents that reference the page") {
        runTest {
            RepositoryFixture().use { fixture ->
                val book = BookId("reference_book")
                val source = PageId("source_page")
                val target = PageId("target_page")
                fixture.createBook("reference_book")
                fixture.createPage("source_page", book, TestPageKinds.STATIC.toLibrary())
                val fixtureResponse =
                    fixture.database
                        .query(
                            """
                            CREATE element:referrer CONTENT {
                                element_type: 'test:entry',
                                schema_revision: 1,
                                name: 'Referrer',
                                value: {},
                                placement: { kind: 'graph_v1', x: 0, y: 0, width: 1, height: 1 }
                            };
                            RELATE page:source_page->contains_element:[page:source_page, element:referrer]->element:referrer;
                            RELATE element:referrer->element_reference:[element:referrer, 'target']->page:target_page
                                SET slot = 'target', expected_type = 'test/Page';
                            """.trimIndent(),
                        )
                for (index in 0 until fixtureResponse.size()) fixtureResponse.take(index)

                val created =
                    fixture.authoring.apply(
                        AuthoringBatch(
                            BatchId("create-target-page"),
                            listOf(AuthoringOperation.CreatePage(page(target, book, "target_page"))),
                        ),
                    ) as AuthoringBatchResult.Applied
                created.change.indirectlyAffectedResources shouldContainExactly
                    setOf(AuthoringResourceRef.Page(source))

                val patched =
                    fixture.authoring.apply(
                        AuthoringBatch(
                            BatchId("patch-target-page"),
                            listOf(
                                AuthoringOperation.PatchPage(
                                    target,
                                    name = ExpectedChange(LibraryName("target_page"), LibraryName("renamed_page")),
                                ),
                            ),
                        ),
                    ) as AuthoringBatchResult.Applied
                patched.change.indirectlyAffectedResources shouldContainExactly
                    setOf(AuthoringResourceRef.Page(source))

                val deleted =
                    fixture.authoring.apply(
                        AuthoringBatch(
                            BatchId("delete-target-page"),
                            listOf(AuthoringOperation.DeletePage(target)),
                        ),
                    ) as AuthoringBatchResult.Applied
                deleted.change.indirectlyAffectedResources shouldContainExactly
                    setOf(AuthoringResourceRef.Page(source))
            }
        }
    }
}

private fun page(
    id: PageId,
    book: BookId,
    name: String,
) = Page(
    id = id,
    book = book.ref(),
    name = LibraryName(name),
    kind = TestPageKinds.STATIC.toLibrary(),
    chapter = ChapterPath.parse(""),
    priority = 0,
)

private fun mixedCreateBatch(prefix: String): AuthoringBatch =
    AuthoringBatch(
        BatchId("$prefix-batch"),
        listOf(
            AuthoringOperation.CreateTag(
                TagId("${prefix}_tag"),
                LibraryName("${prefix}_tag"),
                Color(0u),
                emptyList(),
                GridPlacement(0, 0, 3, 1),
            ),
            AuthoringOperation.CreateBook(
                BookId("${prefix}_book"),
                LibraryName("${prefix}_book"),
                Icon.parse("mdi:book"),
                Color(0u),
                listOf(TagId("${prefix}_tag").ref()),
            ),
            AuthoringOperation.CreatePage(
                Page(
                    id = PageId("${prefix}_page"),
                    book = BookId("${prefix}_book").ref(),
                    name = LibraryName("${prefix}_page"),
                    kind = TestPageKinds.STATIC.toLibrary(),
                    chapter = ChapterPath.parse(""),
                    priority = 0,
                ),
            ),
        ),
    )
