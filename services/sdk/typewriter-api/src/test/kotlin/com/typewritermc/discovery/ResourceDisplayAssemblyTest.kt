package com.typewritermc.discovery

import com.typewritermc.authoring.AuthoredReads
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.BoundCollectionPath
import com.typewritermc.authoring.BoundPath
import com.typewritermc.authoring.DisplayFormulas
import com.typewritermc.authoring.DraftBinding
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.ReadContext
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.PartialSelection
import com.typewritermc.checking.TypedSelection
import com.typewritermc.elements.CueDefinition
import com.typewritermc.expression.DefaultExpressionEvaluator
import com.typewritermc.expression.EvaluationBudget
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.expression.ExpressionBindings
import com.typewritermc.expression.ExpressionValueReader
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
import com.typewritermc.types.Color
import com.typewritermc.types.ColorDefinition
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointCardinality
import com.typewritermc.types.EndpointDefinition
import com.typewritermc.types.EndpointId
import com.typewritermc.types.EndpointSlot
import com.typewritermc.types.Icon
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
import com.typewritermc.types.RelationContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.RelationFamilyId
import com.typewritermc.types.RelationId
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.ResourceId
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import com.typewritermc.types.catalog.DeclarationOrigin
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldNotContain
import io.kotest.matchers.shouldBe

val ResourceDisplayAssemblyTest by testSuite {
    test("a book with a blank title is labelled with its type name, and a titled book with its title") {
        val assembly = assemble()

        assembly.label(book(title = "")) shouldBe "Book"
        assembly.label(book(title = "   ")) shouldBe "Book"
        assembly.label(book(title = "Main story")) shouldBe "Main story"
    }

    test("the most specific declared display wins and every other resource uses the default display") {
        val assembly = assemble(declarations = listOf(fixtureType(fixturePage, parent = PageDefinition.id)))
        val displays = assembly.displays

        displays.displayFor(BookDefinition.id, assembly.checked)?.target shouldBe
            ResourceTarget.Type(TypeTemplate.Named(BookDefinition.id))
        displays.displayFor(fixturePage, assembly.checked)?.target shouldBe
            ResourceTarget.Type(TypeTemplate.Named(PageDefinition.id))
        displays.displayFor(CueDefinition.id, assembly.checked)?.target shouldBe ResourceTarget.AnyResource
        assembly.label(
            AuthoringRecord(TypeSelection.Complete(TypeUse.Named(fixturePage)), mapOf("name" to DataValue.StringValue("Intro"))),
        ) shouldBe
            "Intro"
    }

    test("the default display reads the subject's type display") {
        val display = TypeDisplay("Fixture resource", "", Icon.Iconify("mdi:cube"), Color(0xFF123456u))
        val assembly =
            assemble(
                declarations = listOf(fixtureType(fixtureResource, display = display)),
                searchKeys =
                    mapOf(fixtureResource to "fixture"),
            )
        val record = AuthoringRecord(TypeSelection.Complete(TypeUse.Named(fixtureResource)), emptyMap())
        val formulas = assembly.displays.displayFor(fixtureResource, assembly.checked)!!

        formulas.target shouldBe ResourceTarget.AnyResource
        assembly.label(record) shouldBe "Fixture resource"
        assembly.evaluate(formulas.accent, record) shouldBe
            DataValue.Named(ColorDefinition.use, DataValue.Integer(0xFF123456u.toString().toBigInteger()))
    }

    test("a display formula that reads a host context input is rejected") {
        val contextual =
            displayProvider(ResourceTarget.Type(TypeTemplate.Named(BookDefinition.id))) {
                DisplayFormulas(
                    label = input<String>(ExpressionBindingId("context:active")).orElse(literal("Book")),
                    accent = literal(Color(0xFF000000u)),
                    icon = literal(Icon.Iconify("mdi:book")),
                )
            }
        val assembly = assemble(displays = listOf(contextual))

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("display_reads_context")
        val otherResource =
            displayProvider(ResourceTarget.Type(TypeTemplate.Named(BookDefinition.id))) {
                val other =
                    RuntimePresentationQueries(mapOf(Book::class to TypeTemplate.Named(BookDefinition.id)))
                        .resource(literal(ResourceId("other")), Book::class)
                DisplayFormulas(
                    label = other.fields.title.orElse(literal("Book")),
                    accent = literal(Color(0xFF000000u)),
                    icon = literal(Icon.Iconify("mdi:book")),
                )
            }
        assemble(displays = listOf(otherResource)).diagnosticCodes(BookDefinition.id) shouldBe listOf("display_reads_context")
        assembly.snapshot.resourceDisplays.none {
            it.label ==
                contextual.provider
                    .formulas()
                    .label
                    .toNode()
        } shouldBe true
        assembly.label(book(title = "Kept")) shouldBe "Kept"
    }

    test("two displays for one target are rejected and the resource falls back to a less specific display") {
        val target = ResourceTarget.Type(TypeTemplate.Named(BookDefinition.id))
        val constant = { label: String ->
            displayProvider(target) {
                DisplayFormulas(literal(label), literal(Color(0xFF000000u)), literal(Icon.Iconify("mdi:book")))
            }
        }
        val assembly = assemble(displays = listOf(constant("First"), constant("Second")), includeGenerated = false)

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("duplicate_resource_display")
        assembly.snapshot.resourceDisplays
            .map { it.target } shouldBe listOf(ResourceTarget.AnyResource)
        assembly.label(book(title = "")) shouldBe "Book"
    }

    test("an extension's any resource display is rejected while the framework default keeps naming every resource") {
        val extension =
            displayProvider(ResourceTarget.AnyResource) {
                DisplayFormulas(literal("Extension"), literal(Color(0xFF000000u)), literal(Icon.Iconify("mdi:book")))
            }
        val assembly = assemble(displays = listOf(extension), includeGenerated = false)

        val duplicate = assembly.snapshot.diagnostics.single { it.code == "duplicate_resource_display" }
        duplicate.origins shouldBe listOf(DeclarationOrigin(extension.origin.owner))
        assembly.snapshot.resourceDisplays
            .map { it.target } shouldBe listOf(ResourceTarget.AnyResource)
        assembly.label(book(title = "")) shouldBe "Book"
    }

    test("the realm root and its sections publish no search key and never conflict with a resource's") {
        val owner = fixtureType(fixtureResource)
        val ownership =
            RelationContract(
                id = RelationId("fixture.ownership"),
                first = endpoint("fixture.owner", EndpointSlot.First, fixtureResource),
                second = endpoint("fixture.owned", EndpointSlot.Second, BookDefinition.id),
                families = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val assembly =
            assemble(
                declarations = listOf(owner),
                searchKeys = mapOf(fixtureResource to "library"),
                relations = listOf(ownership),
            )
        val keys = assembly.snapshot.types.associate { it.definition.id to it.searchKey }

        listOf(RealmRootDefinition.id, LibraryDefinition.id, TaxonomyDefinition.id).map(keys::getValue) shouldBe
            listOf(null, null, null)
        keys.getValue(fixtureResource) shouldBe "library"
        keys.getValue(BookDefinition.id) shouldBe "book"
        assembly.diagnosticCodes(fixtureResource) shouldNotContain "duplicate_search_key"
    }

    test("two owner types with one search key are rejected and publish no search key") {
        val owner = fixtureType(fixtureResource)
        val ownership =
            RelationContract(
                id = RelationId("fixture.ownership"),
                first = endpoint("fixture.owner", EndpointSlot.First, fixtureResource),
                second = endpoint("fixture.owned", EndpointSlot.Second, BookDefinition.id),
                families = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val bookOwnership =
            RelationContract(
                id = RelationId("fixture.book_ownership"),
                first = endpoint("fixture.book", EndpointSlot.First, BookDefinition.id),
                second = endpoint("fixture.book_owned", EndpointSlot.Second, fixtureResource),
                families = setOf(RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID)),
            )
        val assembly =
            assemble(
                declarations = listOf(owner),
                searchKeys = mapOf(fixtureResource to "book"),
                relations = listOf(ownership, bookOwnership),
            )

        assembly.diagnosticCodes(BookDefinition.id) shouldBe listOf("duplicate_search_key")
        assembly.diagnosticCodes(fixtureResource) shouldBe listOf("duplicate_search_key")
        assembly.snapshot.types
            .filter { it.definition.id == BookDefinition.id || it.definition.id == fixtureResource }
            .map { it.searchKey } shouldBe listOf(null, null)
    }
}

private val fixtureResource = TypeDefinitionId(TypeId.Qualified("fixture", "DisplayResource"), 1)
private val fixturePage = TypeDefinitionId(TypeId.Qualified("fixture", "DisplayPage"), 1)

private fun fixtureType(
    id: TypeDefinitionId,
    parent: TypeDefinitionId? = null,
    display: TypeDisplay? = null,
) = id to
    Pair(
        TypeDefinition(
            id,
            representation = RepresentationTemplate.Record(emptyList()),
            parents = listOfNotNull(parent).map { TypeTemplate.Named(it) },
        ),
        display,
    )

private fun endpoint(
    id: String,
    slot: EndpointSlot,
    resource: TypeDefinitionId,
) = EndpointDefinition(EndpointId(id), slot, TypeTemplate.Named(resource), EndpointCardinality.Many, RelationDeletePolicy.CLEAR)

private fun book(title: String) =
    AuthoringRecord(
        TypeSelection.Complete(BookDefinition.use),
        mapOf(
            "title" to DataValue.StringValue(title),
            "icon" to DataValue.Unfilled,
            "color" to DataValue.Unfilled,
            "tags" to DataValue.Unfilled,
            "pages" to DataValue.Unfilled,
        ),
    )

private class FixtureDisplay(
    override val target: ResourceTarget,
    private val build: () -> DisplayFormulas,
) : GeneratedResourceDisplayProvider {
    override fun formulas(): DisplayFormulas = build()
}

private fun displayProvider(
    target: ResourceTarget,
    build: () -> DisplayFormulas,
) = OwnedResourceDisplay(providerOrigin(), FixtureDisplay(target, build))

private fun assemble(
    declarations: List<Pair<TypeDefinitionId, Pair<TypeDefinition, TypeDisplay?>>> = emptyList(),
    displays: List<OwnedResourceDisplay> = emptyList(),
    searchKeys: Map<TypeDefinitionId, String> = emptyMap(),
    relations: List<RelationContract> = emptyList(),
    includeGenerated: Boolean = true,
): CatalogAssembly {
    val origin = providerOrigin()
    val generated = generatedTypeProviders().distinctBy { it.definition.id }
    val generatedDisplays =
        generatedProviders<GeneratedResourceDisplayProvider>(GeneratedProviderKind.ResourceDisplay)
            .filter { includeGenerated || it.target == ResourceTarget.AnyResource }
            .map { OwnedResourceDisplay(origin, it) }
    return CatalogContributions(
        declarations =
            generated.map { OwnedTypeDeclaration(origin, it.definition, it.display, searchKey = it.searchKey) } +
                declarations.map { (id, declared) ->
                    OwnedTypeDeclaration(origin, declared.first, declared.second, searchKey = searchKeys[id])
                },
        relations = generatedProviders<GeneratedRelationProvider>(GeneratedProviderKind.Relation).map { it.contract } + relations,
        displays = generatedDisplays + displays,
    ).assemble(CatalogAssemblyContext(CatalogGeneration("resource displays")))
}

private fun CatalogAssembly.diagnosticCodes(type: TypeDefinitionId): List<String> =
    snapshot.diagnostics.filter { it.affected == type }.map { it.code }

private fun CatalogAssembly.label(record: AuthoringRecord): String? = with(DisplayReads) { displays.label(record, checked) }

/** Evaluates one checked display formula of the subject [record] the way editors do: the record is the subject. */
private fun CatalogAssembly.evaluate(
    formula: com.typewritermc.expression.CheckedExpressionProgram,
    record: AuthoringRecord,
): DataValue? {
    val subject = DataValue.Named((record.configuration as TypeSelection.Complete).use, DataValue.Record(record.fields))
    val types = snapshot.types.associateBy { it.definition.id }
    val queries =
        object : com.typewritermc.expression.CanonicalQueryReader {
            override val catalog = checked

            context(reads: AuthoredReads)
            override fun resource(id: ResourceId) = Availability.Unavailable(emptyList())

            context(reads: AuthoredReads)
            override fun declaration(id: TypeDefinitionId) = Availability.Available(types.getValue(id))
        }
    val result =
        with(DisplayReads) {
            DefaultExpressionEvaluator(ExpressionValueReader { error("The subject is a local value") }, queries)
                .evaluateChecked(
                    formula,
                    ExpressionBindings(emptyMap()),
                    EvaluationBudget(1_000, 1_000),
                    mapOf(ExpressionBindingId("configured_value") to subject),
                )
        }
    return (result as? Availability.Available)?.value
}

private object DisplayReads : AuthoredReads {
    override val catalog = CatalogGeneration("resource displays")
    override val readContext = ReadContext(catalog)

    override fun <T> read(path: BoundPath<T>): Availability<T> = error("Display formulas read portable values")

    override fun <T> readRepresentation(
        path: BoundPath<*>,
        representation: TypeUse,
    ): Availability<T> = error("Display formulas read portable values")

    override fun presence(path: BoundPath<*>): Availability<Boolean> = error("Display formulas read portable values")

    override fun binding(path: BoundPath<*>): Availability<DraftBinding> = error("Display formulas read portable values")

    override fun canonicalValueKey(path: BoundPath<*>): Availability<String> = error("Display formulas read portable values")

    override fun members(path: BoundCollectionPath): List<ItemId> = emptyList()

    override fun <D> select(query: TypedSelection<D>): PartialSelection<D> = error("Display formulas read portable values")
}
