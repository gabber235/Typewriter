package com.typewritermc.library

import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class BookId(
    val key: RecordIdKey,
) {
    constructor(value: String) : this(
        com.typewritermc.types.RecordIdKey
            .String(value),
    )
}

@JvmInline
@Serializable
value class TagId(
    val key: RecordIdKey,
) {
    constructor(value: String) : this(
        com.typewritermc.types.RecordIdKey
            .String(value),
    )
}

@JvmInline
@Serializable
value class LibraryName(
    val value: String,
) {
    init {
        require(value.length >= 3 && value.matches(PATTERN)) {
            "Library names must contain lowercase alphanumeric segments separated by single underscores."
        }
    }

    private companion object {
        val PATTERN = Regex("^[a-z0-9]+(_[a-z0-9]+)*$")
    }
}

fun BookId.ref(): Ref<Book> = Ref(ResourceId("book", key))

fun TagId.ref(): Ref<Tag> = Ref(ResourceId("tag", key))

fun PageId.ref(): Ref<Page> = Ref(ResourceId("page", key))

fun Ref<Book>.bookId(): BookId {
    require(id.table == "book") { "Book references must target the book table." }
    return BookId(id.key)
}

fun Ref<Tag>.tagId(): TagId {
    require(id.table == "tag") { "Tag references must target the tag table." }
    return TagId(id.key)
}

fun Ref<Page>.pageId(): PageId {
    require(id.table == "page") { "Page references must target the page table." }
    return PageId(id.key)
}
