package com.typewritermc.library

import com.typewritermc.authoring.CompilationUnit
import com.typewritermc.authoring.GraphLayout
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.HierarchyPath
import com.typewritermc.authoring.RealmSection
import com.typewritermc.elements.Element
import com.typewritermc.types.Acyclic
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
import com.typewritermc.types.TypewriterRecordContract
import com.typewritermc.types.TypewriterType

/** The library section of the realm: it owns every [Book]. The realm creates its single instance. */
@TypewriterType(id = "c52850c175584f289e0b708b90a96ea3")
@com.typewritermc.types.TypewriterDisplay(
    name = "Library",
    description = "Every book of the realm",
    icon = "material-symbols:local-library",
    color = "#3F51B5",
)
data class Library(
    val books: List<Ref<LibraryBooks.Library, Book>> = emptyList(),
) : RealmSection

@ReferenceContract(LIBRARY_BOOKS_RELATION_ID)
interface LibraryBooksContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Library : One<com.typewritermc.library.Library>

    interface Book : Many<com.typewritermc.library.Book>
}

/**
 * The tags section of the realm: it owns every [Tag] and lays them out as a graph, so moved and created tags get a
 * placement. The realm creates its single instance.
 */
@TypewriterType(id = "4d46660b0c0b4e009628ff28953a086e")
@com.typewritermc.types.TypewriterDisplay(
    name = "Tags",
    description = "Every tag of the realm",
    icon = "material-symbols:label",
    color = "#795548",
)
data class Taxonomy(
    val tags: List<Ref<TaxonomyTags.Taxonomy, Tag>> = emptyList(),
) : RealmSection,
    GraphLayout

@ReferenceContract(TAXONOMY_TAGS_RELATION_ID)
interface TaxonomyTagsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Taxonomy : One<com.typewritermc.library.Taxonomy>

    interface Tag : Many<com.typewritermc.library.Tag>
}

/**
 * Groups authored pages through the core resource ownership relation and classifies them with independent tags.
 * Pages and their elements remain separate resources connected by generated endpoint references, so library
 * operations and graph reads can reason about ownership without decoding every concrete page or element type.
 */
@TypewriterType(id = "bbb646b300cf4dd2b7aab051854e4dd1")
@com.typewritermc.types.TypewriterDisplay(
    name = "Book",
    description = "Authored page collection",
    icon = "material-symbols:book",
    color = "#3F51B5",
)
data class Book(
    val library: Ref<LibraryBooks.Book, Library>,
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
    val taxonomy: Ref<TaxonomyTags.Tag, Taxonomy>,
    val name: String = "",
    val color: Color = Color(0xff9e9e9eu),
    val parents: Set<Ref<TagParents.Child, Tag>> = emptySet(),
    val placement: GraphPlacement,
) : Resource

@ReferenceContract(TAG_PARENTS_RELATION_ID)
interface TagParentsContract : Acyclic {
    interface Child : Many<Tag>

    interface Parent : Many<Tag>
}

@TypewriterRecordContract
interface Page : CompilationUnit {
    val book: Ref<BookPages.Page, Book>
    val name: String
    val chapter: HierarchyPath
    val priority: Int
    val elements: List<Ref<PageElements.Page, Element>>
}

@ReferenceContract(PAGE_ELEMENTS_RELATION_ID)
interface PageElementsContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Page : One<com.typewritermc.library.Page>

    @DeletionPolicy(RelationDeletePolicy.CLEAR)
    interface Element : Many<com.typewritermc.elements.Element>
}

const val LIBRARY_BOOKS_RELATION_ID = "ee2a486d09504adda0b2ad9848a031a5"
const val TAXONOMY_TAGS_RELATION_ID = "98c5a9a284f7446bb3ca009ab8dc8713"
const val BOOK_TAGS_RELATION_ID = "6376a137c1cf4765ab09f816d40c4ee4"
const val BOOK_PAGES_RELATION_ID = "4fbbe0dcedd84ccb8b7ce8c6a6105551"
const val TAG_PARENTS_RELATION_ID = "d894f2ab4dd6480791c45f779c9392e8"
const val PAGE_ELEMENTS_RELATION_ID = "349b4d11c4464d13ad4ca063ead60c62"
