@file:OptIn(GeneratedSdkApi::class)

package com.typewritermc.presentation

import com.typewritermc.authoring.Availability
import com.typewritermc.authoring.GeneratedSdkApi
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.text
import com.typewritermc.configuration.field
import com.typewritermc.configuration.of
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.CatalogContributions
import com.typewritermc.discovery.OwnedPresentation
import com.typewritermc.discovery.OwnedTypeDeclaration
import com.typewritermc.discovery.ProviderOrigin
import com.typewritermc.discovery.assemble
import com.typewritermc.discovery.contributionKey
import com.typewritermc.expression.Handled
import com.typewritermc.expression.eq
import com.typewritermc.expression.field
import com.typewritermc.expression.input
import com.typewritermc.expression.literal
import com.typewritermc.expression.orElse
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ContributionName
import com.typewritermc.imprint.ContributionSourceId
import com.typewritermc.imprint.ProducerId
import com.typewritermc.library.coreTagCollectionProjection
import com.typewritermc.presentation.of
import com.typewritermc.testkit.boundControl
import com.typewritermc.testkit.buildPresentation
import com.typewritermc.testkit.bytes
import com.typewritermc.testkit.definitions
import com.typewritermc.testkit.elementsOf
import com.typewritermc.testkit.fixedChildren
import com.typewritermc.testkit.iconName
import com.typewritermc.testkit.literalText
import com.typewritermc.testkit.literalValue
import com.typewritermc.testkit.origin
import com.typewritermc.testkit.ready
import com.typewritermc.testkit.singleFixed
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceId
import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.catalog.apply
import com.typewritermc.types.field
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.of
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.requireValid
import com.typewritermc.types.rows
import com.typewritermc.types.setValue
import com.typewritermc.types.template
import com.typewritermc.types.text
import com.typewritermc.types.toTemplate
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldNotThrowAny
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.catalog.DeclarationStatus
import skirout.editor.v1.catalog.PresentationDescriptor
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.catalog.PresentationTarget
import skirout.editor.v1.catalog.RepresentationKind
import skirout.editor.v1.catalog.RoleFallback
import skirout.editor.v1.expression.ExpressionNode
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.ChoicePresentation
import skirout.editor.v1.presentation.CollectionGraphDirection
import skirout.editor.v1.presentation.ControlDensity
import skirout.editor.v1.presentation.CrossAxisAlignment
import skirout.editor.v1.presentation.FlexFit
import skirout.editor.v1.presentation.ImageFit
import skirout.editor.v1.presentation.MainAxisAlignment
import skirout.editor.v1.presentation.PresentationAlignment
import skirout.editor.v1.presentation.PresentationContextSource
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationInteractionState
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.presentation.PresentationTextTone
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.PresentationId
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.ValuePath

internal fun descriptor(
    name: String,
    target: PresentationTarget,
    priority: Int,
    role: PresentationRole = PresentationRole.WORKSPACE,
): PresentationDescriptor =
    PresentationDescriptor.of(
        skirout.editor.v1.type_catalog
            .PresentationId(namespace = "test", name = name),
        DeclarationOwner(
            source =
                contributionKey(
                    ContributionSourceId("test"),
                    "main",
                    ProducerId("test"),
                    ContributionName(name.replace(' ', '_')),
                ),
            localIdentity = name,
        ),
        target,
        setOf(role),
        priority,
    )

internal interface TestPositionScope : Layout {
    val x: PresentedField<Int, NumberControl<Int>>
}

internal class TestPositionScopeImpl(
    private val build: PresentationBuildScope,
) : TestPositionScope,
    Layout by build {
    @Suppress("UNCHECKED_CAST")
    override val x: PresentedField<Int, NumberControl<Int>>
        get() = build.field("x", NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>)
}

internal class ProjectionFixtureResource : Resource

internal object ProjectionFixtureExpressionsFactory : com.typewritermc.expression.ExpressionFactory<ProjectionFixtureExpressions> {
    override val scope = ProjectionFixtureExpressions::class

    override fun create(
        value: com.typewritermc.expression.Expr<*, out com.typewritermc.expression.MissingPolicy>,
    ): ProjectionFixtureExpressions = object : ProjectionFixtureExpressions {}
}

internal interface ProjectionFixtureExpressions

/** Declares [definition] a resource type, which collection projections may read. */
internal fun ownedResource(
    origin: ProviderOrigin,
    definition: TypeDefinition,
): OwnedTypeDeclaration =
    OwnedTypeDeclaration(
        origin,
        definition,
        searchKey =
            definition.id
                .toString()
                .filter(Char::isLetter)
                .lowercase(),
    )

/** One of each display element with its options configured, in declaration order. */
internal fun displayElements(): List<PresentationElement> {
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "display options"), StandardTypes.definitions)
    val checked = catalog.ready(ScalarKind.TEXT.use)
    val color = literalColor(com.typewritermc.types.Color(0xff3366ccu))
    val result =
        DefaultPresentationRuntime().build(
            PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.INSPECTOR),
        ) { build ->
            with(build) {
                image(literal("https://example.test/image.png")) {
                    width(80.0)
                    height(literal(60.0))
                    fit(ImageFit.COVER)
                    radius(PresentationRadius.Small)
                }
                badge(literal("Ready")) {
                    textStyle(TextStyle(weight = FontWeight(500)))
                    fill(color)
                    icon("book", size = 14.0)
                }
                chip(literal("Label")) {
                    noIcon()
                    noBorder()
                    density(ControlDensity.COMPACT)
                }
                progress(literal(3), literal(10)) {
                    color(color)
                    backgroundColor(color)
                    minimumHeight(5.0)
                    radius(PresentationRadius.Small)
                }
                tooltip(literal("Details"), configure = {
                    waitDelay(DisplayDelay(250))
                    showDelay(DisplayDelay(2000))
                    preferBelow(false)
                    fill(color)
                }) { text(literal("Help")) }
                divider {
                    color(color)
                    thickness(2.0)
                    space(literal(12.0))
                    indent(4.0)
                    endIndent(6.0)
                }
                tabs {
                    density(ControlDensity.COMPACT)
                    spacing(Spacing(4.0))
                    contentSpacing(Spacing(10.0))
                    tab("first", literal("First"), icon = "book") { text(literal("Content")) }
                }
                status(
                    literal(true),
                    listOf(
                        StatusCase(
                            true,
                            StatusAppearance("Active", "active") {
                                noIcon()
                                textStyle(TextStyle(weight = FontWeight(600)))
                            },
                        ),
                    ),
                )
                dateTime(literal(kotlin.time.Instant.fromEpochMilliseconds(1000)), literal("yyyy")) {
                    noIcon()
                    textStyle(TextStyle(weight = FontWeight(500)))
                }
                relativeTime(literal(kotlin.time.Instant.fromEpochMilliseconds(1000))) {
                    noIcon()
                    density(ControlDensity.COMPACT)
                }
            }
        }
    return result.layout.fixedChildren().map { requireNotNull(it.element) }
}

/** A row of an x and a y coordinate editor, configured in different orders, and a fixed text. */
internal fun coordinateRow(): skirout.editor.v1.presentation.AxisChildrenElement {
    val id = TypeDefinitionId.qualified("test", "ConfiguredCoordinates")
    val number = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template
    val definition =
        definitions {
            record(id) {
                field("x", number)
                field("y", number)
            }
        }.single()
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "configured coordinates"), listOf(definition))
    val checked = catalog.ready(id.use())

    fun NumericInputScope<Int>.coordinateInput() {
        step(2)
        density(ControlDensity.COMPACT)
        selectAllOnFocus()
        textStyle(TextStyle(weight = FontWeight(500)))
    }
    val result =
        DefaultPresentationRuntime().build(
            PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
        ) { build ->
            with(build) {
                @Suppress("UNCHECKED_CAST")
                val scope = NumberControl::class as kotlin.reflect.KClass<NumberControl<Int>>
                val x: PresentedField<Int, NumberControl<Int>> = field("x", scope)
                val y: PresentedField<Int, NumberControl<Int>> = field("y", scope)
                row {
                    x {
                        numericInput {
                            coordinateInput()
                            placeholder("X")
                            noIcon()
                            prefix { text(literal("axis")) }
                            onComplete { value }
                        }
                        label("Horizontal")
                        readOnly()
                        enabledIf(literal(false))
                    }
                    y {
                        label("Vertical")
                        numericInput {
                            coordinateInput()
                            placeholder(literal("Y"))
                        }
                    }
                    text(literal("units"))
                }
            }
        }
    return ((result.layout.singleFixed().element as PresentationElement.ChildrenWrapper).value as ChildrenElement.RowWrapper).value
}

/** The wire appearance of a list input over text items whose collection appearance [configure] sets. */
internal fun collectionAppearance(configure: CollectionAppearanceScope.() -> Unit): skirout.editor.v1.presentation.CollectionAppearance {
    val result =
        DefaultPresentationRuntime().build(
            PresentationBuildBinding(CompositeFixture.checked.presentationTemplate(), PresentationRole.WORKSPACE),
        ) { build ->
            with(CompositeFixture) {
                build.textList().invoke {
                    listInput {
                        configure()
                        items { textInput() }
                    }
                }
            }
        }
    return (result.layout.singleFixed().element as PresentationElement.ListInputWrapper).value.appearance
        ?: error("A list input always sends its appearance.")
}

/** A subject with list, set, map, named scalar and nested record fields that the composite editors bind into. */
internal object CompositeFixture {
    val wrapperId = TypeDefinitionId.qualified("test", "Code")
    val positionId = TypeDefinitionId.qualified("test", "Position")
    val subjectId = TypeDefinitionId.qualified("test", "CompositeSubject")
    val integer = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
    val position =
        definitions {
            record(positionId) {
                field("x", integer.template)
                field("y", integer.template)
            }
        }.single()
    val wrapper =
        TypeDefinition.partial(id = wrapperId, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))
    val subject =
        definitions {
            record(subjectId) {
                field("list", StandardTypes.list.template(listOf(ScalarKind.TEXT.template)))
                field("set", StandardTypes.set.template(listOf(ScalarKind.TEXT.template)))
                field("map", StandardTypes.map.template(listOf(ScalarKind.TEXT.template, integer.template.nullable())))
                field("code", wrapperId.template())
                field("position", positionId.template())
            }
        }.single()
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "nested presentation callbacks"),
            StandardTypes.definitions + wrapper + position + subject,
        )
    val checked = catalog.ready(subjectId.use())

    /** The subject's list of text, edited with text inputs. */
    @Suppress("UNCHECKED_CAST")
    fun PresentationBuildScope.textList(): PresentedField<List<String>, ListControl<TextControl>> =
        field(
            "list",
            ListControl::class as kotlin.reflect.KClass<ListControl<TextControl>>,
            mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
        )

    fun root(): PresentationBuildResult =
        DefaultPresentationRuntime().build(
            PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
        ) { build ->
            with(build) {
                val list = textList()

                @Suppress("UNCHECKED_CAST")
                val set: PresentedField<Set<String>, SetControl<TextControl>> =
                    field(
                        "set",
                        SetControl::class as kotlin.reflect.KClass<SetControl<TextControl>>,
                        mapOf(NestedPresentationSlot.Items to NestedPresentationScope(TextControl::class)),
                    )

                @Suppress("UNCHECKED_CAST")
                val map: PresentedField<Map<String, Int?>, MapControl<TextControl, NullableControl<NumberControl<Int>>>> =
                    field(
                        "map",
                        MapControl::class as kotlin.reflect.KClass<MapControl<TextControl, NullableControl<NumberControl<Int>>>>,
                        mapOf(
                            NestedPresentationSlot.Keys to NestedPresentationScope(TextControl::class),
                            NestedPresentationSlot.Values to
                                NestedPresentationScope(
                                    NullableControl::class,
                                    nested =
                                        mapOf(
                                            NestedPresentationSlot.Values to NestedPresentationScope(NumberControl::class),
                                        ),
                                ),
                        ),
                    )

                @Suppress("UNCHECKED_CAST")
                val code: PresentedField<String, NamedControl<String, TextControl>> =
                    field(
                        "code",
                        NamedControl::class as kotlin.reflect.KClass<NamedControl<String, TextControl>>,
                        mapOf(NestedPresentationSlot.Payload to NestedPresentationScope(TextControl::class)),
                    )

                @Suppress("UNCHECKED_CAST")
                val positionField: PresentedField<Any, RecordControl<TestPositionScope>> =
                    field(
                        "position",
                        RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                        mapOf(
                            NestedPresentationSlot.Fields to
                                NestedPresentationScope(
                                    TestPositionScope::class,
                                    create = { nested -> TestPositionScopeImpl(nested) },
                                ),
                        ),
                    )

                list { listInput { items { textInput() } } }
                set { collectionInput { items { textInput() } } }
                map {
                    mapInput {
                        keys { textInput() }
                        values { nullableInput { value { numericInput() } } }
                    }
                }
                code { namedInput { payload { textInput() } } }
                positionField { recordInput { fields { x { numericInput() } } } }
            }
        }

    fun nestedRemainder(): PresentationBuildResult =
        DefaultPresentationRuntime().build(
            PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE),
        ) { build ->
            with(build) {
                @Suppress("UNCHECKED_CAST")
                val positionField: PresentedField<Any, RecordControl<TestPositionScope>> =
                    field(
                        "position",
                        RecordControl::class as kotlin.reflect.KClass<RecordControl<TestPositionScope>>,
                        mapOf(
                            NestedPresentationSlot.Fields to
                                NestedPresentationScope(TestPositionScope::class, create = { nested -> TestPositionScopeImpl(nested) }),
                        ),
                    )
                positionField {
                    recordInput {
                        fields {
                            x { numericInput { placeholder("X") } }
                            remainingFields()
                        }
                    }
                }
            }
        }
}

/** A subject with one title field and the data nodes built over it: repeated, scoped, typed, lookup, graph, match, invocation. */
internal object PresentationDataFixture {
    val id = TypeDefinitionId.qualified("test", "PresentationDataSubject")
    val definition =
        definitions {
            record(id) {
                field("title", ScalarKind.TEXT.template)
            }
        }.single()
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "presentation data"), StandardTypes.definitions + definition)
    val checked = catalog.ready(id.use())
    val reference = object : PresentationReference {}
    val referenceId =
        skirout.editor.v1.type_catalog
            .PresentationId(namespace = "test", name = "invoked")
    val parameter = presentationParameter<String>("title")
    val runtime =
        DefaultPresentationRuntime().also {
            it.register(reference, descriptor("invoked", PresentationTarget.NamedWrapper(id.namedTemplate()), 0))
        }
    val repeatedSource =
        com.typewritermc.expression.portableLiteral<List<String>>(
            DataValue.listValue(
                listOf(ListItem(id = ItemId(value = "first"), value = DataValue.StringValueWrapper("value"))),
            ),
        )
    val source =
        collectionSource<String, String>("rows", ScalarKind.TEXT.template) {
            key(row)
            relations("children", repeatedSource)
        }
    val other =
        collectionSource<Boolean, String>("rows", ScalarKind.BOOLEAN.template) {
            key(literal("same key type"))
        }

    /** Builds [content] over the subject with its `title` field. */
    fun build(content: PresentationBuildScope.(PresentedField<String, TextControl>) -> Unit): PresentationBuildResult =
        runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
            build.content(build.field("title", TextControl::class))
        }

    fun root(): PresentationBuildResult =
        runtime.build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE)) { build ->
            with(build) {
                val title: PresentedField<String, TextControl> = field("title", TextControl::class)
                repeated<String, String>(repeatedSource) {
                    text(item.orElse(literal("missing")))
                    empty { text(literal("empty")) }
                    separator { divider() }
                }
                scoped(title.input) { textInput() }
                typedField(title.input) { textInput() }
                collectionLookup(source, title.input) {
                    found { text(row.orElse(literal("missing row"))) }
                    missing { text(literal("missing")) }
                    loading { text(literal("loading")) }
                }
                collectionGraph(source) {
                    root(title.input)
                    relation("children", CollectionGraphDirection.REVERSE, maximumDepth = 4)
                    node {
                        text(row.orElse(literal("missing node")))
                        descendants()
                    }
                }
                polymorphicMatch(title.input) {
                    case(AppliedPresentation<String>(id.namedUse(), reference)) {
                        text(literal("subject case"))
                    }
                    fallback { text(literal("fallback")) }
                }
                invoke(reference) { bind(parameter, title.input) }
            }
        }
}

internal fun dataElements(): List<PresentationElement> =
    PresentationDataFixture.root().layout.fixedChildren().map {
        requireNotNull(it.element)
    }

/**
 * The panel's compiled control fixtures from presentation building: the composite, nested remainder, nullable and typed
 * layouts with a value for each, by file name.
 */
internal fun presentationControlFixtures(): Map<String, ByteArray> {
    val root = CompositeFixture.root().layout
    val nestedRemainder = CompositeFixture.nestedRemainder().layout
    val map = (root.fixedChildren()[2].element as PresentationElement.MapInputWrapper).value
    val owner =
        ProviderOrigin(
            descriptor("nested remainder", PresentationTarget.NamedWrapper(CompositeFixture.subjectId.namedTemplate()), 0).owner,
            ArtifactId("test:nested-remainder"),
            "main",
        )
    val nestedRemainderCatalog =
        CatalogContributions(
            declarations =
                listOf(CompositeFixture.wrapper, CompositeFixture.position, CompositeFixture.subject).map {
                    OwnedTypeDeclaration(owner, it)
                },
        ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "nested remainder fixture"))).editorCatalog
    return mapOf(
        "composite-layout.bin" to PresentationNode.serializer.toBytes(root).toByteArray(),
        "composite-value.bin" to
            DataValue
                .record(
                    mapOf(
                        "list" to DataValue.listValue(emptyList()),
                        "set" to DataValue.setValue(emptyList()),
                        "map" to DataValue.mapValue(emptyList()),
                        "code" to DataValue.named(CompositeFixture.wrapperId.namedUse(), DataValue.StringValueWrapper("Authored code")),
                        "position" to
                            DataValue.named(
                                CompositeFixture.positionId.namedUse(),
                                DataValue.record(
                                    mapOf(
                                        "x" to DataValue.integer(java.math.BigInteger.valueOf(7)),
                                        "y" to DataValue.integer(java.math.BigInteger.valueOf(8)),
                                    ),
                                ),
                            ),
                    ),
                ).bytes(),
        "nested-remainder-layout.bin" to PresentationNode.serializer.toBytes(nestedRemainder).toByteArray(),
        "nested-remainder-catalog.bin" to
            skirout.editor.v1.catalog.EditorCatalog.serializer
                .toBytes(nestedRemainderCatalog)
                .toByteArray(),
        "nullable-layout.bin" to PresentationNode.serializer.toBytes(requireNotNull(map.valuePresentation)).toByteArray(),
        "nullable-value.bin" to DataValue.integer(java.math.BigInteger.valueOf(42)).bytes(),
        "typed-layout.bin" to PresentationNode.serializer.toBytes(PresentationDataFixture.root().layout.fixedChildren()[2]).toByteArray(),
        "typed-value.bin" to DataValue.record(mapOf("title" to DataValue.StringValueWrapper("Authored title"))).bytes(),
    )
}

internal val WEIGHTED = TypeDefinitionId.qualified("test", "Weighted")

internal val WEIGHTED_VALUE = ParameterKey(owner = WEIGHTED, index = 0)

internal val SUBJECT = TypeDefinitionId.qualified("test", "LoweringSubject")

/** Presents the weight and value fields of a Weighted<T>, configuring them through [configure]. */
internal fun weighted(
    scope: PresentationBuildScope,
    configure: WeightedFields.(PresentedField<Double, NumberControl<Double>>) -> Unit,
) {
    @Suppress("UNCHECKED_CAST")
    val weight = scope.field<Double, NumberControl<*>>("weight", NumberControl::class) as PresentedField<Double, NumberControl<Double>>

    @Suppress("UNCHECKED_CAST")
    val value = scope.field<Any?, NumberControl<*>>("value", NumberControl::class) as PresentedField<Any?, NumberControl<Any?>>
    WeightedFields(value).configure(weight)
}

internal class WeightedFields(
    val value: PresentedField<Any?, NumberControl<Any?>>,
)

/** A text expression the DSL would not accept, to show that lowering checks the slot type itself. */
@Suppress("UNCHECKED_CAST")
internal fun com.typewritermc.expression.Expr<Boolean, Handled>.uncheckedText(): com.typewritermc.expression.Expr<String, Handled> =
    this as com.typewritermc.expression.Expr<String, Handled>

internal fun weightedAssembly(present: (PresentationBuildScope) -> Unit) =
    CatalogContributions(
        declarations = listOf(OwnedTypeDeclaration(origin("lowering"), weightedDefinition())),
        presentations =
            listOf(
                OwnedPresentation(
                    origin("lowering"),
                    PresentationDescriptor.of(
                        id = PresentationId(namespace = "test", name = "weighted"),
                        owner = origin("lowering").owner,
                        target = PresentationTarget.NamedWrapper(WEIGHTED.namedTemplate(listOf(WEIGHTED_VALUE.template))),
                        roles = setOf(PresentationRole.INSPECTOR),
                        priority = 0,
                    ),
                    object : PresentationProvider {
                        override fun build(binding: PresentationBuildBinding) = DefaultPresentationRuntime().build(binding, present)
                    },
                ),
            ),
    ).assemble(CatalogAssemblyContext(CatalogGeneration(value = "weighted")))

internal fun weightedDefinition(): TypeDefinition =
    TypeDefinition(
        id = WEIGHTED,
        parameters = listOf(TypeParameter(key = WEIGHTED_VALUE, name = "T", bounds = emptyList())),
        representation =
            RepresentationTemplate.createRecord(
                fields =
                    listOf(
                        FieldDeclaration.partial(owner = FieldOwner(definition = WEIGHTED, name = "value"), type = WEIGHTED_VALUE.template),
                        FieldDeclaration.partial(
                            owner = FieldOwner(definition = WEIGHTED, name = "weight"),
                            type = floatScalar(FloatWidth.SIXTY_FOUR).template,
                        ),
                    ),
                form = RecordForm.CONCRETE,
            ),
        parents = emptyList(),
    )

/** Builds [content] for a record with a text title and a list of text tags. */
internal fun build(content: (PresentationBuildScope) -> Unit): PresentationBuildResult {
    val subject =
        TypeDefinition.partial(
            id = SUBJECT,
            representation =
                RepresentationTemplate.createRecord(
                    fields =
                        listOf(
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = SUBJECT, name = "title"),
                                type = ScalarKind.TEXT.template,
                            ),
                            FieldDeclaration.partial(
                                owner = FieldOwner(definition = SUBJECT, name = "tags"),
                                type = StandardTypes.list.template(listOf(ScalarKind.TEXT.template)),
                            ),
                        ),
                    form = RecordForm.CONCRETE,
                ),
        )
    val catalog = DefaultCheckedCatalog(CatalogGeneration(value = "lowering"), StandardTypes.definitions + subject)
    val checked = catalog.ready(SUBJECT.use())
    return DefaultPresentationRuntime().build(PresentationBuildBinding(checked.presentationTemplate(), PresentationRole.WORKSPACE), content)
}
