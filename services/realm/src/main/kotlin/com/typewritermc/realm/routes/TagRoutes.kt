package com.typewritermc.realm.routes

import com.typewritermc.realm.repository.BookRepository
import com.typewritermc.realm.repository.RepositoryResult
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.kernel.v1.color.Color
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.DeleteTagResponse
import skirout.library.v1.tag.MoveTagResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.ResizeTagResponse
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
    fun register(builder: CommunicatorRoutesBuilder) = with(builder) {
        watch(contracts.watchTags) {
            WatchTagsResponse.ListWrapper(childSpan("db.tag.list") { tags.listTags() })
        }
        watch(contracts.watchTag) { call ->
            call.request.tagId.invalidRecordId("tag")?.let {
                return@watch WatchTagResponse.InvalidRecordIdErrorWrapper(it)
            }
            val tag = childSpan("db.tag.get") { tags.getTag(call.request.tagId) }
                ?: return@watch WatchTagResponse.createTagNotFoundError(tagId = call.request.tagId)
            WatchTagResponse.InitialWrapper(tag)
        }
        unary(contracts.createTag) { call -> create(call) }
        unary(contracts.updateTag) { call -> update(call) }
        unary(contracts.deleteTag) { call -> delete(call) }
        unary(contracts.moveTag) { call -> move(call) }
        unary(contracts.resizeTag) { call -> resize(call) }
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
        val result = childSpan("db.tag.create") {
            tags.createTag(request.name, request.color ?: Color(argb = 0), request.parentIds, placement)
        }
        val tag = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "tag-name-invalid-error" -> CreateTagResponse.ValidationErrorWrapper(TagValidationError.NAME_REQUIRED)
                "tag-width-invalid-error" -> CreateTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
                "tag-height-invalid-error" -> CreateTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
                "parents-not-found-error" ->
                    CreateTagResponse.createParentsNotFoundError(parentIds = result.relatedIds)
                else -> error("Unexpected tag creation domain error: ${result.slug}")
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
        request.parentIds?.let { ids ->
            ids.invalidRecordId("tag")?.let { return UpdateTagResponse.InvalidRecordIdErrorWrapper(it) }
        }
        val existing = childSpan("db.tag.get") { tags.getTag(request.tagId) }
            ?: return UpdateTagResponse.createTagNotFoundError(tagId = request.tagId)
        val placement = request.placement ?: existing.placement
        validate(request.name ?: existing.name, placement)?.let {
            return UpdateTagResponse.ValidationErrorWrapper(it)
        }
        val parentIds = request.parentIds ?: existing.parentIds
        val missing = missingParents(parentIds)
        if (missing.isNotEmpty()) return UpdateTagResponse.createParentsNotFoundError(parentIds = missing)
        val result = childSpan("db.tag.update") {
            tags.updateTag(
                Tag(
                    tagId = existing.tagId,
                    name = request.name ?: existing.name,
                    color = request.color ?: existing.color,
                    parentIds = parentIds,
                    placement = placement,
                ),
            )
        }
        val tag = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "tag-not-found-error" -> UpdateTagResponse.createTagNotFoundError(tagId = request.tagId)
                "tag-name-invalid-error" -> UpdateTagResponse.ValidationErrorWrapper(TagValidationError.NAME_REQUIRED)
                "tag-width-invalid-error" -> UpdateTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
                "tag-height-invalid-error" -> UpdateTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
                "parents-not-found-error" ->
                    UpdateTagResponse.createParentsNotFoundError(parentIds = result.relatedIds)
                else -> error("Unexpected tag update domain error: ${result.slug}")
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
        val deletion = when (val result = childSpan("db.tag.delete") { tags.deleteTag(id) }) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "tag-not-found-error" -> DeleteTagResponse.createTagNotFoundError(tagId = id)
                else -> error("Unexpected tag deletion domain error: ${result.slug}")
            }
        }
        publish(call.communicator, WatchTagsResponse.RemoveWrapper(id), WatchTagResponse.RemoveWrapper(id))
        for (childId in deletion.childTagIds) {
            val child = childSpan("db.tag.get") { tags.getTag(childId) } ?: continue
            publish(call.communicator, WatchTagsResponse.UpdateWrapper(child), WatchTagResponse.UpdateWrapper(child))
        }
        for (bookId in deletion.bookIds) {
            val book = childSpan("db.book.get") { books.getBook(bookId) } ?: continue
            call.communicator.publishUpdate(
                contracts.watchBooks,
                realmAddress,
                WatchBooksResponse.UpdateWrapper(book),
            ).requirePublished()
            call.communicator.publishUpdate(
                contracts.watchBook,
                realmAddress,
                skirout.library.v1.book.WatchBookResponse.UpdateWrapper(book),
            ).requirePublished()
        }
        return DeleteTagResponse.createSuccess()
    }

    context(main: MainSpanScope)
    private suspend fun move(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.tag.MoveTagRequest,
            MoveTagResponse,
            >,
    ): MoveTagResponse {
        val request = call.request
        request.tagId.invalidRecordId("tag")?.let {
            return MoveTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        if (request.x == null && request.y == null) {
            return MoveTagResponse.ValidationErrorWrapper(TagValidationError.POSITION_REQUIRED)
        }
        val tag = when (val result = childSpan("db.tag.move") {
            tags.moveTag(request.tagId, request.x, request.y)
        }) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "tag-not-found-error" -> MoveTagResponse.createTagNotFoundError(tagId = request.tagId)
                else -> error("Unexpected tag move domain error: ${result.slug}")
            }
        }
        publish(call.communicator, WatchTagsResponse.UpdateWrapper(tag), WatchTagResponse.UpdateWrapper(tag))
        return MoveTagResponse.SuccessWrapper(tag)
    }

    context(main: MainSpanScope)
    private suspend fun resize(
        call: com.typewritermc.services.libs.communicator.router.IncomingUnaryCall<
            RealmAddress,
            skirout.library.v1.tag.ResizeTagRequest,
            ResizeTagResponse,
            >,
    ): ResizeTagResponse {
        val request = call.request
        request.tagId.invalidRecordId("tag")?.let {
            return ResizeTagResponse.InvalidRecordIdErrorWrapper(it)
        }
        if (request.width == null && request.height == null) {
            return ResizeTagResponse.ValidationErrorWrapper(TagValidationError.SIZE_REQUIRED)
        }
        val width = request.width
        val height = request.height
        if (width != null && width <= 0) {
            return ResizeTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
        }
        if (height != null && height <= 0) {
            return ResizeTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
        }
        val result = childSpan("db.tag.resize") {
            tags.resizeTag(request.tagId, width, height)
        }
        val tag = when (result) {
            is RepositoryResult.Success -> result.value
            is RepositoryResult.DomainFailure -> return when (result.slug) {
                "tag-not-found-error" -> ResizeTagResponse.createTagNotFoundError(tagId = request.tagId)
                "tag-width-invalid-error" -> ResizeTagResponse.ValidationErrorWrapper(TagValidationError.WIDTH_INVALID)
                "tag-height-invalid-error" -> ResizeTagResponse.ValidationErrorWrapper(TagValidationError.HEIGHT_INVALID)
                else -> error("Unexpected tag resize domain error: ${result.slug}")
            }
        }
        publish(call.communicator, WatchTagsResponse.UpdateWrapper(tag), WatchTagResponse.UpdateWrapper(tag))
        return ResizeTagResponse.SuccessWrapper(tag)
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

    private fun validate(name: String, placement: Placement): TagValidationError? = when {
        name.isBlank() -> TagValidationError.NAME_REQUIRED
        placement.width <= 0 -> TagValidationError.WIDTH_INVALID
        placement.height <= 0 -> TagValidationError.HEIGHT_INVALID
        else -> null
    }
}
