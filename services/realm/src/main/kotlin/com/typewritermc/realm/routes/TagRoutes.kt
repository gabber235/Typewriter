package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.TagCreateResult
import com.typewritermc.realm.repository.TagDeleteResult
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.TagUpdateResult
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.DeleteTagResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag
import skirout.library.v1.tag.TagValidationError
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsResponse

internal class TagRoutes(
    private val tags: TagRepository,
    private val books: BookRepository,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchTags) {
                WatchTagsResponse.ListWrapper(childSpan("db.tag.list") { tags.listTags() })
            }
            watch(contracts.watchTag) { call ->
                call.request.tagId.invalidRecordId("tag")?.let {
                    return@watch WatchTagResponse.InvalidRecordIdErrorWrapper(it)
                }
                val tag =
                    childSpan("db.tag.get") { tags.getTag(call.request.tagId) }
                        ?: return@watch WatchTagResponse.createTagNotFoundError(tagId = call.request.tagId)
                WatchTagResponse.InitialWrapper(tag)
            }
            unary(contracts.createTag) { call -> create(call) }
            unary(contracts.updateTag) { call -> update(call) }
            unary(contracts.deleteTag) { call -> delete(call) }
        }

    context(main: MainSpanScope)
    private suspend fun create(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.tag.CreateTagRequest,
            CreateTagResponse,
        >,
    ): CreateTagResponse {
        val request = call.request
        val placement = request.placement ?: Placement(x = 0, y = 0, width = 4, height = 1)
        validate(request.name, placement)?.let { return CreateTagResponse.ValidationErrorWrapper(it) }
        request.parentIds.invalidRecordId("tag")?.let {
            return CreateTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        val missing = missingParents(request.parentIds)
        if (missing.isNotEmpty()) return CreateTagResponse.createParentsNotFoundError(parentIds = missing)
        val result =
            childSpan("db.tag.create") {
                tags.createTag(request.name, request.color ?: Color(argb = 0), request.parentIds, placement)
            }
        val tag =
            when (result) {
                is TagCreateResult.Success -> {
                    result.tag
                }

                TagCreateResult.NameInvalid -> {
                    return CreateTagResponse.ValidationErrorWrapper(TagValidationError.NAME_REQUIRED)
                }

                TagCreateResult.WidthInvalid -> {
                    return CreateTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
                }

                TagCreateResult.HeightInvalid -> {
                    return CreateTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
                }

                is TagCreateResult.ParentsNotFound -> {
                    return CreateTagResponse.createParentsNotFoundError(parentIds = result.parentIds)
                }
            }
        publish(call.communicator, WatchTagsResponse.AddWrapper(tag), WatchTagResponse.UpdateWrapper(tag))
        return CreateTagResponse.SuccessWrapper(tag)
    }

    context(main: MainSpanScope)
    private suspend fun update(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.tag.UpdateTagRequest,
            UpdateTagResponse,
        >,
    ): UpdateTagResponse {
        val request = call.request
        request.tagId.invalidRecordId("tag")?.let {
            return UpdateTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        request.parentIds.invalidRecordId("tag")?.let {
            return UpdateTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        val result =
            childSpan("db.tag.update") {
                tags.updateTag(
                    expectedRevision = request.expectedRevision,
                    Tag(
                        tagId = request.tagId,
                        revision = request.expectedRevision,
                        name = request.name,
                        color = request.color,
                        parentIds = request.parentIds,
                        placement = request.placement,
                    ),
                )
            }
        val tag =
            when (result) {
                is TagUpdateResult.Success -> {
                    result.tag
                }

                is TagUpdateResult.Conflict -> {
                    return UpdateTagResponse.createConflictError(
                        expectedRevision = request.expectedRevision,
                        actual = result.actual,
                    )
                }

                TagUpdateResult.NotFound -> {
                    return UpdateTagResponse.createTagNotFoundError(tagId = request.tagId)
                }

                TagUpdateResult.NameInvalid -> {
                    return UpdateTagResponse.ValidationErrorWrapper(TagValidationError.NAME_REQUIRED)
                }

                TagUpdateResult.WidthInvalid -> {
                    return UpdateTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
                }

                TagUpdateResult.HeightInvalid -> {
                    return UpdateTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
                }

                is TagUpdateResult.ParentsNotFound -> {
                    return UpdateTagResponse.createParentsNotFoundError(parentIds = result.parentIds)
                }

                TagUpdateResult.InheritanceCycle -> {
                    return UpdateTagResponse.ValidationErrorWrapper(TagValidationError.INHERITANCE_CYCLE)
                }
            }
        publish(call.communicator, WatchTagsResponse.UpdateWrapper(tag), WatchTagResponse.UpdateWrapper(tag))
        return UpdateTagResponse.SuccessWrapper(tag)
    }

    context(main: MainSpanScope)
    private suspend fun delete(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.tag.DeleteTagRequest,
            DeleteTagResponse,
        >,
    ): DeleteTagResponse {
        val id = call.request.tagId
        id.invalidRecordId("tag")?.let {
            return DeleteTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        val deletion =
            when (val result = childSpan("db.tag.delete") { tags.deleteTag(id) }) {
                is TagDeleteResult.Success -> result.deletion
                TagDeleteResult.NotFound -> return DeleteTagResponse.createTagNotFoundError(tagId = id)
            }
        publish(call.communicator, WatchTagsResponse.RemoveWrapper(id), WatchTagResponse.RemoveWrapper(id))
        for (childId in deletion.childTagIds) {
            val child = childSpan("db.tag.get") { tags.getTag(childId) } ?: continue
            publish(call.communicator, WatchTagsResponse.UpdateWrapper(child), WatchTagResponse.UpdateWrapper(child))
        }
        for (bookId in deletion.bookIds) {
            val book = childSpan("db.book.get") { books.getBook(bookId) } ?: continue
            call.communicator
                .publishUpdate(
                    contracts.watchBooks,
                    realmAddress,
                    WatchBooksResponse.UpdateWrapper(book),
                ).requirePublished()
            call.communicator
                .publishUpdate(
                    contracts.watchBook,
                    realmAddress,
                    skirout.library.v1.book.WatchBookResponse
                        .UpdateWrapper(book),
                ).requirePublished()
        }
        return DeleteTagResponse.createSuccess()
    }

    context(main: MainSpanScope)
    private suspend fun missingParents(parentIds: List<skirout.kernel.v1.record_id.RecordId>) =
        childSpan("db.tag.validate") { tags.findMissing(parentIds) }

    private suspend fun publish(
        communicator: Communicator,
        collection: WatchTagsResponse,
        resource: WatchTagResponse,
    ) {
        communicator.publishUpdate(contracts.watchTags, realmAddress, collection).requirePublished()
        communicator.publishUpdate(contracts.watchTag, realmAddress, resource).requirePublished()
    }

    private fun validate(
        name: String,
        placement: Placement,
    ): TagValidationError? =
        when {
            name.isBlank() -> TagValidationError.NAME_REQUIRED
            placement.width <= 0 -> TagValidationError.WIDTH_INVALID
            placement.height <= 0 -> TagValidationError.HEIGHT_INVALID
            else -> null
        }
}
