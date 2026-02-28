package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.services.libs.communicator.routing.NatsRouting
import com.typewritermc.services.libs.registrar.Credential
import com.typewritermc.services.libs.registrar.RegistrationState
import com.typewritermc.services.libs.telemetry.timed
import com.typewritermc.services.libs.utils.DeferredProvider
import com.typewritermc.services.libs.utils.StateProvider
import io.opentelemetry.api.trace.StatusCode
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Error
import protokt.v1.typewriter.models.v1.Placement

class TagRoutes(
    private val tagRepository: TagRepository,
    private val credentials: DeferredProvider<Credential>,
    private val registrationStateProvider: StateProvider<RegistrationState>,
) {
    fun configure(): NatsRouting.() -> Unit = {
        val serviceId = credentials.require { "TagRoutes requires the credentials to be set to register" }.id
        val orgId = when (val state = registrationStateProvider.get()) {
            is RegistrationState.Bound -> state.organizationId
            else -> error("Service must be bound to an organization before routes can be configured")
        }
        route("realm.to.${serviceId}.organization.${orgId}") {
            handle("tag.list") {
                receive(ListTagsRequest)
                span.setAttribute("operation", "tag.list")

                val tags = span.timed("db.tag.list") {
                    tagRepository.listTags()
                }
                span.setAttribute("result.count", tags.size.toLong())

                val response = ListTagsResponse {
                    result = ListTagsResponse.Result.Tags(ListTags { this.tags = tags })
                }
                reply(response)
            }

            handle("tag.get") {
                val request = receive(GetTagRequest)
                span.setAttribute("operation", "tag.get")
                val tagId = request.tagId.ifBlank {
                    return@handle reply(
                        GetTagResponse {
                            result = GetTagResponse.Result.Error(Error { message = "id is required" })
                        }
                    )
                }
                span.setAttribute("tag.id", tagId)

                val tag = span.timed("db.tag.get") {
                    tagRepository.getTag(tagId)
                }

                val response = if (tag != null) {
                    GetTagResponse { result = GetTagResponse.Result.Tag(tag) }
                } else {
                    span.setStatus(StatusCode.ERROR, "Tag not found: $tagId")
                    GetTagResponse {
                        result = GetTagResponse.Result.Error(Error { message = "Tag not found: $tagId" })
                    }
                }
                reply(response)
            }

            handle("tag.create") {
                val request = receive(CreateTagRequest)
                span.setAttribute("operation", "tag.create")
                val name = request.name
                span.setAttribute("tag.name", name)

                val placement = request.placement ?: Placement {}
                val color = request.color?.value?.toInt() ?: 0

                val tag = span.timed("db.tag.create") {
                    tagRepository.createTag(
                        name = name,
                        color = color,
                        parentIds = request.parentIds,
                        placement = placement
                    )
                }
                span.setAttribute("tag.id", tag.tagId)

                val response = CreateTagResponse { result = CreateTagResponse.Result.Tag(tag) }
                reply(response)
            }

            handle("tag.update") {
                val request = receive(UpdateTagRequest)
                span.setAttribute("operation", "tag.update")

                val tag = request.tag
                if (tag == null) {
                    span.setStatus(StatusCode.ERROR, "Tag is required")
                    val response = UpdateTagResponse {
                        result = UpdateTagResponse.Result.Error(Error { message = "Tag is required" })
                    }
                    reply(response)
                    return@handle
                }
                span.setAttribute("tag.id", tag.tagId)

                val updatedTag = span.timed("db.tag.update") {
                    tagRepository.updateTag(tag)
                }
                val response = UpdateTagResponse { result = UpdateTagResponse.Result.Tag(updatedTag) }
                reply(response)
            }

            handle("tag.delete") {
                val request = receive<DeleteTagRequest>(DeleteTagRequest)
                span.setAttribute("operation", "tag.delete")
                val tagId = request.tagId.ifBlank {
                    return@handle reply(
                        DeleteTagResponse {
                            result = DeleteTagResponse.Result.Error(Error { message = "tag id is required" })
                        }
                    )
                }
                span.setAttribute("tag.id", tagId)

                val success = span.timed("db.tag.delete") {
                    tagRepository.deleteTag(tagId)
                }
                span.setAttribute("result.success", success)

                val response = DeleteTagResponse { result = DeleteTagResponse.Result.Success(success) }
                reply(response)
            }

            handle("tag.move") {
                val request = receive(MoveTagRequest)
                span.setAttribute("operation", "tag.move")
                val tagId = request.tagId.ifBlank {
                    return@handle reply(
                        MoveTagResponse {
                            result = MoveTagResponse.Result.Error(Error { message = "id is required" })
                        }
                    )
                }
                val x = request.x
                val y = request.y
                span.setAttribute("tag.id", tagId)
                x?.let { span.setAttribute("tag.x", it.toDouble()) }
                y?.let { span.setAttribute("tag.y", it.toDouble()) }

                val success = span.timed("db.tag.move") {
                    tagRepository.moveTag(tagId, x, y)
                }
                span.setAttribute("result.success", success)

                val response = MoveTagResponse { result = MoveTagResponse.Result.Success(success) }
                reply(response)
            }

            handle("tag.resize") {
                val request = receive(ResizeTagRequest)
                span.setAttribute("operation", "tag.resize")
                val tagId = request.tagId.ifBlank {
                    return@handle reply(
                        ResizeTagResponse {
                            result = ResizeTagResponse.Result.Error(Error { message = "id is required" })
                        }
                    )
                }
                val width = request.width
                val height = request.height
                span.setAttribute("tag.id", tagId)
                width?.let { span.setAttribute("tag.width", it.toDouble()) }
                height?.let { span.setAttribute("tag.height", it.toDouble()) }

                val success = span.timed("db.tag.resize") {
                    tagRepository.resizeTag(tagId, width, height)
                }
                span.setAttribute("result.success", success)

                val response = ResizeTagResponse { result = ResizeTagResponse.Result.Success(success) }
                reply(response)
            }
        }
    }
}
