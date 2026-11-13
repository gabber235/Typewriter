package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DisplayFormulas
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.of
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.elements.CueDefinition
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.library.Book
import com.typewritermc.library.BookDefinition
import com.typewritermc.library.LibraryDefinition
import com.typewritermc.library.PageDefinition
import com.typewritermc.library.TaxonomyDefinition
import com.typewritermc.library.fields
import com.typewritermc.presentation.RuntimePresentationQueries
import com.typewritermc.testkit.origin
import com.typewritermc.types.Color
import com.typewritermc.types.Icon
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.fields
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.toWire
import com.typewritermc.types.type
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.diagnostic.DeclarationOrigin
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ResourceTarget
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

val ResourceDisplayAssemblyTest by testSuite {
    val fixtureResource = TypeDefinitionId.qualified("fixture", "DisplayResource")

    val fixturePage = TypeDefinitionId.qualified("fixture", "DisplayPage")

    val fixtureBox = TypeDefinitionId.qualified("fixture", "DisplayBox")

    test("Realm labels a titled book with its title and leaves the type name fallback to editors") {
        val assembly = assemble()

        assembly.label(book(title = "Main story")) shouldBe "Main story"
        // The type name comes from the published catalog, a panel profile read Realm does not evaluate.
        assembly.label(book(title = "")) shouldBe null
        assembly.label(book(title = "   ")) shouldBe null
    }

    test("the most specific declared display wins and every other resource uses the default display") {
        val assembly = assemble(declarations = listOf(fixtureType(fixturePage, parent = PageDefinition.id)))
        val displays = assembly.displays

        displays.displayFor(BookDefinition.id, assembly.checked)?.target shouldBe
            ResourceTarget.type(BookDefinition.id.namedTemplate())
        displays.displayFor(fixturePage, assembly.checked)?.target shouldBe
            ResourceTarget.type(PageDefinition.id.namedTemplate())
        displays.displayFor(CueDefinition.id, assembly.checked)?.target shouldBe ResourceTarget.ANY_RESOURCE
        assembly.label(
            AuthoringRecord.of(
                TypeSelection.of(fixturePage.namedUse()),
                mapOf("name" to DataValue.StringValueWrapper("Intro")),
            ),
        ) shouldBe
            "Intro"
    }

    test("a resource type without its own display uses the default display over the type display the catalog publishes") {
        val display = TypeDisplay("Fixture resource", "", Icon.Iconify("mdi:cube"), Color(0xFF123456u))
        val assembly =
            assemble(
                declarations = listOf(fixtureType(fixtureResource, display = display)),
                searchKeys =
                    mapOf(fixtureResource to "fixture"),
            )

        // The default formulas read the published declaration, a panel profile read: the panel evaluates them to these values.
        assembly.displays.displayFor(fixtureResource, assembly.checked)?.target shouldBe ResourceTarget.ANY_RESOURCE
        assembly.editorCatalog.types
            .single { it.definition.id == fixtureResource }
            .display shouldBe display.toWire()
    }

    test("a display formula that reads a host context input is rejected") {
        val contextual =
            displayProvider(ResourceTarget.type(BookDefinition.id.namedTemplate())) {
                DisplayFormulas(
                    label = input<String>(ExpressionBindingId(value = "context:active")).orElse(literal("Book")),
                    accent = literal(Color(0xFF000000u)),
                    icon = literal(Icon.Iconify("mdi:book")),
                )
            }
        val assembly = assemble(displays = listOf(contextual))

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("display_reads_context")
        val otherResource =
            displayProvider(ResourceTarget.type(BookDefinition.id.namedTemplate())) {
                val other =
                    RuntimePresentationQueries(mapOf(Book::class to BookDefinition.id.namedTemplate()))
                        .resource(literal(ResourceId("other")), Book::class)
                DisplayFormulas(
                    label = other.fields.title.orElse(literal("Book")),
                    accent = literal(Color(0xFF000000u)),
                    icon = literal(Icon.Iconify("mdi:book")),
                )
            }
        assemble(displays = listOf(otherResource)).diagnosticCodes(BookDefinition.id) shouldBe listOf("display_reads_context")
        assembly.editorCatalog.resourceDisplays.none {
            it.label ==
                contextual.provider
                    .formulas()
                    .label
                    .toNode()
        } shouldBe true
        assembly.label(book(title = "Kept")) shouldBe "Kept"
    }

    test("a display of a generic resource type checks against every application of its parameters") {
        val generic = genericType(fixtureBox)
        val target = ResourceTarget.type(fixtureBox.namedTemplate())
        val reading = { field: String ->
            displayProvider(target) {
                DisplayFormulas(
                    label = input<Any>(ExpressionBindingId(value = "configured_value")).field<String>(field).orElse(literal("Box")),
                    accent = literal(Color(0xFF000000u)),
                    icon = literal(Icon.Iconify("mdi:package")),
                )
            }
        }

        assemble(declarations = listOf(generic), displays = listOf(reading("title")))
            .diagnosticCodes(fixtureBox) shouldNotContain "invalid_resource_display"
        assemble(declarations = listOf(generic), displays = listOf(reading("contents")))
            .diagnosticCodes(fixtureBox) shouldContain "invalid_resource_display"
        assemble(declarations = listOf(generic), displays = listOf(reading("missing")))
            .diagnosticCodes(fixtureBox) shouldContain "invalid_resource_display"
    }

    test("two displays for one target are rejected and the resource falls back to a less specific display") {
        val target = ResourceTarget.type(BookDefinition.id.namedTemplate())
        val constant = { label: String ->
            displayProvider(target) {
                DisplayFormulas(literal(label), literal(Color(0xFF000000u)), literal(Icon.Iconify("mdi:book")))
            }
        }
        val assembly = assemble(displays = listOf(constant("First"), constant("Second")), includeGenerated = false)

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("duplicate_resource_display")
        assembly.editorCatalog.resourceDisplays
            .map { it.target } shouldBe listOf(skirout.editor.v1.type_catalog.ResourceTarget.ANY_RESOURCE)
        assembly.displays.displayFor(BookDefinition.id, assembly.checked)?.target shouldBe ResourceTarget.ANY_RESOURCE
    }

    test("an extension's any resource display is rejected while the framework default keeps naming every resource") {
        val extension =
            displayProvider(ResourceTarget.ANY_RESOURCE) {
                DisplayFormulas(literal("Extension"), literal(Color(0xFF000000u)), literal(Icon.Iconify("mdi:book")))
            }
        val assembly = assemble(displays = listOf(extension), includeGenerated = false)

        val duplicate = assembly.editorCatalog.diagnostics.single { it.code == "duplicate_resource_display" }
        duplicate.origins shouldBe
            listOf(
                skirout.editor.v1.diagnostic
                    .DeclarationOrigin(owner = extension.origin.owner),
            )
        assembly.editorCatalog.resourceDisplays
            .map { it.target } shouldBe listOf(skirout.editor.v1.type_catalog.ResourceTarget.ANY_RESOURCE)
        assembly.displays.displayFor(BookDefinition.id, assembly.checked)!!.label shouldNotBe
            ExpressionNode.LiteralWrapper(DataValue.StringValueWrapper("Extension"))
    }

    test("the realm root and its sections publish no search key and never conflict with a resource's") {
        val owner = fixtureType(fixtureResource)
        val ownership =
            RelationContract.of(
                id = RelationId(value = "fixture.ownership"),
                first = endpoint("fixture.owner", EndpointSlot.FIRST, fixtureResource),
                second = endpoint("fixture.owned", EndpointSlot.SECOND, BookDefinition.id),
                families = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val assembly =
            assemble(
                declarations = listOf(owner),
                searchKeys = mapOf(fixtureResource to "library"),
                relations = listOf(ownership),
            )
        val keys = assembly.editorCatalog.types.associate { it.definition.id to it.searchKey }

        listOf(RealmRootDefinition.id, LibraryDefinition.id, TaxonomyDefinition.id).map(keys::getValue) shouldBe
            listOf(null, null, null)
        keys.getValue(fixtureResource) shouldBe "library"
        keys.getValue(BookDefinition.id) shouldBe "book"
        assembly.diagnosticCodes(fixtureResource) shouldNotContain "duplicate_search_key"
    }

    test("two owner types with one search key are rejected and publish no search key") {
        val owner = fixtureType(fixtureResource)
        val ownership =
            RelationContract.of(
                id = RelationId(value = "fixture.ownership"),
                first = endpoint("fixture.owner", EndpointSlot.FIRST, fixtureResource),
                second = endpoint("fixture.owned", EndpointSlot.SECOND, BookDefinition.id),
                families = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val bookOwnership =
            RelationContract.of(
                id = RelationId(value = "fixture.book_ownership"),
                first = endpoint("fixture.book", EndpointSlot.FIRST, BookDefinition.id),
                second = endpoint("fixture.book_owned", EndpointSlot.SECOND, fixtureResource),
                families = setOf(RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val assembly =
            assemble(
                declarations = listOf(owner),
                searchKeys = mapOf(fixtureResource to "book"),
                relations = listOf(ownership, bookOwnership),
            )

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("duplicate_search_key")
        assembly.diagnosticCodes(fixtureResource) shouldBe listOf("duplicate_search_key")
        assembly.editorCatalog.types
            .filter { it.definition.id == BookDefinition.id || it.definition.id == fixtureResource }
            .map { it.searchKey } shouldBe listOf(null, null)
    }
}
