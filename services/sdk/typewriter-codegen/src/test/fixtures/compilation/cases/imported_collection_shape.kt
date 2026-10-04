package fixture

import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.elements.Element
import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.ChapterPath
import com.typewritermc.library.Page
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterType

@TypewriterType(id = "a0000000000000000000000000000070")
data class ImportedCollectionPage(
    override val book: Ref<BookPages.Page, Book>,
    override val name: String,
    override val chapter: ChapterPath,
    override val priority: Int,
    override val elements: List<Ref<PageElements.Page, Element>>,
    val invalidElement: Ref<PageElements.Page, Element>,
) : Page

object FixtureResources {
    @TypewriterResourceDefinition("fixture.imported_collection_page", ImportedCollectionPage::class)
    val PAGE = ResourceDefinitionId("fixture.imported_collection_page")
}
