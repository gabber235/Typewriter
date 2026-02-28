package com.typewritermc.realm.repository.utils

import com.surrealdb.RecordId
import com.surrealdb.Value
import protokt.v1.typewriter.models.v1.*

fun requireValidId(name: String, id: String) {
    require(id.isNotBlank()) { "$name id cannot be blank" }
    require(!id.contains(':')) { "$name should only be the id, not the record." }
}

data class PlacementRecord(
    val x: Int = 0,
    val y: Int = 0,
    val width: Int = 0,
    val height: Int = 0
) {
    fun toPlacement(): Placement = Placement {
        x = this@PlacementRecord.x
        y = this@PlacementRecord.y
        width = this@PlacementRecord.width
        height = this@PlacementRecord.height
    }
}

data class TagRecord(
    val id: RecordId = RecordId("tag", ""),
    val name: String = "",
    val color: Long = 0L,
    val placement: PlacementRecord = PlacementRecord(),
    val parentIds: List<RecordId> = emptyList()
) {
    companion object {
        fun parse(value: Value): TagRecord = value.get(TagRecord::class.java)

        fun parseList(result: Value): List<TagRecord> {
            return result.array.map { parse(it) }
        }
    }

    fun toTag(): Tag {
        return Tag {
            tagId = this@TagRecord.id.id.string
            name = this@TagRecord.name
            color = Color { value = this@TagRecord.color.toUInt() }
            placement = this@TagRecord.placement.toPlacement()
            parentIds = this@TagRecord.parentIds.map { it.id.string }
        }
    }
}

data class BookRecord(
    val id: RecordId = RecordId("book", ""),
    val title: String = "",
    val icon: String = "",
    val color: Long = 0L,
    val tagIds: List<RecordId> = emptyList()
) {
    companion object {
        fun parse(value: Value): BookRecord = value.get(BookRecord::class.java)

        fun parseList(result: Value): List<BookRecord> {
            return result.array.map { parse(it) }
        }
    }

    fun toBook(): Book {
        return Book {
            bookId = this@BookRecord.id.id.string
            title = this@BookRecord.title
            icon = this@BookRecord.icon
            color = Color { value = this@BookRecord.color.toUInt() }
            tagIds = this@BookRecord.tagIds.map { it.id.string }
        }
    }
}

data class PageRecord(
    val id: RecordId = RecordId("page", ""),
    val book_id: RecordId = RecordId("book", ""),
    val name: String = "",
    val type: String = "sequence",
    val chapter: String = "",
    val priority: Int = 0
) {
    companion object {
        fun parse(value: Value): PageRecord = value.get(PageRecord::class.java)

        fun parseList(result: Value): List<PageRecord> {
            return result.array.map { parse(it) }
        }
    }

    fun toPage(): Page {
        return Page {
            pageId = this@PageRecord.id.id.string
            bookId = this@PageRecord.book_id.id.string
            name = this@PageRecord.name
            type = this@PageRecord.type.asPageType()
            chapter = this@PageRecord.chapter
            priority = this@PageRecord.priority
        }
    }
}

fun PageType.name(): String {
    return when (this) {
        PageType.SEQUENCE -> "sequence"
        PageType.STATIC -> "static"
        PageType.SCENE -> "scene"
        PageType.MANIFEST -> "manifest"
        else -> throw IllegalArgumentException("Unknown page type: $this")
    }
}

fun String.asPageType(): PageType {
    return when (this) {
        "sequence" -> PageType.SEQUENCE
        "static" -> PageType.STATIC
        "scene" -> PageType.SCENE
        "manifest" -> PageType.MANIFEST
        else -> throw IllegalArgumentException("Unknown page type: $this")
    }
}
