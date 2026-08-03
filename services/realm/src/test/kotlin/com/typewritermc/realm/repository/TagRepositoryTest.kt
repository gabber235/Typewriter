package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

val TagRepositoryTest by testSuite {
    test("tag listing is empty before any tags are created") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags.listTags() shouldBe emptyList()
            }
        }
    }

    test("tag listing is ordered by name") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags
                    .createTag(
                        "zulu_tag",
                        Color(argb = 1),
                        emptyList(),
                        Placement(x = 0, y = 0, width = 4, height = 1),
                    ).successValue()
                fixture.tags
                    .createTag(
                        "alpha_tag",
                        Color(argb = 2),
                        emptyList(),
                        Placement(x = 0, y = 0, width = 4, height = 1),
                    ).successValue()

                fixture.tags.listTags().map(Tag::name) shouldContainExactly listOf("alpha_tag", "zulu_tag")
            }
        }
    }

    test("tag creation preserves hierarchy and supports retrieval") {
        runTest {
            RepositoryFixture().use { fixture ->
                val parent =
                    fixture.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 3, height = 1),
                        ).successValue()
                val child =
                    fixture.tags
                        .createTag(
                            "child_tag",
                            Color(argb = 2),
                            listOf(parent.tagId),
                            Placement(x = 4, y = 5, width = 6, height = 2),
                        ).successValue()

                fixture.tags.listTags() shouldContainExactlyInAnyOrder listOf(parent, child)
                fixture.tags.getTag(child.tagId)?.parentIds shouldContainExactly listOf(parent.tagId)
            }
        }
    }

    test("missing tag lookup returns every absent identifier") {
        runTest {
            RepositoryFixture().use { fixture ->
                val missing = recordId("tag", "missing")

                fixture.tags.findMissing(listOf(missing)) shouldContainExactly listOf(missing)
            }
        }
    }

    test("missing tag lookup distinguishes existing and absent identifiers") {
        runTest {
            RepositoryFixture().use { fixture ->
                val existing =
                    fixture.tags
                        .createTag(
                            "existing_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val firstMissing = recordId("tag", "first_missing")
                val secondMissing = recordId("tag", "second_missing")

                fixture.tags.findMissing(listOf(existing.tagId, firstMissing, secondMissing)) shouldContainExactly
                    listOf(firstMissing, secondMissing)
                fixture.tags.findMissing(emptyList()) shouldBe emptyList()
            }
        }
    }

    test("tag movement and resizing preserve unspecified placement fields") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "movable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 1, width = 3, height = 2),
                        ).successValue()

                val moved = fixture.tags.moveTag(tag.tagId, 8, null).successValue()
                val resized = fixture.tags.resizeTag(tag.tagId, null, 4).successValue()

                moved.placement shouldBe Placement(x = 8, y = 1, width = 3, height = 2)
                resized.placement shouldBe Placement(x = 8, y = 1, width = 3, height = 4)
            }
        }
    }

    test("tag updates enforce positive placement sizes") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "sized_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 3, height = 1),
                        ).successValue()

                fixture.tags
                    .updateTag(
                        Tag(
                            tagId = tag.tagId,
                            name = tag.name,
                            color = tag.color,
                            parentIds = tag.parentIds,
                            placement = Placement(x = 0, y = 0, width = 0, height = 1),
                        ),
                    ).failureSlug() shouldBe "tag-width-invalid-error"
            }
        }
    }

    test("tag updates with missing parents roll back the record") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 0),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                fixture.tags
                    .updateTag(
                        Tag(
                            tagId = tag.tagId,
                            name = "uncommitted_tag",
                            color = tag.color,
                            parentIds = listOf(recordId("tag", "missing")),
                            placement = tag.placement,
                        ),
                    ).failureSlug() shouldBe "parents-not-found-error"

                fixture.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }

    test("tag deletion removes parent references from tags and books") {
        runTest {
            RepositoryFixture().use { fixture ->
                val parent =
                    fixture.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 3, height = 1),
                        ).successValue()
                val child =
                    fixture.tags
                        .createTag(
                            "child_tag",
                            Color(argb = 2),
                            listOf(parent.tagId),
                            Placement(x = 4, y = 5, width = 6, height = 2),
                        ).successValue()
                val book =
                    fixture.books
                        .createBook("tagged_book", "book", Color(argb = 0), listOf(parent.tagId))
                        .successValue()

                val deletion = fixture.tags.deleteTag(parent.tagId).successValue()

                deletion shouldBe TagDeletion(listOf(child.tagId), listOf(book.bookId))
                fixture.tags.getTag(parent.tagId).shouldBeNull()
                fixture.tags.getTag(child.tagId)?.parentIds shouldBe emptyList()
                fixture.books.getBook(book.bookId)?.tagIds shouldBe emptyList()
            }
        }
    }

    test("missing tag retrieval returns null") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags.getTag(recordId("tag", "missing")).shouldBeNull()
            }
        }
    }

    test("tag creation deduplicates repeated parent identifiers") {
        runTest {
            RepositoryFixture().use { fixture ->
                val parent =
                    fixture.tags
                        .createTag(
                            "parent_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                val child =
                    fixture.tags
                        .createTag(
                            "child_tag",
                            Color(argb = 2),
                            listOf(parent.tagId, parent.tagId),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                child.parentIds shouldContainExactly listOf(parent.tagId)
                fixture.tags.getTag(child.tagId)?.parentIds shouldContainExactly listOf(parent.tagId)
            }
        }
    }

    test("tag creation with missing parents rolls back the record") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags
                    .createTag(
                        "uncommitted_tag",
                        Color(argb = 1),
                        listOf(recordId("tag", "missing")),
                        Placement(x = 0, y = 0, width = 4, height = 1),
                    ).failureSlug() shouldBe "parents-not-found-error"

                fixture.tags.listTags() shouldBe emptyList()
            }
        }
    }

    test("tag updates replace fields and reconcile parent relations") {
        runTest {
            RepositoryFixture().use { fixture ->
                val firstParent =
                    fixture.tags
                        .createTag(
                            "first_parent",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val secondParent =
                    fixture.tags
                        .createTag(
                            "second_parent",
                            Color(argb = 2),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val tag =
                    fixture.tags
                        .createTag(
                            "changing_tag",
                            Color(argb = 3),
                            listOf(firstParent.tagId),
                            Placement(x = 1, y = 2, width = 4, height = 1),
                        ).successValue()

                val updated =
                    fixture.tags
                        .updateTag(
                            tag.copy(
                                name = "updated_tag",
                                color = Color(argb = 4),
                                parentIds = listOf(secondParent.tagId),
                                placement = Placement(x = 5, y = 6, width = 7, height = 8),
                            ),
                        ).successValue()

                updated.name shouldBe "updated_tag"
                updated.color shouldBe Color(argb = 4)
                updated.parentIds shouldContainExactly listOf(secondParent.tagId)
                updated.placement shouldBe Placement(x = 5, y = 6, width = 7, height = 8)
                fixture.tags.getTag(tag.tagId) shouldBe updated
            }
        }
    }

    test("tag update reports a missing tag") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags
                    .updateTag(
                        Tag(
                            tagId = recordId("tag", "missing"),
                            name = "missing_tag",
                            color = Color(argb = 0),
                            parentIds = emptyList(),
                            placement = Placement(x = 0, y = 0, width = 4, height = 1),
                        ),
                    ).failureSlug() shouldBe "tag-not-found-error"
            }
        }
    }

    test("tag update rejects invalid names and rolls back the record") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                listOf("ab", "Upper", "has space", "has-dash", "ümlaut", "_leading", "trailing_").forEach { name ->
                    fixture.tags.updateTag(tag.copy(name = name)).failureSlug() shouldBe "tag-name-invalid-error"
                    fixture.tags.getTag(tag.tagId) shouldBe tag
                }
            }
        }
    }

    test("tag update rejects invalid heights and rolls back the record") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()

                listOf(0, -1).forEach { height ->
                    fixture.tags.updateTag(tag.copy(placement = tag.placement.copy(height = height))).failureSlug() shouldBe
                        "tag-height-invalid-error"
                    fixture.tags.getTag(tag.tagId) shouldBe tag
                }
            }
        }
    }

    test("tag movement supports both coordinates and each coordinate independently") {
        runTest {
            RepositoryFixture().use { fixture ->
                val both =
                    fixture.tags
                        .createTag(
                            "both_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val horizontal =
                    fixture.tags
                        .createTag(
                            "horizontal_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 2, width = 4, height = 1),
                        ).successValue()
                val vertical =
                    fixture.tags
                        .createTag(
                            "vertical_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 3, y = 0, width = 4, height = 1),
                        ).successValue()

                fixture.tags
                    .moveTag(both.tagId, 4, 5)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 4, y = 5, width = 4, height = 1)
                fixture.tags
                    .moveTag(horizontal.tagId, 6, null)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 6, y = 2, width = 4, height = 1)
                fixture.tags
                    .moveTag(vertical.tagId, null, 7)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 3, y = 7, width = 4, height = 1)
            }
        }
    }

    test("tag movement with no coordinates is a repository no operation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 1, y = 2, width = 4, height = 1),
                        ).successValue()

                fixture.tags.moveTag(tag.tagId, null, null).successValue() shouldBe tag
                fixture.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }

    test("tag movement reports a missing tag") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags.moveTag(recordId("tag", "missing"), 1, 2).failureSlug() shouldBe "tag-not-found-error"
            }
        }
    }

    test("tag resizing supports both dimensions and each dimension independently") {
        runTest {
            RepositoryFixture().use { fixture ->
                val both =
                    fixture.tags
                        .createTag(
                            "both_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 1),
                        ).successValue()
                val widthOnly =
                    fixture.tags
                        .createTag(
                            "width_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 2),
                        ).successValue()
                val heightOnly =
                    fixture.tags
                        .createTag(
                            "height_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 5, height = 1),
                        ).successValue()

                fixture.tags
                    .resizeTag(both.tagId, 6, 3)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 0, y = 0, width = 6, height = 3)
                fixture.tags
                    .resizeTag(widthOnly.tagId, 7, null)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 0, y = 0, width = 7, height = 2)
                fixture.tags
                    .resizeTag(heightOnly.tagId, null, 4)
                    .successValue()
                    .placement shouldBe
                    Placement(x = 0, y = 0, width = 5, height = 4)
            }
        }
    }

    test("tag resizing with no dimensions is a repository no operation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 2),
                        ).successValue()

                fixture.tags.resizeTag(tag.tagId, null, null).successValue() shouldBe tag
                fixture.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }

    test("tag resizing rejects zero and negative dimensions without mutation") {
        runTest {
            RepositoryFixture().use { fixture ->
                val tag =
                    fixture.tags
                        .createTag(
                            "stable_tag",
                            Color(argb = 1),
                            emptyList(),
                            Placement(x = 0, y = 0, width = 4, height = 2),
                        ).successValue()

                fixture.tags.resizeTag(tag.tagId, 0, null).failureSlug() shouldBe "tag-width-invalid-error"
                fixture.tags.resizeTag(tag.tagId, -1, null).failureSlug() shouldBe "tag-width-invalid-error"
                fixture.tags.resizeTag(tag.tagId, null, 0).failureSlug() shouldBe "tag-height-invalid-error"
                fixture.tags.resizeTag(tag.tagId, null, -1).failureSlug() shouldBe "tag-height-invalid-error"
                fixture.tags.getTag(tag.tagId) shouldBe tag
            }
        }
    }

    test("tag resizing reports a missing tag") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags.resizeTag(recordId("tag", "missing"), 4, 2).failureSlug() shouldBe
                    "tag-not-found-error"
            }
        }
    }

    test("tag deletion reports a missing tag") {
        runTest {
            RepositoryFixture().use { fixture ->
                fixture.tags.deleteTag(recordId("tag", "missing")).failureSlug() shouldBe "tag-not-found-error"
            }
        }
    }
}
