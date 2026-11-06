@file:OptIn(com.typewritermc.authoring.GeneratedSdkApi::class)

package com.typewritermc.library

import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.authoring.GraphPlacementDefinition
import com.typewritermc.authoring.HierarchyGroupDefinition
import com.typewritermc.authoring.PlacementSdkProvider
import com.typewritermc.authoring.RealmRootDefinition
import com.typewritermc.authoring.fieldMap
import com.typewritermc.authoring.name
import com.typewritermc.authoring.payload
import com.typewritermc.discovery.CatalogAssembly
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.GeneratedProviderIndex
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedTypeProvider
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.assemble
import com.typewritermc.elements.Element
import com.typewritermc.elements.ElementDefinition
import com.typewritermc.expression.Handled
import com.typewritermc.expression.inputExpression
import com.typewritermc.expression.listExpr
import com.typewritermc.expression.literal
import com.typewritermc.expression.name
import com.typewritermc.expression.orElse
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
import com.typewritermc.presentation.createResource
import com.typewritermc.presentation.invoke
import com.typewritermc.presentation.of
import com.typewritermc.presentation.presentationPart
import com.typewritermc.presentation.presentationTemplate
import com.typewritermc.presentation.resource
import com.typewritermc.testkit.actions
import com.typewritermc.testkit.appearanceReads
import com.typewritermc.testkit.bytes
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.generatedProvider
import com.typewritermc.testkit.generatedProviderEntries
import com.typewritermc.testkit.generatedProviders
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.record
import com.typewritermc.testkit.resourcesElement
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.Icon
import com.typewritermc.types.IconIconifyDefinition
import com.typewritermc.types.IconSvgDefinition
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.RESOURCE_OWNERSHIP_FAMILY_ID
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
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainInOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.action.EditorAction
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.EditorCatalog
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.catalog.PreparedValue
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationMaterial
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.catalog.ValuePreparationRequest
import skirout.editor.v1.presentation.GraphDirection
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationHeaderTitle
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationNumber
import skirout.editor.v1.presentation.ResourcesElement
import skirout.editor.v1.presentation.ResourcesLayout
import skirout.editor.v1.presentation.SearchProvider
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import java.lang.reflect.Modifier
import java.math.BigInteger
import java.util.Collections
import kotlin.reflect.KClass
import skirout.editor.v1.catalog.PresentationTarget as WirePresentationTarget
import skirout.editor.v1.expression.ExpressionNode as WireExpressionNode
import skirout.editor.v1.type_catalog.PathSegment as WirePathSegment

/** Builds a Book workspace, with the ownership links of this assembly, whose content [content] declares. */
internal fun CatalogAssembly.buildBook(content: BookPresentationScope.() -> Unit) {
    val ownership =
        relations
            .filter { relation -> relation.families.any { it.value == RESOURCE_OWNERSHIP_FAMILY_ID } }
            .mapTo(hashSetOf()) { it.first.id }
    val binding =
        PresentationBuildBinding(
            checked.ready(BookDefinition.use.use).presentationTemplate(),
            PresentationRole.WORKSPACE,
            ownershipEndpoints = ownership,
        )
    DefaultPresentationRuntime().build(binding) { scope -> BookPresentationScopeImpl(scope).content() }
}

internal fun CatalogAssembly.material(
    type: TypeDefinitionId,
    role: PresentationRole,
): PresentationMaterial {
    val wireType = type
    return editorCatalog.presentationMaterials.single {
        it.role == role && (it.target as? WirePresentationTarget.NamedWrapper)?.value?.definition == wireType
    }
}

internal fun CatalogAssembly.resources(
    type: TypeDefinitionId,
    role: PresentationRole,
): ResourcesElement = material(type, role).layout.resourcesElement()

/** The framework catalog of the generated providers on the test classpath, with their native bindings. */
internal class FrameworkFixture {
    val generation = CatalogGeneration(value = "framework creation")
    val definitions =
        generatedProviders<GeneratedTypeProvider>(GeneratedProviderKind.Type).map { it.definition }.distinctBy(TypeDefinition::id)
    val catalog = DefaultCheckedCatalog(generation, StandardTypes.definitions + definitions)
    private val factories =
        generatedProviders<NativeBindingFactory>(GeneratedProviderKind.NativeBinding).distinctBy(NativeBindingFactory::provider)
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

internal val framework by lazy { FrameworkFixture() }

internal fun DefaultPresentationRegistry.selected(
    role: PresentationRole,
    checked: com.typewritermc.types.catalog.CheckedType,
): PresentationId = (select(role, checked) as PresentationSelection.Selected).descriptor.id

/** Each section header in layout order: its literal title and the configured field it binds, if any. */
internal fun PresentationNode.sections(): List<Pair<String, String?>> =
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
internal fun SearchProvider.resultPresentations(): List<PresentationNode?> =
    when (this) {
        is SearchProvider.StaticValuesWrapper -> listOf(value.result.presentation)
        is SearchProvider.HttpJsonWrapper -> listOf(value.result.presentation)
        is SearchProvider.RealmCallbackWrapper -> listOf(value.result.presentation)
        is SearchProvider.CollectionWrapper -> listOf(value.result.presentation)
        is SearchProvider.MergeWrapper -> value.children.flatMap { it.resultPresentations() }
        else -> wrappedChild()?.resultPresentations().orEmpty()
    }

/** The one provider a wrapping provider (gate, debounce, cache, rank, limit, distinct, history, section) refines. */
internal fun SearchProvider.wrappedChild(): SearchProvider? =
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

/** The field of the presented resource's appearance this expression reads directly, or null for any other expression. */
internal fun WireExpressionNode.appearanceField(): String? {
    val input = (this as? WireExpressionNode.InputWrapper)?.value ?: return null
    if (input.binding.value != "presentation.subject.appearance") return null
    return (input.path.segments.single() as WirePathSegment.FieldWrapper).value.name
}

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

/** The framework catalog plus an entry graph type and an inherited inspector family, as the panel fixtures use it. */
internal fun controlCatalogAssembly(runtime: PresentationRuntime): com.typewritermc.discovery.CatalogAssembly {
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
                            representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
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

internal val entryGraphFixtureType =
    TypeDefinitionId.qualified("fixture", "MessageEntry")

internal interface CompiledInspectorFamily : Element {
    override val placement: GraphPlacement
    val notes: String
}

internal val inspectorFamilyFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorFamily")

internal val inspectorMessageFixtureType =
    TypeDefinitionId.qualified("fixture", "InspectorMessage")

internal fun inheritedInspectorDeclarations(): List<OwnedTypeDeclaration> {
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
                    form = RecordForm.OPEN,
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
                    form = RecordForm.CONCRETE,
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

internal fun inheritedInspectorPresentations(runtime: PresentationRuntime): List<OwnedPresentation> {
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

    fun instance(entry: com.typewritermc.discovery.GeneratedProviderIndexEntry): Any =
        if (entry.kind == GeneratedProviderKind.Presentation) {
            Class.forName(entry.providerClass).getConstructor(PresentationRuntime::class.java).newInstance(runtime)
        } else {
            generatedProvider(entry)
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
