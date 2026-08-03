package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.realm.repository.TagDeletion
import com.typewritermc.realm.repository.utils.toSkirRecordId
import skirout.kernel.v1.color.Color
import skirout.library.v1.tag.Placement
import skirout.library.v1.tag.Tag

internal data class PlacementRecord(
    val x: Int = 0,
    val y: Int = 0,
    val width: Int = 3,
    val height: Int = 1,
) {
    fun toPlacement(): Placement = Placement(x = x, y = y, width = width, height = height)
}

@Suppress("PropertyName")
internal data class TagRecord(
    val id: RecordId = RecordId("tag", ""),
    val name: String = "",
    val color: Long = 0L,
    val placement: PlacementRecord = PlacementRecord(),
    val parent_tags: List<RecordId> = emptyList(),
) {
    fun toTag(): Tag = Tag(
        tagId = id.toSkirRecordId(),
        name = name,
        color = Color(argb = color.toInt()),
        parentIds = parent_tags.map(RecordId::toSkirRecordId),
        placement = placement.toPlacement(),
    )

    companion object {
        fun parseList(result: Value): List<TagRecord> = result.parseRecords(TagRecord::class.java)
    }
}

internal data class TagDeletionRecord(
    val childTagIds: List<RecordId> = emptyList(),
    val bookIds: List<RecordId> = emptyList(),
) {
    fun toTagDeletion(): TagDeletion = TagDeletion(
        childTagIds = childTagIds.map(RecordId::toSkirRecordId),
        bookIds = bookIds.map(RecordId::toSkirRecordId),
    )

    companion object {
        fun parse(result: Value): TagDeletionRecord = result.get(TagDeletionRecord::class.java)
    }
}
