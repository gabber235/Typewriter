package com.typewritermc.library

import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class BookId(
    val value: ResourceId,
)

fun BookId(value: String): BookId = BookId(ResourceId(value))

@JvmInline
@Serializable
value class TagId(
    val value: ResourceId,
)

fun TagId(value: String): TagId = TagId(ResourceId(value))

fun BookId.pageOwnerRef(): Ref<BookPages.Page, Book> = Ref(value)

fun TagId.parentRef(): Ref<TagParents.Child, Tag> = Ref(value)

fun PageId.bookPageRef(): Ref<BookPages.Book, Page> = Ref(value)

fun Ref<*, Book>.bookId(): BookId = BookId(target)

fun Ref<*, Tag>.tagId(): TagId = TagId(target)

fun Ref<*, Page>.pageId(): PageId = PageId(target)
