package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.ResourceRevision
import com.typewritermc.library.Tag
import com.typewritermc.realm.repository.TagCreateResult
import com.typewritermc.realm.repository.TagDeleteResult
import com.typewritermc.realm.repository.TagDeletion
import com.typewritermc.realm.repository.TagUpdateResult
import com.typewritermc.realm.repository.utils.toTagId
import com.typewritermc.types.Color

internal data class PlacementRecord(
    val x: Int = 0,
    val y: Int = 0,
    val width: Int = 3,
    val height: Int = 1,
) {
    fun toPlacement(): GridPlacement = GridPlacement(x = x, y = y, width = width, height = height)
}

@Suppress("PropertyName")
internal data class TagRecord(
    val id: RecordId = RecordId("tag", ""),
    val revision: Long = 1,
    val name: String = "",
    val color: Long = 0L,
    val placement: PlacementRecord = PlacementRecord(),
    val parent_tags: List<RecordId> = emptyList(),
) {
    fun toTag(): Tag =
        Tag(
            id = id.toTagId(),
            revision = ResourceRevision(revision),
            name = LibraryName(name),
            color = Color(argb = color.toUInt()),
            parents = parent_tags.mapTo(linkedSetOf(), RecordId::toTagId),
            placement = placement.toPlacement(),
        )

    companion object {
        fun parseList(result: Value): List<TagRecord> = result.parseRecords(TagRecord::class.java)
    }
}

internal data class TagDeletionRecord(
    val childTags: List<TagRecord> = emptyList(),
    val books: List<BookRecord> = emptyList(),
) {
    fun toTagDeletion(): TagDeletion =
        TagDeletion(
            childTags = childTags.map(TagRecord::toTag),
            books = books.map(BookRecord::toBook),
        )
}

internal data class TagCreateOutputRecord(
    val kind: String = "",
    val tag: TagRecord? = null,
    val parentIds: List<RecordId>? = null,
) {
    fun toResult(): TagCreateResult =
        when (kind) {
            "success" -> TagCreateResult.Success(requireTag().toTag())
            "name_invalid" -> TagCreateResult.NameInvalid
            "width_invalid" -> TagCreateResult.WidthInvalid
            "height_invalid" -> TagCreateResult.HeightInvalid
            "parents_not_found" -> TagCreateResult.ParentsNotFound(requireParentIds())
            else -> invalidTagOutput("unknown create outcome '$kind'")
        }

    companion object {
        fun parse(result: Value): TagCreateOutputRecord = result.get(TagCreateOutputRecord::class.java)
    }

    private fun requireTag(): TagRecord = tag ?: invalidTagOutput("create outcome '$kind' requires a tag")

    private fun requireParentIds() =
        parentIds
            ?.takeIf(List<*>::isNotEmpty)
            ?.mapTo(linkedSetOf(), RecordId::toTagId)
            ?: invalidTagOutput("create outcome '$kind' requires parent ids")
}

internal data class TagUpdateOutputRecord(
    val kind: String = "",
    val tag: TagRecord? = null,
    val parentIds: List<RecordId>? = null,
) {
    fun toResult(): TagUpdateResult =
        when (kind) {
            "success" -> TagUpdateResult.Success(requireTag().toTag())
            "conflict" -> TagUpdateResult.Conflict(requireTag().toTag())
            "not_found" -> TagUpdateResult.NotFound
            "name_invalid" -> TagUpdateResult.NameInvalid
            "width_invalid" -> TagUpdateResult.WidthInvalid
            "height_invalid" -> TagUpdateResult.HeightInvalid
            "parents_not_found" -> TagUpdateResult.ParentsNotFound(requireParentIds())
            "inheritance_cycle" -> TagUpdateResult.InheritanceCycle
            else -> invalidTagOutput("unknown update outcome '$kind'")
        }

    companion object {
        fun parse(result: Value): TagUpdateOutputRecord = result.get(TagUpdateOutputRecord::class.java)
    }

    private fun requireTag(): TagRecord = tag ?: invalidTagOutput("update outcome '$kind' requires a tag")

    private fun requireParentIds() =
        parentIds
            ?.takeIf(List<*>::isNotEmpty)
            ?.mapTo(linkedSetOf(), RecordId::toTagId)
            ?: invalidTagOutput("update outcome '$kind' requires parent ids")
}

internal data class TagDeleteOutputRecord(
    val kind: String = "",
    val deletion: TagDeletionRecord? = null,
) {
    fun toResult(): TagDeleteResult =
        when (kind) {
            "success" -> TagDeleteResult.Success(requireDeletion().toTagDeletion())
            "not_found" -> TagDeleteResult.NotFound
            else -> invalidTagOutput("unknown delete outcome '$kind'")
        }

    companion object {
        fun parse(result: Value): TagDeleteOutputRecord = result.get(TagDeleteOutputRecord::class.java)
    }

    private fun requireDeletion(): TagDeletionRecord = deletion ?: invalidTagOutput("delete outcome '$kind' requires deletion details")
}

private fun invalidTagOutput(reason: String): Nothing = error("Invalid tag mutation output: $reason")
