package com.typewritermc.realm.routes

import com.typewritermc.library.LibraryName
import com.typewritermc.library.ResourceRevision
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.realm.repository.TagCreateResult
import com.typewritermc.realm.repository.TagDeleteResult
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.TagUpdateResult
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpan
import com.typewritermc.types.Color
import skirout.library.v1.book.WatchBooksResponse
import skirout.library.v1.tag.CreateTagResponse
import skirout.library.v1.tag.DeleteTagResponse
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.TagValidationError
import skirout.library.v1.tag.UpdateTagResponse
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsResponse

internal class TagRoutes(
    private val tags: TagRepository,
    private val contracts: LibraryContracts,
    private val realmAddress: RealmAddress,
) {
    fun register(builder: CommunicatorRoutesBuilder) =
        with(builder) {
            watch(contracts.watchTags) {
                WatchTagsResponse.ListWrapper(childSpan("db.tag.list") { tags.listTags() }.map(Tag::toSkir))
            }
            watch(contracts.watchTag) { call ->
                call.request.tagId.invalidRecordId("tag")?.let {
                    return@watch WatchTagResponse.InvalidRecordIdErrorWrapper(it)
                }
                val tag =
                    childSpan("db.tag.get") { tags.getTag(call.request.tagId.toTagId()) }
                        ?: return@watch WatchTagResponse.createTagNotFoundError(tagId = call.request.tagId)
                WatchTagResponse.InitialWrapper(tag.toSkir())
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
        val parentIds = request.parentIds.mapTo(linkedSetOf()) { it.toTagId() }
        val missing = missingParents(parentIds)
        if (missing.isNotEmpty()) {
            return CreateTagResponse.createParentsNotFoundError(parentIds = missing.map { it.toSkirRecordId() })
        }
        val result =
            childSpan("db.tag.create") {
                tags.createTag(
                    LibraryName(request.name),
                    request.color?.toLibrary() ?: Color(argb = 0u),
                    parentIds,
                    placement.toLibrary(),
                    encodeEvents = { tag ->
                        tagEvents(
                            WatchTagsResponse.AddWrapper(tag.toSkir()),
                            WatchTagResponse.UpdateWrapper(tag.toSkir()),
                        )
                    },
                )
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
                    return CreateTagResponse.createParentsNotFoundError(
                        parentIds = result.parentIds.map { it.toSkirRecordId() },
                    )
                }
            }
        return CreateTagResponse.SuccessWrapper(tag.toSkir())
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
        validate(request.name, request.placement)?.let {
            return UpdateTagResponse.ValidationErrorWrapper(it)
        }
        val result =
            childSpan("db.tag.update") {
                tags.updateTag(
                    expectedRevision = request.expectedRevision,
                    Tag(
                        id = request.tagId.toTagId(),
                        revision = ResourceRevision(request.expectedRevision),
                        name = LibraryName(request.name),
                        color = request.color.toLibrary(),
                        parents = request.parentIds.mapTo(linkedSetOf()) { it.toTagId() },
                        placement = request.placement.toLibrary(),
                    ),
                    encodeEvents = { updated ->
                        tagEvents(
                            WatchTagsResponse.UpdateWrapper(updated.toSkir()),
                            WatchTagResponse.UpdateWrapper(updated.toSkir()),
                        )
                    },
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
                        actual = result.actual.toSkir(),
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
                    return UpdateTagResponse.createParentsNotFoundError(
                        parentIds = result.parentIds.map { it.toSkirRecordId() },
                    )
                }

                TagUpdateResult.InheritanceCycle -> {
                    return UpdateTagResponse.ValidationErrorWrapper(TagValidationError.INHERITANCE_CYCLE)
                }
            }
        return UpdateTagResponse.SuccessWrapper(tag.toSkir())
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
        when (
            val result =
                childSpan("db.tag.delete") {
                    tags.deleteTag(id.toTagId()) { deletion -> deletionEvents(id, deletion) }
                }
        ) {
            is TagDeleteResult.Success -> Unit
            TagDeleteResult.NotFound -> return DeleteTagResponse.createTagNotFoundError(tagId = id)
        }
        return DeleteTagResponse.createSuccess()
    }

    context(main: MainSpanScope)
    private suspend fun missingParents(parentIds: Set<TagId>) = childSpan("db.tag.validate") { tags.findMissing(parentIds) }

    private fun tagEvents(
        collection: WatchTagsResponse,
        resource: WatchTagResponse,
    ) = listOf(
        contracts.watchTags.encodeUpdate(realmAddress, collection),
        contracts.watchTag.encodeUpdate(realmAddress, resource),
    )

    private fun deletionEvents(
        id: skirout.kernel.v1.record_id.RecordId,
        deletion: com.typewritermc.realm.repository.TagDeletion,
    ) = buildList {
        addAll(tagEvents(WatchTagsResponse.RemoveWrapper(id), WatchTagResponse.RemoveWrapper(id)))
        deletion.childTags.forEach { child ->
            addAll(
                tagEvents(
                    WatchTagsResponse.UpdateWrapper(child.toSkir()),
                    WatchTagResponse.UpdateWrapper(child.toSkir()),
                ),
            )
        }
        deletion.books.forEach { book ->
            add(contracts.watchBooks.encodeUpdate(realmAddress, WatchBooksResponse.UpdateWrapper(book.toSkir())))
            add(
                contracts.watchBook.encodeUpdate(
                    realmAddress,
                    skirout.library.v1.book.WatchBookResponse
                        .UpdateWrapper(book.toSkir()),
                ),
            )
        }
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
