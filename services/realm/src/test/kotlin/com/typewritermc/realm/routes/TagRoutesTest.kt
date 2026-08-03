package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.recordId
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.tag.CreateTagRequest
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.DeleteTagRequest
import skirout.library.v1.tag.DeleteTagResponse
import skirout.library.v1.tag.MoveTagRequest
import skirout.library.v1.tag.MoveTagResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.ResizeTagRequest
import skirout.library.v1.tag.ResizeTagResponse
import skirout.library.v1.tag.UpdateTagRequest
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTagRequest
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsRequest
import skirout.library.v1.tag.WatchTagsResponse

val TagRoutesTest by testSuite {
    test("tag collection watch returns an empty initial state") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "tag.watch",
                        WatchTagsRequest(),
                        WatchTagsRequest.serializer,
                        WatchTagsResponse.serializer,
                    )

                response shouldBe WatchTagsResponse.ListWrapper(emptyList())
            }
        }
    }

    test("tag collection and resource watches return persisted state") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "tag_one",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val collection =
                    fixture.request(
                        "tag.watch",
                        WatchTagsRequest(),
                        WatchTagsRequest.serializer,
                        WatchTagsResponse.serializer,
                    )
                val resource =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = tag.tagId),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )

                collection.kind shouldBe WatchTagsResponse.Kind.LIST_WRAPPER
                resource.kind shouldBe WatchTagResponse.Kind.INITIAL_WRAPPER
            }
        }
    }

    test("tag resource watch classifies invalid and missing identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val invalid =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = recordId("book", "wrong")),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )
                val missingId = recordId("tag", "missing")
                val missing =
                    fixture.request(
                        "tag.resource.watch",
                        WatchTagRequest(tagId = missingId),
                        WatchTagRequest.serializer,
                        WatchTagResponse.serializer,
                    )

                invalid.kind shouldBe WatchTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missing shouldBe WatchTagResponse.createTagNotFoundError(tagId = missingId)
            }
        }
    }

    test("tag creation persists defaults and publishes both update channels") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "created_tag",
                            color = null,
                            parentIds = emptyList(),
                            placement = null,
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                response.kind shouldBe CreateTagResponse.Kind.SUCCESS_WRAPPER
                val tag =
                    fixture.repositories.tags
                        .listTags()
                        .single()
                tag.color shouldBe Color(argb = 0)
                tag.placement shouldBe Placement(x = 0, y = 0, width = 4, height = 1)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.AddWrapper(tag))
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(WatchTagResponse.UpdateWrapper(tag))
            }
        }
    }

    test("tag creation preserves explicit fields and parents and publishes exact payloads") {
        runTest {
            RouteFixture().use { fixture ->
                val parent =
                    fixture.repositories.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val response =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "explicit_tag",
                            color = Color(argb = 2),
                            parentIds = listOf(parent.tagId),
                            placement = Placement(x = 3, y = 4, width = 5, height = 2),
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                val tag =
                    fixture.repositories.tags
                        .listTags()
                        .single { it.tagId != parent.tagId }
                response shouldBe CreateTagResponse.SuccessWrapper(tag)
                tag.color shouldBe Color(argb = 2)
                tag.parentIds shouldContainExactly listOf(parent.tagId)
                tag.placement shouldBe Placement(x = 3, y = 4, width = 5, height = 2)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.AddWrapper(tag))
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(WatchTagResponse.UpdateWrapper(tag))
            }
        }
    }

    test("tag creation classifies invalid parent identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "invalid_parent_tag",
                            color = null,
                            parentIds = listOf(recordId("book", "wrong")),
                            placement = null,
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                response.kind shouldBe CreateTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.repositories.tags.listTags() shouldBe emptyList()
            }
        }
    }

    test("tag creation validates names and placement without mutation") {
        runTest {
            RouteFixture().use { fixture ->
                val blankName =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(name = " ", color = null, parentIds = emptyList(), placement = null),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )
                val invalidWidth =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "width_tag",
                            color = null,
                            parentIds = emptyList(),
                            placement = Placement(x = 0, y = 0, width = 0, height = 1),
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )
                val invalidHeight =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "height_tag",
                            color = null,
                            parentIds = emptyList(),
                            placement = Placement(x = 0, y = 0, width = 4, height = 0),
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                blankName.kind shouldBe CreateTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                invalidWidth.kind shouldBe CreateTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                invalidHeight.kind shouldBe CreateTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.tags.listTags() shouldBe emptyList()
                fixture.publishedTo("tag.watch") shouldBe emptyList()
            }
        }
    }

    test("tag updates persist changes and publish both update channels") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "tag_one",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val response =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = "updated_tag",
                            color = null,
                            parentIds = null,
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )

                response.kind shouldBe UpdateTagResponse.Kind.SUCCESS_WRAPPER
                val persisted = fixture.repositories.tags.getTag(tag.tagId) ?: error("Tag was not persisted")
                persisted.name shouldBe "updated_tag"
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.UpdateWrapper(persisted))
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(WatchTagResponse.UpdateWrapper(persisted))
            }
        }
    }

    test("tag updates preserve omitted fields") {
        runTest {
            RouteFixture().use { fixture ->
                val parent =
                    fixture.repositories.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 2),
                            listOf(parent.tagId),
                            Placement(x = 3, y = 4, width = 5, height = 2),
                        ).successValue()

                val response =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = null,
                            color = null,
                            parentIds = null,
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )

                response shouldBe UpdateTagResponse.SuccessWrapper(tag)
                fixture.repositories.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }

    test("tag updates reconcile parents and publish the exact persisted tag") {
        runTest {
            RouteFixture().use { fixture ->
                val firstParent =
                    fixture.repositories.tags
                        .createTag(
                            "first_parent",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val secondParent =
                    fixture.repositories.tags
                        .createTag(
                            "second_parent",
                            Color(argb = 2),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "changing_tag",
                            Color(argb = 3),
                            listOf(firstParent.tagId),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val response =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = null,
                            color = null,
                            parentIds = listOf(secondParent.tagId),
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )

                val updated = fixture.repositories.tags.getTag(tag.tagId) ?: error("Tag was not persisted")
                response shouldBe UpdateTagResponse.SuccessWrapper(updated)
                updated.parentIds shouldContainExactly listOf(secondParent.tagId)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.UpdateWrapper(updated))
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(WatchTagResponse.UpdateWrapper(updated))
            }
        }
    }

    test("tag update validation and parent errors leave the tag unchanged") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val wrongTarget =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = recordId("book", "wrong"),
                            name = null,
                            color = null,
                            parentIds = null,
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )
                val wrongParent =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = null,
                            color = null,
                            parentIds = listOf(recordId("book", "wrong")),
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )
                val missingParentId = recordId("tag", "missing")
                val missingParent =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = null,
                            color = null,
                            parentIds = listOf(missingParentId),
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )
                val blankName =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = " ",
                            color = null,
                            parentIds = null,
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )
                val invalidPlacement =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            name = null,
                            color = null,
                            parentIds = null,
                            placement = Placement(x = 0, y = 0, width = 4, height = 0),
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )

                wrongTarget.kind shouldBe UpdateTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                wrongParent.kind shouldBe UpdateTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                missingParent shouldBe UpdateTagResponse.createParentsNotFoundError(parentIds = listOf(missingParentId))
                blankName.kind shouldBe UpdateTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                invalidPlacement.kind shouldBe UpdateTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.tags.getTag(tag.tagId) shouldBe tag
                fixture.publishedTo("tag.watch") shouldBe emptyList()
            }
        }
    }

    test("tag movement and resizing persist geometry and publish updates") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "tag_one",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val moved =
                    fixture.request(
                        "tag.move",
                        MoveTagRequest(tagId = tag.tagId, x = 4, y = 5),
                        MoveTagRequest.serializer,
                        MoveTagResponse.serializer,
                    )
                val resized =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = tag.tagId, width = 6, height = 2),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )

                moved.kind shouldBe MoveTagResponse.Kind.SUCCESS_WRAPPER
                resized.kind shouldBe ResizeTagResponse.Kind.SUCCESS_WRAPPER
                fixture.repositories.tags
                    .getTag(tag.tagId)
                    ?.placement shouldBe
                    Placement(x = 4, y = 5, width = 6, height = 2)
                fixture.publishedTo("tag.watch") shouldHaveSize 2
                fixture.publishedTo("tag.resource.watch") shouldHaveSize 2
            }
        }
    }

    test("tag deletion reconciles related tags and books and publishes every update") {
        runTest {
            RouteFixture().use { fixture ->
                val parent =
                    fixture.repositories.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val child =
                    fixture.repositories.tags
                        .createTag(
                            "child_tag",
                            Color(argb = 2),
                            listOf(parent.tagId),
                            Placement(x = 1, y = 1, width = 4, height = 1),
                        ).successValue()
                val book =
                    fixture.repositories.books
                        .createBook(
                            "book_one",
                            "book",
                            Color(argb = 0),
                            listOf(parent.tagId),
                        ).successValue()

                val response =
                    fixture.request(
                        "tag.delete",
                        DeleteTagRequest(tagId = parent.tagId),
                        DeleteTagRequest.serializer,
                        DeleteTagResponse.serializer,
                    )

                response.kind shouldBe DeleteTagResponse.Kind.SUCCESS_WRAPPER
                fixture.repositories.tags
                    .getTag(child.tagId)
                    ?.parentIds shouldBe emptyList()
                fixture.repositories.books
                    .getBook(book.bookId)
                    ?.tagIds shouldBe emptyList()
                val updatedChild = fixture.repositories.tags.getTag(child.tagId) ?: error("Child tag was not persisted")
                val updatedBook = fixture.repositories.books.getBook(book.bookId) ?: error("Book was not persisted")
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(
                        WatchTagsResponse.RemoveWrapper(parent.tagId),
                        WatchTagsResponse.UpdateWrapper(updatedChild),
                    )
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(
                        WatchTagResponse.RemoveWrapper(parent.tagId),
                        WatchTagResponse.UpdateWrapper(updatedChild),
                    )
                fixture.publishedTo("book.watch", skirout.library.v1.book.WatchBooksResponse.serializer) shouldContainExactly
                    listOf(
                        skirout.library.v1.book.WatchBooksResponse
                            .UpdateWrapper(updatedBook),
                    )
                fixture.publishedTo(
                    "book.resource.watch",
                    skirout.library.v1.book.WatchBookResponse.serializer,
                ) shouldContainExactly
                    listOf(
                        skirout.library.v1.book.WatchBookResponse
                            .UpdateWrapper(updatedBook),
                    )
            }
        }
    }

    test("tag deletion classifies invalid identifiers") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "tag.delete",
                        DeleteTagRequest(tagId = recordId("book", "wrong")),
                        DeleteTagRequest.serializer,
                        DeleteTagResponse.serializer,
                    )

                response.kind shouldBe DeleteTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.publishedTo("tag.watch") shouldBe emptyList()
            }
        }
    }

    test("tag creation reports missing parents") {
        runTest {
            RouteFixture().use { fixture ->
                val response =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "tag_name",
                            color = null,
                            parentIds = listOf(recordId("tag", "missing")),
                            placement = Placement(x = 0, y = 0, width = 4, height = 1),
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                response.kind shouldBe CreateTagResponse.Kind.PARENTS_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("tag updates and deletion report missing tags") {
        runTest {
            RouteFixture().use { fixture ->
                val missingUpdate =
                    fixture.request(
                        "tag.update",
                        UpdateTagRequest(
                            tagId = recordId("tag", "missing"),
                            name = null,
                            color = null,
                            parentIds = null,
                            placement = null,
                        ),
                        UpdateTagRequest.serializer,
                        UpdateTagResponse.serializer,
                    )
                val missingDelete =
                    fixture.request(
                        "tag.delete",
                        DeleteTagRequest(tagId = recordId("tag", "missing")),
                        DeleteTagRequest.serializer,
                        DeleteTagResponse.serializer,
                    )

                missingUpdate.kind shouldBe UpdateTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
                missingDelete.kind shouldBe DeleteTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("tag geometry routes validate requests and report missing tags") {
        runTest {
            RouteFixture().use { fixture ->
                val invalidMove =
                    fixture.request(
                        "tag.move",
                        MoveTagRequest(tagId = recordId("tag", "missing"), x = null, y = null),
                        MoveTagRequest.serializer,
                        MoveTagResponse.serializer,
                    )
                val missingMove =
                    fixture.request(
                        "tag.move",
                        MoveTagRequest(tagId = recordId("tag", "missing"), x = 1, y = null),
                        MoveTagRequest.serializer,
                        MoveTagResponse.serializer,
                    )
                val invalidResize =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = recordId("tag", "missing"), width = 0, height = null),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )
                val missingResize =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = recordId("tag", "missing"), width = 1, height = null),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )

                invalidMove.kind shouldBe MoveTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                missingMove.kind shouldBe MoveTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
                invalidResize.kind shouldBe ResizeTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                missingResize.kind shouldBe ResizeTagResponse.Kind.TAG_NOT_FOUND_ERROR_WRAPPER
            }
        }
    }

    test("tag movement classifies invalid identifiers and supports partial coordinates") {
        runTest {
            RouteFixture().use { fixture ->
                val horizontal =
                    fixture.repositories.tags
                        .createTag(
                            "horizontal_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 2, width = 4, height = 1),
                        ).successValue()
                val vertical =
                    fixture.repositories.tags
                        .createTag(
                            "vertical_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 3, y = 0, width = 4, height = 1),
                        ).successValue()
                val invalid =
                    fixture.request(
                        "tag.move",
                        MoveTagRequest(tagId = recordId("book", "wrong"), x = 1, y = null),
                        MoveTagRequest.serializer,
                        MoveTagResponse.serializer,
                    )
                fixture.request(
                    "tag.move",
                    MoveTagRequest(tagId = horizontal.tagId, x = 6, y = null),
                    MoveTagRequest.serializer,
                    MoveTagResponse.serializer,
                )
                fixture.request(
                    "tag.move",
                    MoveTagRequest(tagId = vertical.tagId, x = null, y = 7),
                    MoveTagRequest.serializer,
                    MoveTagResponse.serializer,
                )

                invalid.kind shouldBe MoveTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.repositories.tags
                    .getTag(horizontal.tagId)
                    ?.placement shouldBe
                    Placement(x = 6, y = 2, width = 4, height = 1)
                fixture.repositories.tags
                    .getTag(vertical.tagId)
                    ?.placement shouldBe
                    Placement(x = 3, y = 7, width = 4, height = 1)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldHaveSize 2
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldHaveSize 2
            }
        }
    }

    test("tag resizing classifies invalid identifiers and supports partial dimensions") {
        runTest {
            RouteFixture().use { fixture ->
                val widthTag =
                    fixture.repositories.tags
                        .createTag(
                            "width_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 2),
                        ).successValue()
                val heightTag =
                    fixture.repositories.tags
                        .createTag(
                            "height_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 5, height = 1),
                        ).successValue()
                val invalid =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = recordId("book", "wrong"), width = 4, height = null),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )
                fixture.request(
                    "tag.resize",
                    ResizeTagRequest(tagId = widthTag.tagId, width = 7, height = null),
                    ResizeTagRequest.serializer,
                    ResizeTagResponse.serializer,
                )
                fixture.request(
                    "tag.resize",
                    ResizeTagRequest(tagId = heightTag.tagId, width = null, height = 4),
                    ResizeTagRequest.serializer,
                    ResizeTagResponse.serializer,
                )

                invalid.kind shouldBe ResizeTagResponse.Kind.INVALID_RECORD_ID_ERROR_WRAPPER
                fixture.repositories.tags
                    .getTag(widthTag.tagId)
                    ?.placement shouldBe
                    Placement(x = 0, y = 0, width = 7, height = 2)
                fixture.repositories.tags
                    .getTag(heightTag.tagId)
                    ?.placement shouldBe
                    Placement(x = 0, y = 0, width = 5, height = 4)
            }
        }
    }

    test("tag resizing rejects negative dimensions without mutation") {
        runTest {
            RouteFixture().use { fixture ->
                val tag =
                    fixture.repositories.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 2),
                        ).successValue()
                val negativeWidth =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = tag.tagId, width = -1, height = null),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )
                val negativeHeight =
                    fixture.request(
                        "tag.resize",
                        ResizeTagRequest(tagId = tag.tagId, width = null, height = -1),
                        ResizeTagRequest.serializer,
                        ResizeTagResponse.serializer,
                    )

                negativeWidth.kind shouldBe ResizeTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                negativeHeight.kind shouldBe ResizeTagResponse.Kind.VALIDATION_ERROR_WRAPPER
                fixture.repositories.tags.getTag(tag.tagId) shouldBe tag
                fixture.publishedTo("tag.watch") shouldBe emptyList()
            }
        }
    }

    test("tag publication failure remains observable after the tag is committed") {
        runTest {
            RouteFixture().use { fixture ->
                fixture.transport.failNextPublish(
                    com.typewritermc.services.libs.communicator.transport.TransportError
                        .Unavailable(),
                )

                val response =
                    fixture.request(
                        "tag.create",
                        CreateTagRequest(
                            name = "committed_tag",
                            color = null,
                            parentIds = emptyList(),
                            placement = null,
                        ),
                        CreateTagRequest.serializer,
                        CreateTagResponse.serializer,
                    )

                response.kind shouldBe CreateTagResponse.Kind.INTERNAL_ERROR_WRAPPER
                fixture.repositories.tags
                    .listTags()
                    .single()
                    .name shouldBe "committed_tag"
            }
        }
    }
}
