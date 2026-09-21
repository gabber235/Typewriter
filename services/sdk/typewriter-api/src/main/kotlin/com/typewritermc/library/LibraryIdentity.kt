package com.typewritermc.library

import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ref
import kotlinx.serialization.Serializable

/**
 * Gives Book APIs a compile time identity type while retaining one opaque resource id.
 */
@JvmInline
@Serializable
value class BookId(
    val value: ResourceId,
)

fun BookId(value: String): BookId = BookId(ResourceId(value))

/**
 * Gives Tag APIs a compile time identity type while retaining one opaque resource id.
 */
@JvmInline
@Serializable
value class TagId(
    val value: ResourceId,
)

fun TagId(value: String): TagId = TagId(ResourceId(value))

fun BookId.ref(): Ref<Book> = value.ref()

fun TagId.ref(): Ref<Tag> = value.ref()

fun PageId.ref(): Ref<Page> = value.ref()

fun Ref<Book>.bookId(): BookId = BookId(id)

fun Ref<Tag>.tagId(): TagId = TagId(id)

fun Ref<Page>.pageId(): PageId = PageId(id)
