package com.typewritermc.library

import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.elements.StoredElementEnvelope
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
data class Book(
    val id: BookId,
    val revision: ResourceRevision,
    val title: LibraryName,
    val icon: Icon,
    val color: Color,
    val tags: Set<TagId>,
)

@Serializable
data class Tag(
    val id: TagId,
    val revision: ResourceRevision,
    val name: LibraryName,
    val color: Color,
    val parents: Set<TagId>,
    val placement: GridPlacement,
)

@Serializable
data class Page(
    val id: PageId,
    val revision: ResourceRevision,
    val bookId: BookId,
    val name: LibraryName,
    val kind: PageKindRef,
    val chapter: ChapterPath,
    val priority: Int,
)

@Serializable
data class GridPlacement(
    val x: Int,
    val y: Int,
    val width: Int,
    val height: Int,
)

@Serializable
sealed interface PageLayout {
    @Serializable
    @SerialName("graph")
    data class Graph(
        val placements: Map<ElementInstanceId, GridPlacement>,
    ) : PageLayout

    @Serializable
    @SerialName("timeline")
    data class Timeline(
        val trackOrder: List<ElementInstanceId>,
    ) : PageLayout {
        init {
            require(trackOrder.distinct().size == trackOrder.size) { "Timeline tracks must be unique." }
        }
    }
}

@Serializable
data class PageContents(
    val pageId: PageId,
    val elements: List<StoredElementEnvelope>,
    val layout: PageLayout,
)

@Serializable
data class LibrarySnapshot(
    val revision: LibraryRevision,
    val books: List<Book>,
    val tags: List<Tag>,
    val pages: List<Page>,
    val contents: List<PageContents>,
) {
    init {
        require(books.map(Book::id).distinct().size == books.size) { "Book ids must be unique." }
        require(tags.map(Tag::id).distinct().size == tags.size) { "Tag ids must be unique." }
        require(pages.map(Page::id).distinct().size == pages.size) { "Page ids must be unique." }
        require(contents.map(PageContents::pageId).distinct().size == contents.size) {
            "Page contents must be unique per page."
        }
        require(contents.all { contents -> pages.any { it.id == contents.pageId } }) {
            "Page contents must reference a page in the snapshot."
        }
    }
}
