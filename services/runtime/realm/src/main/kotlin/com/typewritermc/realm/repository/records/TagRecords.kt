package com.typewritermc.realm.repository.records

import com.surrealdb.RecordId
import com.surrealdb.Value
import com.typewritermc.library.GridPlacement
import com.typewritermc.library.LibraryName
import com.typewritermc.library.Tag
import com.typewritermc.library.ref
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
    val name: String = "",
    val color: Long = 0L,
    val placement: PlacementRecord = PlacementRecord(),
    val parent_tags: List<RecordId> = emptyList(),
) {
    fun toTag(): Tag =
        Tag(
            id = id.toTagId(),
            name = LibraryName(name),
            color = Color(argb = color.toUInt()),
            parents = parent_tags.mapTo(linkedSetOf()) { it.toTagId().ref() },
            placement = placement.toPlacement(),
        )

    companion object {
        fun parseList(result: Value): List<TagRecord> = result.parseRecords(TagRecord::class.java)
    }
}
