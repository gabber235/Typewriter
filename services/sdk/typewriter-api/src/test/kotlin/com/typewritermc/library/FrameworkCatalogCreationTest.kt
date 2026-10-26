@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.library

import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.name
import com.typewritermc.authoring.payload
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.expression.literal
import com.typewritermc.presentation.DefaultPresentationRegistry
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.Layout
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationBuildScope
import com.typewritermc.presentation.PresentationProvider
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.PresentationSelection
import com.typewritermc.presentation.RecordControl
import com.typewritermc.presentation.TextControl
import com.typewritermc.presentation.allNodes
import com.typewritermc.presentation.invoke
import com.typewritermc.presentation.of
import com.typewritermc.presentation.presentationPart
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.encodeGeneratedDefault
import com.typewritermc.types.field
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requirePortable
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainInOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import java.lang.reflect.Modifier
import java.math.BigInteger
import java.util.Collections
import kotlin.reflect.KClass
import skirout.editor.v1.expression.ExpressionNode as WireExpressionNode
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment

val FrameworkCatalogCreationTest by testSuite {
    test("the element graph presentation reaches every concrete element unless a concrete presentation targets it") {
        val concreteId = TypeDefinitionId.qualified("test", "ConcreteEntry")
        val catalog =
            DefaultCheckedCatalog(
                CatalogGeneration(value = "entry graph inheritance"),
                StandardTypes.definitions + framework.definitions +
                    TypeDefinition.partial(
                        id = concreteId,
                        representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                        parents = listOf(ElementDefinition.id.namedTemplate()),
                    ),
            )
        val checked = catalog.resolve(concreteId.use()).ready()
        val inherited =
            com.typewritermc.elements
                .ElementGraphNodePresentation_ElementPresentationProvider(DefaultPresentationRuntime())
                .descriptor(origin("element_graph"))
        val concrete =
            inherited.copy(
                id = PresentationId(namespace = "test", name = "concrete entry graph"),
                target = PresentationTarget.NamedWrapper(concreteId.namedTemplate()),
                priority = inherited.priority - 1,
            )

        DefaultPresentationRegistry(catalog, listOf(inherited)).selected(PresentationRole.ITEM, checked) shouldBe inherited.id
        DefaultPresentationRegistry(catalog, listOf(inherited, concrete)).selected(PresentationRole.ITEM, checked) shouldBe concrete.id
    }

    test("a new book starts with the book icon and no findings") {
        val book = framework.prepareBook()

        book.findings shouldBe emptyList()
        book.record.fieldMap.getValue("icon") shouldBe
            DataValue.named(
                IconIconifyDefinition.use,
                DataValue.record(mapOf("value" to DataValue.StringValueWrapper("material-symbols:book"))),
            )
    }

    test("a new tag starts unnamed, without parents, at the origin of the graph") {
        val tag = framework.prepareTag()

        tag.findings shouldBe emptyList()
        tag.record.fieldMap.getValue("name") shouldBe DataValue.StringValueWrapper("")
        (tag.record.fieldMap.getValue("parents") as DataValue.NamedWrapper).payload shouldBe DataValue.setValue(emptyList())
        tag.record.fieldMap.getValue("placement") shouldBe
            DataValue.named(
                GraphPlacementDefinition.use,
                DataValue.record(
                    mapOf(
                        "x" to DataValue.integer(BigInteger.ZERO),
                        "y" to DataValue.integer(BigInteger.ZERO),
                        "width" to DataValue.integer(BigInteger.ONE),
                        "height" to DataValue.integer(BigInteger.ONE),
                    ),
                ),
            )
    }

    test("every iconify search source shows its results with one presentation") {
        val layout =
            framework.build(
                "CoreIconSdkProvider_IconIconifyPresentationProvider",
                IconIconifyDefinition.use,
                PresentationRole.INSPECTOR,
            )
        val results =
            layout
                .elementsOf<PresentationElement.SearchInputWrapper>()
                .single()
                .value.provider
                .resultPresentations()

        results shouldHaveSize 2
        results.distinct() shouldHaveSize 1
        results.first() shouldNotBe null
    }

    test("the book inspector shows title, icon, color, direct tags and effective tags in order") {
        val layout = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)

        layout.sections() shouldContainInOrder
            listOf("Title" to "title", "Icon" to "icon", "Color" to "color", "Direct Tags" to "tags", "Effective Tags" to null)
    }

    test("the tag inspector shows name, color, direct parents, inheritance and placement in order") {
        val layout = framework.build("TagInspectorPresentation_TagPresentationProvider", TagDefinition.use)

        layout.sections() shouldContainInOrder
            listOf("Name" to "name", "Color" to "color", "Direct Parents" to "parents", "Inheritance" to null, "Placement" to "placement")
    }

    test("the page inspector shows book, name, chapter and priority in order") {
        val layout = framework.build("PageInspectorPresentation_PagePresentationProvider", PageDefinition.use)

        layout.sections() shouldContainInOrder listOf("Book" to "book", "Name" to "name", "Chapter" to "chapter", "Priority" to "priority")
    }

    test("the book icon field offers the iconify and svg icon editors") {
        val iconify = framework.presentation("CoreIconSdkProvider_IconIconifyPresentationProvider").descriptor
        val svg = framework.presentation("CoreIconSdkProvider_IconSvgPresentationProvider").descriptor
        val layout = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)
        val options =
            layout
                .elementsOf<PresentationElement.PolymorphicInputWrapper>()
                .single()
                .value.concreteTypes

        options.map { it.concreteType } shouldBe listOf(IconIconifyDefinition.use.use, IconSvgDefinition.use.use)
        options.map { (it.presentation?.element as PresentationElement.InvocationWrapper).value.presentationId?.name } shouldBe
            listOf(iconify.id.name, svg.id.name)
    }

    test("effective tags of a book and the inheritance of a tag draw the tag parents graph") {
        val book = framework.build("BookInspectorPresentation_BookPresentationProvider", BookDefinition.use)
        val tag = framework.build("TagInspectorPresentation_TagPresentationProvider", TagDefinition.use)

        for (layout in listOf(book, tag)) {
            val graph = layout.elementsOf<PresentationElement.CollectionGraphWrapper>().single().value
            graph.sourceId shouldBe TAG_COLLECTION_SOURCE_ID
            graph.relationId shouldBe "parents"
        }
    }

    test("reference previews of books, tags and pages show the resource's appearance") {
        val previews =
            listOf(
                framework.build(
                    "BookReferencePresentation_BookPresentationProvider",
                    BookDefinition.use,
                    PresentationRole.REFERENCE_PREVIEW,
                ),
                framework.build("TagReferencePresentation_TagPresentationProvider", TagDefinition.use, PresentationRole.REFERENCE_PREVIEW),
                framework.build(
                    "PageReferencePresentation_PagePresentationProvider",
                    PageDefinition.use,
                    PresentationRole.REFERENCE_PREVIEW,
                ),
            )

        for (preview in previews) {
            val leading = preview.elementsOf<PresentationElement.AdaptiveLeadingWrapper>().single().value
            (leading.leading.element as PresentationElement.IconWrapper).value.name.appearanceField() shouldBe "icon"
        }
        val book =
            previews
                .first()
                .elementsOf<PresentationElement.AdaptiveLeadingWrapper>()
                .single()
                .value
        (book.center!!.element as PresentationElement.TextWrapper).value.value.appearanceField() shouldBe "label"
    }

    test("the placement inspector labels its fields X, Y, W and H") {
        val layout =
            framework.build(
                "PlacementSdkProvider_GraphPlacementPresentationProvider",
                GraphPlacementDefinition.use,
            )
        val prefixes =
            layout.elementsOf<PresentationElement.NumericInputWrapper>().map { numeric ->
                val prefix = requireNotNull(numeric.value.content).leading as skirout.editor.v1.presentation.InputAdornment.ContentWrapper
                val text = prefix.value.element as PresentationElement.TextWrapper
                ((text.value.value as WireExpressionNode.LiteralWrapper).value as DataValue.StringValueWrapper).value
            }

        prefixes shouldBe listOf("X", "Y", "W", "H")
    }

    test("the compiled control catalog assembles its inherited inspectors without failures") {
        val assembly = controlCatalogAssembly(DefaultPresentationRuntime())
        val materials = assembly.editorCatalog.presentationMaterials

        assembly.callbackFailures.map { "${it.callback}: ${it.cause}" } shouldBe emptyList()
        assembly.editorCatalog.diagnostics.filter { it.code.contains("display") || it.code.contains("search_key") } shouldBe emptyList()
        assembly.editorCatalog.diagnostics.filter { it.code.contains("presentation") } shouldBe emptyList()
        materials
            .single {
                it.role == PresentationRole.INSPECTOR &&
                    (it.target as? PresentationTarget.NamedWrapper)?.value?.definition == ElementDefinition.id
            }.inheritableNodes shouldHaveSize 3
        materials
            .single { it.provider == PresentationId(namespace = "fixture", name = "entry inspector") }
            .inheritableNodes shouldHaveSize 3
    }
}

/** The framework catalog of the generated providers on the test classpath, with their native bindings. */
private class FrameworkFixture {
    val generation = CatalogGeneration(value = "framework creation")
    private val entries = generatedProviderEntries()
    val definitions =
        entries
            .filter { it.kind == GeneratedProviderKind.Type }
            .map { (instantiateGeneratedProvider(Class.forName(it.providerClass)) as GeneratedTypeProvider).definition }
            .distinctBy(TypeDefinition::id)
    val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + definitions)
    private val factories =
        entries
            .filter { it.kind == GeneratedProviderKind.NativeBinding }
            .map { instantiateGeneratedProvider(Class.forName(it.providerClass)) as NativeBindingFactory }
            .distinctBy(NativeBindingFactory::provider)
    private val bindings = FactoryNativeBindingRegistry(catalog, factories)
    private val initializer = DefaultInitializationRuntime(catalog, bindings)
    val runtime = DefaultPresentationRuntime()

    /** Describing every generated presentation registers the references other presentations invoke. */
    private val presentations = frameworkContributions(runtime).presentations
    private val resourceTypes =
        factories
            .mapNotNull { factory ->
                val native = factory.nativeClass ?: return@mapNotNull null
                val definition = definitions.singleOrNull { it.id == factory.definition } ?: return@mapNotNull null
                native to definition.id.namedTemplate(definition.parameters.map { it.key.template })
            }.toMap()

    /** Books and tags are always created into their section, so creation supplies the owner link. */
    fun prepareBook(): PreparedValue =
        initializer.prepareNow(
            request(
                BookDefinition.use,
                mapOf(
                    "library" to
                        owner(
                            LibraryBooks.Book.Definition.id
                                .namedUse(listOf(LibraryDefinition.use.use)),
                            "library",
                        ),
                ),
            ),
        )

    fun prepareTag(): PreparedValue =
        initializer.prepareNow(
            request(
                TagDefinition.use,
                mapOf(
                    "taxonomy" to
                        owner(
                            TaxonomyTags.Tag.Definition.id
                                .namedUse(listOf(TaxonomyDefinition.use.use)),
                            "taxonomy",
                        ),
                ),
            ),
        )

    /** The generated presentation whose provider class is [name], as discovery describes it. */
    fun presentation(name: String): OwnedPresentation = presentations.single { it.provider.javaClass.simpleName == name }

    /** The layout of the generated presentation [name] for [use] in [role]. */
    fun build(
        name: String,
        use: NamedTypeUse,
        role: PresentationRole = PresentationRole.INSPECTOR,
    ): PresentationNode = build(presentation(name).provider, use, role)

    /** The layout [provider] builds for [use] in [role]. */
    fun build(
        provider: PresentationProvider,
        use: NamedTypeUse,
        role: PresentationRole = PresentationRole.INSPECTOR,
    ): PresentationNode =
        provider
            .build(PresentationBuildBinding(catalog.resolve(use.use).ready().presentationTemplate(), role, resourceTypes))
            .layout

    private fun owner(
        link: NamedTypeUse,
        target: String,
    ): DataValue =
        bindings
            .bind(catalog.resolve(link.use).ready())
            .encodeGeneratedDefault(com.typewritermc.types.Ref<Nothing, Nothing>(com.typewritermc.types.ResourceId(target)))

    private fun request(
        use: NamedTypeUse,
        supplied: Map<String, DataValue>,
    ) = ValuePreparationRequest(
        catalog = generation,
        target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(use)),
        suppliedValue = DataValue.record(supplied),
    )
}

private val framework by lazy { FrameworkFixture() }

private fun DefaultPresentationRegistry.selected(
    role: PresentationRole,
    checked: com.typewritermc.types.catalog.CheckedType,
): PresentationId = (select(role, checked) as PresentationSelection.Selected).descriptor.id

/** Each section header in layout order: its literal title and the configured field it binds, if any. */
private fun PresentationNode.sections(): List<Pair<String, String?>> =
    allNodes().mapNotNull { node ->
        val header = node.header ?: return@mapNotNull null
        val title =
            (header.title as? PresentationHeaderTitle.TextWrapper)?.value as? WireExpressionNode.LiteralWrapper ?: return@mapNotNull null
        val field =
            header.binding
                ?.path
                ?.segments
                ?.singleOrNull() as? WirePathSegment.FieldWrapper
        (title.value as DataValue.StringValueWrapper).value to field?.value?.name
    }

/** The result presentation of every source in this provider tree, at any depth. */
private fun SearchProvider.resultPresentations(): List<PresentationNode?> =
    when (this) {
        is SearchProvider.StaticValuesWrapper -> listOf(value.result.presentation)
        is SearchProvider.HttpJsonWrapper -> listOf(value.result.presentation)
        is SearchProvider.RealmCallbackWrapper -> listOf(value.result.presentation)
        is SearchProvider.CollectionWrapper -> listOf(value.result.presentation)
        is SearchProvider.MergeWrapper -> value.children.flatMap { it.resultPresentations() }
        else -> wrappedChild()?.resultPresentations().orEmpty()
    }

/** The one provider a wrapping provider (gate, debounce, cache, rank, limit, distinct, history, section) refines. */
private fun SearchProvider.wrappedChild(): SearchProvider? =
    when (this) {
        is SearchProvider.GateWrapper -> value.child
        is SearchProvider.DebounceWrapper -> value.child
        is SearchProvider.CacheWrapper -> value.child
        is SearchProvider.RankWrapper -> value.child
        is SearchProvider.LimitWrapper -> value.child
        is SearchProvider.DistinctWrapper -> value.child
        is SearchProvider.HistoryWrapper -> value.child
        is SearchProvider.SectionWrapper -> value.child
        else -> null
    }

private fun instantiateGeneratedProvider(type: Class<*>): Any =
    type.fields
        .singleOrNull { field ->
            field.name == "INSTANCE" && Modifier.isStatic(field.modifiers) && field.type === type
        }?.get(null)
        ?: type.getConstructor().newInstance()

/** The field of the presented resource's appearance this expression reads directly, or null for any other expression. */
private fun WireExpressionNode.appearanceField(): String? {
    val input = (this as? WireExpressionNode.InputWrapper)?.value ?: return null
    if (input.binding.value != "presentation.subject.appearance") return null
    return (input.path.segments.single() as WirePathSegment.FieldWrapper).value.name
}

private fun generatedProviderEntries(): List<com.typewritermc.discovery.GeneratedProviderIndexEntry> {
    val resources =
        Collections.list(
            requireNotNull(Thread.currentThread().contextClassLoader).getResources("META-INF/typewriter/generated-providers"),
        )
    return resources
        .flatMap { resource ->
            resource.openStream().bufferedReader().use { GeneratedProviderIndex.parse(it.readText()) }
        }.distinct()
}

private val PreparedValue.record
    get() = (content as PreparedContent.RecordWrapper).value

/**
 * The panel's compiled control fixtures from the framework: the assembled control catalog and the encoded book, tag,
 * placement, element and inherited inspector values, by file name.
 */
internal fun frameworkControlFixtures(): Map<String, ByteArray> {
    val tag = framework.prepareTag().record
    val book = framework.prepareBook().record
    val placement = tag.fieldMap.getValue("placement")
    val wire = controlCatalogAssembly(DefaultPresentationRuntime()).editorCatalog
    return mapOf(
        "element-value.bin" to
            DataValue
                .named(
                    entryGraphFixtureType.namedUse(),
                    DataValue.record(mapOf("name" to DataValue.StringValueWrapper("Welcome to the village"))),
                ).bytes(),
        "inherited-inspector-value.bin" to
            DataValue
                .named(
                    inspectorMessageFixtureType.namedUse(),
                    DataValue.record(
                        mapOf(
                            "name" to DataValue.StringValueWrapper("Welcome"),
                            "message" to DataValue.StringValueWrapper("Hello player"),
                            "other" to DataValue.StringValueWrapper("Cooldown"),
                            "notes" to DataValue.StringValueWrapper("Shared note"),
                            "placement" to placement,
                        ),
                    ),
                ).bytes(),
        "book.bin" to AuthoringRecord.serializer.toBytes(book).toByteArray(),
        "book-value.bin" to DataValue.named(BookDefinition.use, DataValue.RecordWrapper(book.payload)).bytes(),
        "catalog.bin" to EditorCatalog.serializer.toBytes(wire).toByteArray(),
        "tag.bin" to AuthoringRecord.serializer.toBytes(tag).toByteArray(),
        "tag-value.bin" to DataValue.named(TagDefinition.use, DataValue.RecordWrapper(tag.payload)).bytes(),
        "placement.bin" to placement.bytes(),
    )
}

private fun DataValue.bytes(): ByteArray = DataValue.serializer.toBytes(requirePortable()).toByteArray()

/** The framework catalog plus an entry graph type and an inherited inspector family, as the panel fixtures use it. */
private fun controlCatalogAssembly(runtime: PresentationRuntime): com.typewritermc.discovery.CatalogAssembly {
    val inspectorOrigin = origin("fixture_entry_inspector")
    val entryInspector =
        OwnedPresentation(
            inspectorOrigin,
            PresentationDescriptor.of(
                id = PresentationId(namespace = "fixture", name = "entry inspector"),
                owner = inspectorOrigin.owner,
                target = PresentationTarget.NamedWrapper(entryGraphFixtureType.namedTemplate()),
                roles = setOf(PresentationRole.INSPECTOR),
                priority = 0,
            ),
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding) =
                    runtime.build(binding) { scope ->
                        scope.field<String, TextControl>("name", TextControl::class)()
                        scope.remainingFields()
                    }
            },
        )
    val framework = frameworkContributions(runtime)
    val contributions =
        framework.copy(
            declarations =
                framework.declarations +
                    OwnedTypeDeclaration(
                        origin("fixture_entry"),
                        TypeDefinition.partial(
                            id = entryGraphFixtureType,
                            representation = RepresentationTemplate.createRecord(fields = emptyList(), abstract_ = false),
                            parents = listOf(ElementDefinition.id.namedTemplate()),
                        ),
                        com.typewritermc.types.TypeDisplay(
                            "Message action",
                            "Entry graph fixture",
                            Icon.Iconify("fa6-solid:message"),
                            com.typewritermc.types.Color(0xFFE74C3Cu),
                        ),
                    ) + inheritedInspectorDeclarations(),
            presentations = framework.presentations + entryInspector + inheritedInspectorPresentations(runtime),
        )
    return contributions.assemble(com.typewritermc.discovery.CatalogAssemblyContext(CatalogGeneration(value = "compiled controls fixture")))
}

private val entryGraphFixtureType =
    TypeDefinitionId.qualified("fixture", "MessageEntry")

private interface CompiledInspectorFamily : Element {
    override val placement: GraphPlacement
    val notes: String
}

private val inspectorFamilyFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorFamily")
private val inspectorMessageFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorMessage")

private fun inheritedInspectorDeclarations(): List<OwnedTypeDeclaration> {
    val family =
        TypeDefinition.partial(
            id = inspectorFamilyFixtureType,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorFamilyFixtureType, name = "placement"),
                                type = GraphPlacementDefinition.id.template(),
                                overrides =
                                    listOf(
                                        FieldOwner(definition = ElementDefinition.id, name = "placement"),
                                    ),
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorFamilyFixtureType, name = "notes"),
                                type = ScalarKind.TEXT.template,
                            ),
                        ),
                    abstract_ = true,
                ),
            parents = listOf(ElementDefinition.id.namedTemplate()),
        )
    val message =
        TypeDefinition.partial(
            id = inspectorMessageFixtureType,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf("message", "other").map { name ->
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = inspectorMessageFixtureType, name = name),
                                type = ScalarKind.TEXT.template,
                            )
                        },
                    abstract_ = false,
                ),
            parents = listOf(inspectorFamilyFixtureType.namedTemplate()),
        )
    return listOf(
        OwnedTypeDeclaration(
            origin("inherited_inspector_family"),
            family,
            nativeClass = CompiledInspectorFamily::class,
        ),
        OwnedTypeDeclaration(origin("inherited_inspector_message"), message),
    )
}

private fun inheritedInspectorPresentations(runtime: PresentationRuntime): List<OwnedPresentation> {
    val heading = presentationPart<Element>("fixture_heading")
    val details = presentationPart<CompiledInspectorFamily>("fixture_details")

    fun provider(
        name: String,
        target: TypeDefinitionId,
        body: (PresentationBuildScope) -> Unit,
    ): OwnedPresentation {
        val owner = origin(name.replace(' ', '_'))
        return OwnedPresentation(
            owner,
            PresentationDescriptor.of(
                id = PresentationId(namespace = "fixture", name = name),
                owner = owner.owner,
                target =
                    PresentationTarget
                        .NamedWrapper(target.namedTemplate()),
                roles = setOf(PresentationRole.INSPECTOR),
                priority = 0,
            ),
            object : PresentationProvider {
                override fun build(binding: PresentationBuildBinding) = runtime.build(binding, body)
            },
        )
    }
    return listOf(
        provider("inherited family inspector", inspectorFamilyFixtureType) { scope ->
            val name =
                scope.field<String, TextControl>(
                    "name",
                    TextControl::class,
                )
            val notes =
                scope.field<String, TextControl>(
                    "notes",
                    TextControl::class,
                )

            @Suppress("UNCHECKED_CAST")
            val placement =
                scope
                    .field<GraphPlacement, RecordControl<Layout>>(
                        "placement",
                        RecordControl::class as KClass<RecordControl<Layout>>,
                    )
            with(scope) {
                name()
                heading { text(literal("Entry heading")) }
                details {
                    section {
                        text(literal("Shared details"))
                        notes {
                            label("Notes")
                            textInput()
                        }
                    }
                }
                remainingFields()
                placement(using = PlacementSdkProvider)
            }
        },
        provider("inherited child inspector", inspectorMessageFixtureType) { scope ->
            val name =
                scope.field<String, TextControl>(
                    "name",
                    TextControl::class,
                )
            val message =
                scope.field<String, TextControl>(
                    "message",
                    TextControl::class,
                )
            with(scope) {
                name()
                heading()
                message {
                    label("Message")
                    textInput()
                }
                remainingFields()
            }
        },
    )
}

/**
 * Every contribution the framework generates on the test classpath, with presentations built by [runtime], so tests
 * assemble the core catalog exactly as discovery would.
 */
internal fun frameworkContributions(
    runtime: PresentationRuntime = DefaultPresentationRuntime(),
): com.typewritermc.discovery.CatalogContributions {
    val entries = generatedProviderEntries()

    fun instance(entry: com.typewritermc.discovery.GeneratedProviderIndexEntry): Any {
        val type = Class.forName(entry.providerClass)
        return if (entry.kind ==
            GeneratedProviderKind.Presentation
        ) {
            type.getConstructor(PresentationRuntime::class.java).newInstance(runtime)
        } else {
            instantiateGeneratedProvider(type)
        }
    }
    val exportedKinds =
        setOf(
            GeneratedProviderKind.Type,
            GeneratedProviderKind.Presentation,
            GeneratedProviderKind.Configuration,
            GeneratedProviderKind.NativeBinding,
            GeneratedProviderKind.Relation,
            GeneratedProviderKind.EndpointBindings,
            GeneratedProviderKind.ResourceDisplay,
            GeneratedProviderKind.ResourceOperation,
        )
    val providers = entries.filter { it.kind in exportedKinds }.associateWith(::instance)
    val declarations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Type }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedTypeProvider
            com.typewritermc.discovery.OwnedTypeDeclaration(
                origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                provider.definition,
                provider.display,
                provider.nativeClass,
                provider.searchKey,
            )
        }
    val presentations =
        providers.filterKeys { it.kind == GeneratedProviderKind.Presentation }.map { (entry, value) ->
            val provider = value as com.typewritermc.discovery.GeneratedPresentationProvider
            val owner = origin(entry.providerClass.substringAfterLast('.').replace('$', '_'))
            com.typewritermc.discovery.OwnedPresentation(owner, provider.descriptor(owner), provider)
        }
    return com.typewritermc.discovery.CatalogContributions(
        declarations = declarations,
        presentations = presentations,
        configurations =
            providers.filterKeys { it.kind == GeneratedProviderKind.Configuration }.map { (entry, value) ->
                val provider = value as com.typewritermc.discovery.GeneratedConfigurationProvider
                com.typewritermc.discovery.OwnedConfiguration(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    provider.target,
                    provider,
                )
            },
        nativeBindings =
            providers.filterKeys { it.kind == GeneratedProviderKind.NativeBinding }.map { (entry, value) ->
                com.typewritermc.discovery.OwnedNativeBinding(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    value as NativeBindingFactory,
                )
            },
        relations =
            providers
                .filterKeys {
                    it.kind == GeneratedProviderKind.Relation
                }.values
                .map { (it as com.typewritermc.discovery.GeneratedRelationProvider).contract },
        endpointBindings =
            providers
                .filterKeys {
                    it.kind == GeneratedProviderKind.EndpointBindings
                }.values
                .flatMap { (it as com.typewritermc.discovery.GeneratedEndpointBindingsProvider).bindings },
        displays =
            providers.filterKeys { it.kind == GeneratedProviderKind.ResourceDisplay }.map { (entry, value) ->
                com.typewritermc.discovery.OwnedResourceDisplay(
                    origin(entry.providerClass.substringAfterLast('.').replace('$', '_')),
                    value as com.typewritermc.discovery.GeneratedResourceDisplayProvider,
                )
            },
        operations =
            providers.filterKeys { it.kind == GeneratedProviderKind.ResourceOperation }.map { (entry, value) ->
                (value as com.typewritermc.discovery.GeneratedResourceOperationProvider)
                    .contribute(origin(entry.providerClass.substringAfterLast('.').replace('$', '_')))
            },
    )
}
