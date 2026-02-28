package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
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
import protokt.v1.typewriter.models.v1.Error
import protokt.v1.typewriter.models.v1.Placement

class TagRoutes(
    private val tagRepository: TagRepository
) {
    fun configure(): NatsRouting.() -> Unit = {
        route("realm.in.{serviceId}") {
            handle("tag.list") {
                receive<ListTagsRequest>(ListTagsRequest)
                val tags = tagRepository.listTags()
                val response = ListTagsResponse {
                    result = ListTagsResponse.Result.Tags(ListTags { this.tags = tags })
                }
                reply(response)
            }

            handle("tag.get") {
                val request = receive<GetTagRequest>(GetTagRequest)
                val tag = tagRepository.getTag(request.id)
                val response = if (tag != null) {
                    GetTagResponse { result = GetTagResponse.Result.Tag(tag) }
                } else {
                    GetTagResponse {
                        result = GetTagResponse.Result.Error(Error { message = "Tag not found: ${request.id}" })
                    }
                }
                reply(response)
            }

            handle("tag.create") {
                val request = receive<CreateTagRequest>(CreateTagRequest)
                val placement = request.placement ?: Placement {}
                val color = request.color?.value?.toInt() ?: 0
                val tag = tagRepository.createTag(
                    name = request.name,
                    color = color,
                    parentIds = request.parentIds,
                    placement = placement
                )
                val response = CreateTagResponse { result = CreateTagResponse.Result.Tag(tag) }
                reply(response)
            }

            handle("tag.update") {
                val request = receive<UpdateTagRequest>(UpdateTagRequest)
                val tag = request.tag
                if (tag == null) {
                    val response = UpdateTagResponse {
                        result = UpdateTagResponse.Result.Error(Error { message = "Tag is required" })
                    }
                    reply(response)
                    return@handle
                }
                val updatedTag = tagRepository.updateTag(tag)
                val response = UpdateTagResponse { result = UpdateTagResponse.Result.Tag(updatedTag) }
                reply(response)
            }

            handle("tag.delete") {
                val request = receive<DeleteTagRequest>(DeleteTagRequest)
                val success = tagRepository.deleteTag(request.id)
                val response = DeleteTagResponse { result = DeleteTagResponse.Result.Success(success) }
                reply(response)
            }

            handle("tag.move") {
                val request = receive<MoveTagRequest>(MoveTagRequest)
                val success = tagRepository.moveTag(request.id, request.x, request.y)
                val response = MoveTagResponse { result = MoveTagResponse.Result.Success(success) }
                reply(response)
            }

            handle("tag.resize") {
                val request = receive<ResizeTagRequest>(ResizeTagRequest)
                val success = tagRepository.resizeTag(request.id, request.width, request.height)
                val response = ResizeTagResponse { result = ResizeTagResponse.Result.Success(success) }
                reply(response)
            }
        }
    }
}
