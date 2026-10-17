package fixture

import com.typewritermc.library.Book
import com.typewritermc.library.BookPages
import com.typewritermc.library.Page
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.types.Ref
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports

@TypewriterTypeImports(Book::class, Page::class)
@TypewriterType(id = "a0000000000000000000000000000001")
data class ImportedEndpointOnWrongResource(
    val page: Ref<BookPages.Book, Page>,
) : Resource

object FixtureResources {
    @TypewriterResourceDefinition("fixture.imported", ImportedEndpointOnWrongResource::class)
    val IMPORTED = ResourceDefinitionId("fixture.imported")
}
