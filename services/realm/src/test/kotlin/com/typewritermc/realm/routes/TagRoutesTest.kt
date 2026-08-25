package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.createTag
import com.typewritermc.realm.repository.getTag
import com.typewritermc.realm.repository.successValue
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.test.runTest
import skirout.kernel.v1.color.Color
import skirout.kernel.v1.record_id.RecordId
import skirout.library.v1.tag.CreateTagRequest
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.TagValidationError
import skirout.library.v1.tag.UpdateTagRequest
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsResponse

val TagRoutesTest by testSuite {
    test("tag creation starts at revision one") {
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

                val tag = (response as CreateTagResponse.SuccessWrapper).value
                tag.revision shouldBe 1
                tag.placement shouldBe Placement(x = 0, y = 0, width = 4, height = 1)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.AddWrapper(tag))
            }
        }
    }

    test("tag update replaces fields parents and placement") {
        runTest {
            RouteFixture().use { fixture ->
                val parent = fixture.createTag("parent_tag")
                val tag = fixture.createTag("editable_tag")

                val response =
                    fixture.updateTag(
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            expectedRevision = tag.revision,
                            name = "updated_tag",
                            color = Color(argb = 4),
                            parentIds = listOf(parent.tagId),
                            placement = Placement(x = 5, y = 6, width = 7, height = 2),
                        ),
                    )

                val updated = (response as UpdateTagResponse.SuccessWrapper).value
                updated.revision shouldBe 2
                updated.name shouldBe "updated_tag"
                updated.parentIds shouldContainExactly listOf(parent.tagId)
                updated.placement shouldBe Placement(x = 5, y = 6, width = 7, height = 2)
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.UpdateWrapper(updated))
                fixture.publishedTo("tag.resource.watch", WatchTagResponse.serializer) shouldContainExactly
                    listOf(WatchTagResponse.UpdateWrapper(updated))
            }
        }
    }

    test("stale tag update returns the canonical entity without writing") {
        runTest {
            RouteFixture().use { fixture ->
                val tag = fixture.createTag("original_tag")
                val first =
                    fixture.updateTag(
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            expectedRevision = tag.revision,
                            name = "first_update",
                            color = tag.color,
                            parentIds = tag.parentIds,
                            placement = tag.placement,
                        ),
                    ) as UpdateTagResponse.SuccessWrapper

                val conflict =
                    fixture.updateTag(
                        UpdateTagRequest(
                            tagId = tag.tagId,
                            expectedRevision = tag.revision,
                            name = "stale_update",
                            color = tag.color,
                            parentIds = tag.parentIds,
                            placement = tag.placement,
                        ),
                    )

                conflict shouldBe
                    UpdateTagResponse.createConflictError(
                        expectedRevision = tag.revision,
                        actual = first.value,
                    )
                fixture.repositories.tags.getTag(tag.tagId) shouldBe first.value
                fixture.publishedTo("tag.watch", WatchTagsResponse.serializer) shouldContainExactly
                    listOf(WatchTagsResponse.UpdateWrapper(first.value))
            }
        }
    }

    test("tag update rejects direct and transitive inheritance cycles") {
        runTest {
            RouteFixture().use { fixture ->
                val root = fixture.createTag("root_tag")
                val child = fixture.createTag("child_tag", listOf(root.tagId))

                val direct =
                    fixture.updateTag(
                        UpdateTagRequest(
                            tagId = root.tagId,
                            expectedRevision = root.revision,
                            name = root.name,
                            color = root.color,
                            parentIds = listOf(root.tagId),
                            placement = root.placement,
                        ),
                    )
                val transitive =
                    fixture.updateTag(
                        UpdateTagRequest(
                            tagId = root.tagId,
                            expectedRevision = root.revision,
                            name = root.name,
                            color = root.color,
                            parentIds = listOf(child.tagId),
                            placement = root.placement,
                        ),
                    )

                direct shouldBe UpdateTagResponse.ValidationErrorWrapper(TagValidationError.INHERITANCE_CYCLE)
                transitive shouldBe UpdateTagResponse.ValidationErrorWrapper(TagValidationError.INHERITANCE_CYCLE)
                fixture.repositories.tags.getTag(root.tagId) shouldBe root
                fixture.publishedTo("tag.watch") shouldBe emptyList()
            }
        }
    }
}

private suspend fun RouteFixture.createTag(
    name: String,
    parentIds: List<RecordId> = emptyList(),
) = repositories.tags
    .createTag(
        name,
        Color(argb = 1),
        parentIds,
        Placement(x = 0, y = 0, width = 4, height = 1),
    ).successValue()

private suspend fun RouteFixture.updateTag(request: UpdateTagRequest): UpdateTagResponse =
    request(
        "tag.update",
        request,
        UpdateTagRequest.serializer,
        UpdateTagResponse.serializer,
    )
