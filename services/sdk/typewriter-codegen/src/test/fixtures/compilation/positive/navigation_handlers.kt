package fixture

import com.typewritermc.authoring.AuthoringNavigationHandler
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.types.Resource
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.catalog.EditorCatalogSnapshot
import com.typewritermc.types.catalog.toWire
import skirout.editor.v1.catalog.EditorCatalogWireSnapshot
import skirout.editor.v1.catalog.AuthoringNavigationHandler as WireHandler

@TypewriterType(id = "a0000000000000000000000000000088")
data class NavigationResource(val title: String = "") : Resource

object NavigationResources {
    @TypewriterResourceDefinition("fixture.default", NavigationResource::class)
    val DEFAULT = ResourceDefinitionId("fixture.default")

    @TypewriterResourceDefinition("fixture.generic", NavigationResource::class, AuthoringNavigationHandler.GENERIC)
    val GENERIC = ResourceDefinitionId("fixture.generic")

    @TypewriterResourceDefinition("fixture.book", NavigationResource::class, AuthoringNavigationHandler.BOOK)
    val BOOK = ResourceDefinitionId("fixture.book")

    @TypewriterResourceDefinition("fixture.page", NavigationResource::class, AuthoringNavigationHandler.PAGE)
    val PAGE = ResourceDefinitionId("fixture.page")

    @TypewriterResourceDefinition("fixture.element", NavigationResource::class, AuthoringNavigationHandler.PAGE_ELEMENT)
    val ELEMENT = ResourceDefinitionId("fixture.element")

    @TypewriterResourceDefinition("fixture.tags", NavigationResource::class, AuthoringNavigationHandler.TAGS)
    val TAGS = ResourceDefinitionId("fixture.tags")
}

fun main() {
    val definitions =
        listOf(
            fixture_NavigationResources_DEFAULTResourceRegistration.definition,
            fixture_NavigationResources_GENERICResourceRegistration.definition,
            fixture_NavigationResources_BOOKResourceRegistration.definition,
            fixture_NavigationResources_PAGEResourceRegistration.definition,
            fixture_NavigationResources_ELEMENTResourceRegistration.definition,
            fixture_NavigationResources_TAGSResourceRegistration.definition,
        )
    val expected =
        listOf(
            AuthoringNavigationHandler.GENERIC,
            AuthoringNavigationHandler.GENERIC,
            AuthoringNavigationHandler.BOOK,
            AuthoringNavigationHandler.PAGE,
            AuthoringNavigationHandler.PAGE_ELEMENT,
            AuthoringNavigationHandler.TAGS,
        )
    check(definitions.map { it.navigationHandler } == expected)
    val wire =
        EditorCatalogSnapshot(
            generation = CatalogGeneration("navigation"),
            types = emptyList(),
            relations = emptyList(),
            resourceDefinitions = definitions,
            presentations = emptyList(),
            presentationMaterials = emptyList(),
            configuration = emptyList(),
            diagnostics = emptyList(),
        ).toWire()
    val decoded =
        EditorCatalogWireSnapshot.serializer.fromJsonCode(
            EditorCatalogWireSnapshot.serializer.toJsonCode(wire),
        )
    val expectedWire =
        listOf(
            WireHandler.GENERIC,
            WireHandler.GENERIC,
            WireHandler.BOOK,
            WireHandler.PAGE,
            WireHandler.PAGE_ELEMENT,
            WireHandler.TAGS,
        )
    check(decoded.resourceDefinitions.map { it.navigationHandler } == expectedWire)
}
