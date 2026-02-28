package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import protokt.v1.typewriter.api.v1.CreateTagRequest
import protokt.v1.typewriter.api.v1.CreateTagResponse
import protokt.v1.typewriter.api.v1.DeleteTagRequest
import protokt.v1.typewriter.api.v1.DeleteTagResponse
import protokt.v1.typewriter.api.v1.GetTagRequest
import protokt.v1.typewriter.api.v1.GetTagResponse
import protokt.v1.typewriter.api.v1.ListTags
import protokt.v1.typewriter.api.v1.ListTagsRequest
import protokt.v1.typewriter.api.v1.ListTagsResponse
import protokt.v1.typewriter.api.v1.MoveTagRequest
import protokt.v1.typewriter.api.v1.MoveTagResponse
import protokt.v1.typewriter.api.v1.ResizeTagRequest
import protokt.v1.typewriter.api.v1.ResizeTagResponse
import protokt.v1.typewriter.api.v1.UpdateTagRequest
import protokt.v1.typewriter.api.v1.UpdateTagResponse
import protokt.v1.typewriter.models.v1.Color
import protokt.v1.typewriter.models.v1.Placement
import protokt.v1.typewriter.models.v1.Tag
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class TagRoutesTest : FunSpec({

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("list tags") {
        test("returns all tags from repository") {
            val mockRepo = mockk<TagRepository>()
            val tags = listOf(
                Tag { id = "tag:1"; name = "Tag1"; color = Color { value = 0xFF0000u } },
                Tag { id = "tag:2"; name = "Tag2"; color = Color { value = 0x00FF00u } }
            )
            coEvery { mockRepo.listTags() } returns tags

            val routes = TagRoutes(mockRepo)
            val request = ListTagsRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.list",
                data = serialize(request)
            )

            result.success shouldBe true
            result.replies.size shouldBe 1

            val response = ListTagsResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagsResult = response.result
            tagsResult.shouldBeInstanceOf<ListTagsResponse.Result.Tags>()
            tagsResult.tags.tags.size shouldBe 2
            tagsResult.tags.tags[0].name shouldBe "Tag1"
            tagsResult.tags.tags[1].name shouldBe "Tag2"
        }

        test("returns empty list when no tags exist") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.listTags() } returns emptyList()

            val routes = TagRoutes(mockRepo)
            val request = ListTagsRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.list",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ListTagsResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagsResult = response.result
            tagsResult.shouldBeInstanceOf<ListTagsResponse.Result.Tags>()
            tagsResult.tags.tags.size shouldBe 0
        }
    }

    context("get tag") {
        test("returns tag when found") {
            val mockRepo = mockk<TagRepository>()
            val tag = Tag { id = "tag:123"; name = "TestTag"; color = Color { value = 0xFF0000u } }
            coEvery { mockRepo.getTag("tag:123") } returns tag

            val routes = TagRoutes(mockRepo)
            val request = GetTagRequest { id = "tag:123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<GetTagResponse.Result.Tag>()
            tagResult.tag.name shouldBe "TestTag"
        }

        test("returns error when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.getTag("tag:missing") } returns null

            val routes = TagRoutes(mockRepo)
            val request = GetTagRequest { id = "tag:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.get",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = GetTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<GetTagResponse.Result.Error>()
            tagResult.error.message shouldBe "Tag not found: tag:missing"
        }
    }

    context("create tag") {
        test("creates tag and returns it") {
            val mockRepo = mockk<TagRepository>()
            val createdTag = Tag {
                id = "tag:new"
                name = "NewTag"
                color = Color { value = 0x0000FFu }
                placement = Placement { x = 10; y = 20 }
            }
            coEvery {
                mockRepo.createTag(
                    name = "NewTag",
                    color = 0x0000FF,
                    parentIds = emptyList(),
                    placement = any()
                )
            } returns createdTag

            val routes = TagRoutes(mockRepo)
            val request = CreateTagRequest {
                name = "NewTag"
                color = Color { value = 0x0000FFu }
                placement = Placement { x = 10; y = 20 }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<CreateTagResponse.Result.Tag>()
            tagResult.tag.name shouldBe "NewTag"
            tagResult.tag.id shouldBe "tag:new"
        }

        test("creates tag with parent ids") {
            val mockRepo = mockk<TagRepository>()
            val parentTag1 = Tag { id = "tag:parent1"; name = "Parent1" }
            val parentTag2 = Tag { id = "tag:parent2"; name = "Parent2" }
            val createdTag = Tag {
                id = "tag:child"
                name = "ChildTag"
                color = Color { value = 0x00FF00u }
                parents = listOf(parentTag1, parentTag2)
            }
            coEvery {
                mockRepo.createTag(
                    name = "ChildTag",
                    color = 0x00FF00,
                    parentIds = listOf("tag:parent1", "tag:parent2"),
                    placement = any()
                )
            } returns createdTag

            val routes = TagRoutes(mockRepo)
            val request = CreateTagRequest {
                name = "ChildTag"
                color = Color { value = 0x00FF00u }
                parentIds = listOf("tag:parent1", "tag:parent2")
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<CreateTagResponse.Result.Tag>()
            tagResult.tag.parents.size shouldBe 2
        }
    }

    context("update tag") {
        test("updates tag and returns it") {
            val mockRepo = mockk<TagRepository>()
            val updatedTag = Tag {
                id = "tag:existing"
                name = "UpdatedName"
                color = Color { value = 0xFFFFFFu }
            }
            coEvery { mockRepo.updateTag(any()) } returns updatedTag

            val routes = TagRoutes(mockRepo)
            val request = UpdateTagRequest {
                tag = Tag {
                    id = "tag:existing"
                    name = "UpdatedName"
                    color = Color { value = 0xFFFFFFu }
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<UpdateTagResponse.Result.Tag>()
            tagResult.tag.name shouldBe "UpdatedName"
        }

        test("returns error when tag is null in request") {
            val mockRepo = mockk<TagRepository>()
            val routes = TagRoutes(mockRepo)
            val request = UpdateTagRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.update",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = UpdateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<UpdateTagResponse.Result.Error>()
            tagResult.error.message shouldBe "Tag is required"
        }
    }

    context("delete tag") {
        test("deletes tag and returns success") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.deleteTag("tag:to-delete") } returns true

            val routes = TagRoutes(mockRepo)
            val request = DeleteTagRequest { id = "tag:to-delete" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.delete",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = DeleteTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val deleteResult = response.result
            deleteResult.shouldBeInstanceOf<DeleteTagResponse.Result.Success>()
            deleteResult.success shouldBe true
        }

        test("returns false when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.deleteTag("tag:missing") } returns false

            val routes = TagRoutes(mockRepo)
            val request = DeleteTagRequest { id = "tag:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.delete",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = DeleteTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val deleteResult = response.result
            deleteResult.shouldBeInstanceOf<DeleteTagResponse.Result.Success>()
            deleteResult.success shouldBe false
        }
    }

    context("move tag") {
        test("moves tag and returns success") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("tag:movable", 100, 200) } returns true

            val routes = TagRoutes(mockRepo)
            val request = MoveTagRequest { id = "tag:movable"; x = 100; y = 200 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe true

            coVerify { mockRepo.moveTag("tag:movable", 100, 200) }
        }

        test("returns false when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("tag:missing", 100, 200) } returns false

            val routes = TagRoutes(mockRepo)
            val request = MoveTagRequest { id = "tag:missing"; x = 100; y = 200 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe false
        }
    }

    context("resize tag") {
        test("resizes tag and returns success") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("tag:resizable", 300, 400) } returns true

            val routes = TagRoutes(mockRepo)
            val request = ResizeTagRequest { id = "tag:resizable"; width = 300; height = 400 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe true

            coVerify { mockRepo.resizeTag("tag:resizable", 300, 400) }
        }

        test("returns false when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("tag:missing", 300, 400) } returns false

            val routes = TagRoutes(mockRepo)
            val request = ResizeTagRequest { id = "tag:missing"; width = 300; height = 400 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.in.test-service.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe false
        }
    }
})
