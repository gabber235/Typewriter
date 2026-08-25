package com.typewritermc.realm.routes

import com.typewritermc.library.Tag
import com.typewritermc.realm.repository.TagRepository
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.telemetry.childSpan
import skirout.library.v1.tag.WatchTagResponse
import skirout.library.v1.tag.WatchTagsResponse

internal class TagRoutes(
    private val tags: TagRepository,
    private val contracts: LibraryContracts,
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
        }
}
