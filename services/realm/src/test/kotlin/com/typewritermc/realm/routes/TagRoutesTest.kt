package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.routing.testing.testRoute
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.utils.StateProvider
import com.typewritermc.services.libs.utils.asDeferredProvider
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.coEvery
import io.mockk.coVerify
import io.mockk.mockk
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Color
import protokt.v1.typewriter.models.v1.Placement
import protokt.v1.typewriter.models.v1.Tag
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream

class TagRoutesTest : FunSpec({

    val credentials = Credential(id = "test-service", name = "Test Service", token = "test-token").asDeferredProvider()
    val registrationStateProvider = StateProvider<RegistrationState>(
        RegistrationState.Bound(organizationId = "test-org", organizationName = "Test Organization")
    )

    fun serialize(message: protokt.v1.AbstractMessage): ByteArray {
        return ByteArrayOutputStream().also { message.serialize(it) }.toByteArray()
    }

    context("list tags") {
        test("returns all tags from repository") {
            val mockRepo = mockk<TagRepository>()
            val tags = listOf(
                Tag { tagId = "tag:1"; name = "Tag1"; color = Color { value = 0xFF0000u } },
                Tag { tagId = "tag:2"; name = "Tag2"; color = Color { value = 0x00FF00u } }
            )
            coEvery { mockRepo.listTags() } returns tags

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ListTagsRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.list",
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

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ListTagsRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.list",
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
            val tag = Tag { tagId = "tag:123"; name = "TestTag"; color = Color { value = 0xFF0000u } }
            coEvery { mockRepo.getTag("tag:123") } returns tag

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetTagRequest { tagId = "tag:123" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.get",
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

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = GetTagRequest { tagId = "tag:missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.get",
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
                tagId = "tag:new"
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

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateTagRequest {
                name = "NewTag"
                color = Color { value = 0x0000FFu }
                placement = Placement { x = 10; y = 20 }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<CreateTagResponse.Result.Tag>()
            tagResult.tag.name shouldBe "NewTag"
            tagResult.tag.tagId shouldBe "tag:new"
        }

        test("creates tag with parent ids") {
            val mockRepo = mockk<TagRepository>()
            val createdTag = Tag {
                tagId = "tag:child"
                name = "ChildTag"
                color = Color { value = 0x00FF00u }
                parentIds = listOf("parent1", "parent2")
            }
            coEvery {
                mockRepo.createTag(
                    name = "ChildTag",
                    color = 0x00FF00,
                    parentIds = listOf("parent1", "parent2"),
                    placement = any()
                )
            } returns createdTag

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateTagRequest {
                name = "ChildTag"
                color = Color { value = 0x00FF00u }
                parentIds = listOf("parent1", "parent2")
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<CreateTagResponse.Result.Tag>()
            tagResult.tag.parentIds.size shouldBe 2
            tagResult.tag.parentIds shouldContainExactlyInAnyOrder listOf("parent1", "parent2")
        }

        test("creates tag without placement uses defaults") {
            val mockRepo = mockk<TagRepository>()
            val createdTag = Tag {
                tagId = "tag:no-placement"
                name = "NoPlacement"
                color = Color { value = 0x0000FFu }
                placement = Placement {}
            }
            coEvery {
                mockRepo.createTag(
                    name = "NoPlacement",
                    color = 0x0000FF,
                    parentIds = emptyList(),
                    placement = any()
                )
            } returns createdTag

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = CreateTagRequest {
                name = "NoPlacement"
                color = Color { value = 0x0000FFu }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.create",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = CreateTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val tagResult = response.result
            tagResult.shouldBeInstanceOf<CreateTagResponse.Result.Tag>()
            tagResult.tag.name shouldBe "NoPlacement"
            tagResult.tag.tagId shouldBe "tag:no-placement"
        }
    }

    context("update tag") {
        test("updates tag and returns it") {
            val mockRepo = mockk<TagRepository>()
            val updatedTag = Tag {
                tagId = "existing"
                name = "UpdatedName"
                color = Color { value = 0xFFFFFFu }
            }
            coEvery { mockRepo.updateTag(any()) } returns updatedTag

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdateTagRequest {
                tag = Tag {
                    tagId = "existing"
                    name = "UpdatedName"
                    color = Color { value = 0xFFFFFFu }
                }
            }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.update",
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
            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = UpdateTagRequest {}

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.update",
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
            coEvery { mockRepo.deleteTag("to-delete") } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = DeleteTagRequest { tagId = "to-delete" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.delete",
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
            coEvery { mockRepo.deleteTag("missing") } returns false

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = DeleteTagRequest { tagId = "missing" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.delete",
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
        test("moves tag with only x provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("movable", 50, null) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = MoveTagRequest { tagId = "movable"; x = 50 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe true

            coVerify { mockRepo.moveTag("movable", 50, null) }
        }

        test("moves tag with only y provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("movable", null, 75) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = MoveTagRequest { tagId = "movable"; y = 75 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe true

            coVerify { mockRepo.moveTag("movable", null, 75) }
        }

        test("moves tag with no coordinates provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("movable", null, null) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = MoveTagRequest { tagId = "movable" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe true

            coVerify { mockRepo.moveTag("movable", null, null) }
        }
        test("moves tag and returns success") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("movable", 100, 200) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = MoveTagRequest { tagId = "movable"; x = 100; y = 200 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.move",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = MoveTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val moveResult = response.result
            moveResult.shouldBeInstanceOf<MoveTagResponse.Result.Success>()
            moveResult.success shouldBe true

            coVerify { mockRepo.moveTag("movable", 100, 200) }
        }

        test("returns false when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.moveTag("missing", 100, 200) } returns false

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = MoveTagRequest { tagId = "missing"; x = 100; y = 200 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.move",
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
            coEvery { mockRepo.resizeTag("resizable", 300, 400) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ResizeTagRequest { tagId = "resizable"; width = 300; height = 400 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe true

            coVerify { mockRepo.resizeTag("resizable", 300, 400) }
        }

        test("returns false when tag not found") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("missing", 300, 400) } returns false

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ResizeTagRequest { tagId = "missing"; width = 300; height = 400 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe false
        }

        test("resizes tag with only width provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("resizable", 200, null) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ResizeTagRequest { tagId = "resizable"; width = 200 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe true

            coVerify { mockRepo.resizeTag("resizable", 200, null) }
        }

        test("resizes tag with only height provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("resizable", null, 300) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ResizeTagRequest { tagId = "resizable"; height = 300 }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe true

            coVerify { mockRepo.resizeTag("resizable", null, 300) }
        }

        test("resizes tag with no dimensions provided") {
            val mockRepo = mockk<TagRepository>()
            coEvery { mockRepo.resizeTag("resizable", null, null) } returns true

            val routes = TagRoutes(mockRepo, credentials, registrationStateProvider)
            val request = ResizeTagRequest { tagId = "resizable" }

            val result = testRoute(
                routing = routes.configure(),
                subject = "realm.to.test-service.organization.test-org.tag.resize",
                data = serialize(request)
            )

            result.success shouldBe true
            val response = ResizeTagResponse.deserialize(ByteArrayInputStream(result.replies[0]))
            val resizeResult = response.result
            resizeResult.shouldBeInstanceOf<ResizeTagResponse.Result.Success>()
            resizeResult.success shouldBe true

            coVerify { mockRepo.resizeTag("resizable", null, null) }
        }
    }
})
