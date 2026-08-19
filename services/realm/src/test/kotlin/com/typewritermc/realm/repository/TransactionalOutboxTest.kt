package com.typewritermc.realm.repository

import com.typewritermc.realm.routes.LibraryContracts
import com.typewritermc.realm.routes.RealmAddress
import com.typewritermc.realm.routes.encodeUpdate
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.WatchBookResponse
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.page.PageType
import skirout.library.v1.page.WatchPageResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsResponse

val TransactionalOutboxTest by testSuite {
    test("book page and tag mutations persist the existing serialized watch bytes") {
        runTest {
            RepositoryFixture().use { fixture ->
                val contracts = LibraryContracts(RealmAddress("realm", "organization"))
                val book =
                    fixture.books
                        .createBook("encoded_book", "book", Color(argb = 1), emptyList()) { canonical ->
                            listOf(
                                contracts.watchBooks.encodeUpdate(
                                    RealmAddress("realm", "organization"),
                                    WatchBooksResponse.AddWrapper(canonical),
                                ),
                            )
                        }.successValue()
                val page =
                    fixture.pages
                        .createPage(book.bookId, "encoded_page", PageType.STATIC, "", 0) { canonical ->
                            listOf(
                                contracts.watchPage.encodeUpdate(
                                    RealmAddress("realm", "organization"),
                                    WatchPageResponse.UpdateWrapper(canonical),
                                ),
                            )
                        }.successValue()
                val tag =
                    fixture.tags
                        .createTag(
                            "encoded_tag",
                            Color(argb = 2),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ) { canonical ->
                            listOf(
                                contracts.watchTags.encodeUpdate(
                                    RealmAddress("realm", "organization"),
                                    WatchTagsResponse.AddWrapper(canonical),
                                ),
                            )
                        }.successValue()

                val pending = fixture.outbox.pending(10)
                pending.map {
                    it.event.payload
                        .toByteArray()
                        .toList()
                } shouldContainExactly
                    listOf(
                        WatchBooksResponse.serializer
                            .toBytes(WatchBooksResponse.AddWrapper(book))
                            .toByteArray()
                            .toList(),
                        WatchPageResponse.serializer
                            .toBytes(WatchPageResponse.UpdateWrapper(page))
                            .toByteArray()
                            .toList(),
                        WatchTagsResponse.serializer
                            .toBytes(WatchTagsResponse.AddWrapper(tag))
                            .toByteArray()
                            .toList(),
                    )
            }
        }
    }

    test("encoder failure rolls back canonical state and outbox rows") {
        runTest {
            RepositoryFixture().use { fixture ->
                shouldThrow<IllegalStateException> {
                    fixture.books.createBook("rolled_back", "book", Color(argb = 0), emptyList()) {
                        error("encoding failed")
                    }
                }

                fixture.books.listBooks() shouldBe emptyList()
                fixture.outbox.pending(10) shouldBe emptyList()
            }
        }
    }

    test("tag deletion commits every canonical fanout event in one transaction") {
        runTest {
            RepositoryFixture().use { fixture ->
                val address = RealmAddress("realm", "organization")
                val contracts = LibraryContracts(address)
                val parent =
                    fixture.tags
                        .createTag(
                            "parent",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                fixture.tags
                    .createTag(
                        "child",
                        Color(argb = 2),
                        listOf(parent.tagId),
                        Placement(x = 0, y = 0, width = 4, height = 1),
                    ).successValue()
                fixture.books.createBook("tagged", "book", Color(argb = 0), listOf(parent.tagId)).successValue()

                fixture.tags
                    .deleteTag(parent.tagId) { deletion ->
                        buildList {
                            add(contracts.watchTags.encodeUpdate(address, WatchTagsResponse.RemoveWrapper(parent.tagId)))
                            add(contracts.watchTag.encodeUpdate(address, WatchTagResponse.RemoveWrapper(parent.tagId)))
                            deletion.childTags.forEach { child ->
                                add(contracts.watchTags.encodeUpdate(address, WatchTagsResponse.UpdateWrapper(child)))
                                add(contracts.watchTag.encodeUpdate(address, WatchTagResponse.UpdateWrapper(child)))
                            }
                            deletion.books.forEach { book ->
                                add(contracts.watchBooks.encodeUpdate(address, WatchBooksResponse.UpdateWrapper(book)))
                                add(contracts.watchBook.encodeUpdate(address, WatchBookResponse.UpdateWrapper(book)))
                            }
                        }
                    }.successValue()

                fixture.outbox.pending(10).size shouldBe 6
            }
        }
    }
}
