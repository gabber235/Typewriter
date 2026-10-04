package com.typewritermc.library

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.elements.Element
import com.typewritermc.types.Color
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Icon
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "bbb646b300cf4dd2b7aab051854e4dd1")
@com.typewritermc.types.TypewriterDisplay(
    name = "Book",
    description = "Authored page collection",
    icon = "material-symbols:book",
    color = "#3F51B5",
)
data class Book(
    val title: String = "",
    val icon: Icon = Icon.Iconify("material-symbols:book"),
    val color: Color = Color(0xff3f51b5u),
    val tags: Set<Ref<BookTags.Book, Tag>> = emptySet(),
    val pages: List<Ref<BookPages.Book, Page>> = emptyList(),
) : Resource

@ReferenceContract(BOOK_TAGS_RELATION_ID)
interface BookTagsContract {
    interface Book : Many<com.typewritermc.library.Book>

    interface Tag : Many<com.typewritermc.library.Tag>
}

@ReferenceContract(BOOK_PAGES_RELATION_ID)
interface BookPagesContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Book : One<com.typewritermc.library.Book>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Page : Many<com.typewritermc.library.Page>
}

@TypewriterType(id = "ce1ae253a42d4509935c48b8ecba664a")
@com.typewritermc.types.TypewriterDisplay(
    name = "Tag",
    description = "Library classification",
    icon = "material-symbols:label",
    color = "#795548",
)
data class Tag(
    val name: String = "",
    val color: Color = Color(0xff9e9e9eu),
    val parents: Set<Ref<TagParents.Child, Tag>> = emptySet(),
    val placement: GraphPlacement,
) : Resource

@ReferenceContract(TAG_PARENTS_RELATION_ID)
interface TagParentsContract {
    interface Child : Many<Tag>

    interface Parent : Many<Tag>
}

@TypewriterRecordContract
interface Page : Resource {
    val book: Ref<BookPages.Page, Book>
    val name: String
    val chapter: ChapterPath
    val priority: Int
    val elements: List<Ref<PageElements.Page, Element>>
}

val PAGE_CONTRACT_TYPE = TypeDefinitionId(TypeId.Qualified("kotlin", "com.typewritermc.library.Page"), 1)

@ReferenceContract(PAGE_ELEMENTS_RELATION_ID)
interface PageElementsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Page : One<com.typewritermc.library.Page>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Element : Many<com.typewritermc.elements.Element>
}

const val BOOK_TAGS_RELATION_ID = "6376a137c1cf4765ab09f816d40c4ee4"
const val BOOK_PAGES_RELATION_ID = "4fbbe0dcedd84ccb8b7ce8c6a6105551"
const val TAG_PARENTS_RELATION_ID = "d894f2ab4dd6480791c45f779c9392e8"
const val PAGE_ELEMENTS_RELATION_ID = "349b4d11c4464d13ad4ca063ead60c62"
