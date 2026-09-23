package com.typewritermc.library

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Element
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.Ref
import com.typewritermc.types.Referenceable
import com.typewritermc.types.OwnsResource
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.ToMany
import com.typewritermc.types.ToOne
import com.typewritermc.types.TypewriterRelation
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypeId

/**
 * Groups authored pages under a stable identity and library name.
 *
 * Tags are references to separate records; constructing a book does not resolve them or enforce database
 * uniqueness.
 */
@TypewriterType(id = "bbb646b300cf4dd2b7aab051854e4dd1")
data class Book(
    val title: String = "",
    val icon: Icon = Icon.Iconify("material-symbols:book"),
    val color: Color = Color(0xff3f51b5u),
    val tags: Set<Ref<Tag>> = emptySet(),
    val pages: ToMany<BookPages, Page> = ToMany.empty(),
) : Referenceable

/** Owns the synchronized Book to Page containment relationship. */
@TypewriterRelation(
    id = BOOK_PAGES_RELATION_ID,
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface BookPages : OwnsResource<Book, Page>

/**
 * Represents a library tag with potentially multiple parents and editor placement.
 *
 * Hierarchy validation belongs to [TagHierarchy] and the repository. The record itself permits unresolved parent
 * references.
 */
@TypewriterType(id = "ce1ae253a42d4509935c48b8ecba664a")
data class Tag(
    val name: String = "",
    val color: Color = Color(0xff9e9e9eu),
    val parents: Set<Ref<Tag>> = emptySet(),
    val placement: GraphPlacement,
) : Referenceable

/** Shared authored fields for concrete Page resource types. */
interface Page : Referenceable {
    val book: ToOne<BookPages, Book>
    val name: String
    val chapter: ChapterPath
    val priority: Int
    val elements: ToMany<PageElements, Element>
}

val PAGE_CONTRACT_TYPE = ResolvedTypeRef(TypeId.Qualified("com.typewritermc.library", "Page"), 1)

/** Owns Page containment of authored element resources. */
@TypewriterRelation(
    id = PAGE_ELEMENTS_RELATION_ID,
    onSourceDelete = RelationDeletePolicy.CASCADE,
    onTargetDelete = RelationDeletePolicy.CLEAR,
)
sealed interface PageElements : OwnsResource<Page, Element>

const val BOOK_PAGES_RELATION_ID = "4fbbe0dcedd84ccb8b7ce8c6a6105551"
const val PAGE_ELEMENTS_RELATION_ID = "349b4d11c4464d13ad4ca063ead60c62"
