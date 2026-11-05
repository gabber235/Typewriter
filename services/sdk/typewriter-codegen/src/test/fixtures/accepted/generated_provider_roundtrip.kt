@file:JvmName("GeneratedProviderRoundtrip")

package fixture

import build.skir.JsonFlavor
import io.kotest.assertions.assertSoftly
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.assertions.withClue
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import skirout.editor.v1.type_catalog.ExpressionBindingId
import skirout.editor.v1.catalog.PreparationTarget
import skirout.editor.v1.catalog.ValuePreparationRequest
import com.typewritermc.types.type
import skirout.editor.v1.type_catalog.ResourceTarget
import com.typewritermc.configuration.name
import skirout.editor.v1.type_catalog.CatalogGeneration
import com.typewritermc.authoring.root
import com.typewritermc.types.fields
import com.typewritermc.types.items
import com.typewritermc.types.integer
import com.typewritermc.types.record
import com.typewritermc.types.named
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.field
import com.typewritermc.authoring.fieldMap
import skirout.editor.v1.catalog.PreparedContent
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import java.math.BigInteger
import kotlinx.serialization.Transient
import kotlinx.serialization.SerialName
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.literal
import com.typewritermc.expression.eq
import com.typewritermc.expression.orElse
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.expression.ExpressionNode
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.CollectionProjection
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.presentation.collectionProjection
import com.typewritermc.presentation.projectedCollectionSource
import skirout.editor.v1.catalog.PresentationRole
import skirout.editor.v1.type_catalog.RepresentationTemplate
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.shortcuts.orIfBlank
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports
import com.typewritermc.types.catalog.Resolution
import java.nio.file.Path
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.NamedTypeUse
import com.typewritermc.types.use
import com.typewritermc.types.template
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.integerScalar

/** Names an Example by its title, keeping the type display accent and icon. */
object ExampleNaming : ExampleDisplay {
    override fun ExampleDisplayScope.label() = title.orIfBlank(defaultLabel())
}

@TypewriterDisplay(
    name = "Example",
    description = "Generated provider display fixture",
    icon = "material-symbols:description",
    color = "#123456",
)
@TypewriterType(id = "a0000000000000000000000000000090")
data class Example(
    val title: String = "",
    val selectedTag: ResourceId = ResourceId("fixture.tag"),
    val selectedTags: List<ResourceId> = listOf(ResourceId("fixture.tag")),
    val unstable: String = failingDefault(),
    val details: ExampleRow? = null,
    val rows: List<ExampleRow> = emptyList(),
    val labels: Map<String, ExampleRow> = emptyMap(),
    val children: List<Ref<ExampleChildren.Parent, Example>> = emptyList(),
) : Resource {
    companion object : ExampleConfiguration {
        override fun ExampleConfigurationScope.configure() {
            title { nonBlank() }
            details { whenPresent { title { nonBlank() } } }
            rows {
                items { title { rule { value eq value }.error("self equal") } }
                uniqueBy { title }
            }
            labels {
                keys { nonBlank() }
                values { title { nonBlank() } }
            }
        }
    }
}

private fun failingDefault(): String = error("fixture default failure")

/** Examples own nested examples, so the Example type is the member of an ownership relation. */
@ReferenceContract("a00000000000000000000000000000a1")
interface ExampleChildrenContract : Owning {
    @DeletionPolicy(RelationDeletePolicy.CASCADE)
    interface Parent : One<Example>

    interface Child : Many<Example>
}

@TypewriterType(id = "a0000000000000000000000000000097")
data class ExampleRow(
    val title: String,
    val value: String = "",
    val receiverExpression: String = "",
)

@TypewriterType(id = "a0000000000000000000000000000098")
sealed interface StoredContract {
    val stored: String

    val computed: String
        get() = stored.uppercase()
}

@TypewriterType(id = "a0000000000000000000000000000099")
data class StoredValue(
    override val stored: String,
) : StoredContract

private var defaultEvaluations = 0
private var constructorEvaluations = 0
fun evaluationCounts(): Pair<Int, Int> = defaultEvaluations to constructorEvaluations
private fun dependentDefault(base: Int): Int { defaultEvaluations += 1; return base * 3 }

@TypewriterType(id = "a0000000000000000000000000000100")
data class DependentDefaults(
    @SerialName("seed") val base: Int = 2,
    val derived: Int = dependentDefault(base),
    val nullable: String? = "fallback",
    val guarded: Int = error("guarded must be supplied"),
) {
    init { constructorEvaluations += 1 }
}

@TypewriterType(id = "a0000000000000000000000000000101")
data class GenericDefaults<T>(val value: T, val duplicate: T = value)

@JvmInline
@TypewriterType(id = "a0000000000000000000000000000102")
value class DefaultCount(val value: Int)

@TypewriterType(id = "a0000000000000000000000000000103")
data class WrappedDefaults(val count: DefaultCount = DefaultCount(3), val doubled: Int = count.value * 2)

@TypewriterType(id = "a0000000000000000000000000000104")
data class CancelledDefaults(val value: String = throw kotlinx.coroutines.CancellationException("cancel defaults"))

@TypewriterType(id = "a0000000000000000000000000000105")
data class TransientDefaults(@Transient val hidden: Int = 5, val derived: Int = hidden * 2)

@TypewriterCollectionProjection
fun exampleCollectionProjection(): CollectionProjection<Example, ExampleRow, ExampleRowExpressions> =
    collectionProjection<Example, ExampleRow, ExampleRowExpressions>(
        sourceId = "fixture.examples",
        root = ExampleDefinition.id.namedTemplate(),
        rowType = ExampleRowDefinition.id.template(),
        expressions = ExampleRowExpressionsFactory,
    ) {
        content(ExampleRowFields.title, ExampleFields.title)
    }

@TypewriterTypeImports(ResourceId::class)
private object FixtureTypeImports

object ExampleInspector : ExamplePresentation {
    override val roles: Set<PresentationRole> = setOf(PresentationRole.INSPECTOR)

    override fun ExamplePresentationScope.present() {
        val examples =
            exampleCollectionProjection().projectedCollectionSource {
                relation("identity", resource)
            }
        title { textInput() }
        rows {
            listInput {
                showIf({ (expressions.title eq expressions.title).orElse(literal(false)) }) {
                    title { textInput() }
                }
            }
        }
        collectionLookup(examples, selectedTag.input) {
            found { text(literal("found")) }
            missing { text(literal("missing")) }
        }
        collectionGraph(examples) {
            root(selectedTag.input)
            relation("identity")
            node { text(literal("tag")) }
        }
        collectionGraph(examples) {
            roots(selectedTags.input)
            relation("identity")
            node { text(literal("tag")) }
        }
    }
}

private class FixtureParent(
    parent: ClassLoader,
) : ClassLoader(parent) {
    override fun loadClass(
        name: String,
        resolve: Boolean,
    ): Class<*> {
        if (name.startsWith("fixture.")) throw ClassNotFoundException(name)
        if (
            name.startsWith("com.typewritermc.types.ResourceId") &&
            name != ResourceId::class.java.name &&
            !name.startsWith("${ResourceId::class.java.name}\$")
        ) {
            throw ClassNotFoundException(name)
        }
        return super.loadClass(name, resolve)
    }
}

/** Checks one requirement; every requirement runs and reports its own failures under [name]. */
private fun requirement(name: String, block: () -> Unit) = withClue(name) { assertSoftly { block() } }

private fun integer(value: Int) = DataValue.integer(BigInteger.valueOf(value.toLong()))

fun main(args: Array<String>) {
    requirement("type displays default from the declaration and keep an explicit display") {
        StoredContractDefinition.display shouldBe
            TypeDisplay(name = "Stored contract", description = "", icon = TypeDisplay.DEFAULT_ICON, color = TypeDisplay.DEFAULT_COLOR)
        StoredContractDefinition.searchKey shouldBe null
        ExampleDefinition.display shouldBe
            TypeDisplay(
                name = "Example",
                description = "Generated provider display fixture",
                icon = com.typewritermc.types.Icon.Iconify("material-symbols:description"),
                color = com.typewritermc.types.Color(0xFF123456u),
            )
        ExampleDefinition.searchKey shouldBe "example"
    }
    requirement("a computed property is no stored field") {
        StoredContractDefinition.declaration.representation.shouldBeInstanceOf<RepresentationTemplate.RecordWrapper>()
            .value.fields.map { it.owner.name } shouldBe listOf("stored")
        StoredValueDefinition.declaration.representation.shouldBeInstanceOf<RepresentationTemplate.RecordWrapper>()
            .value.fields.map { it.owner.name } shouldBe listOf("stored")
    }
    requirement("row expressions read each row field from the source") {
        val source = com.typewritermc.expression.input<Any?>(ExpressionBindingId(value = "fixture"))
        val rowExpressions = ExampleRowExpressionsFactory.create(source)
        fun field(name: String) = com.typewritermc.expression.input<Any?>(ExpressionBindingId(value = "fixture"), ValuePath.root.field(name)).toNode()
        rowExpressions.title.toNode() shouldBe field("title")
        rowExpressions.value.toNode() shouldBe field("value")
        rowExpressions.receiverExpression.toNode() shouldBe field("receiverExpression")
    }
    val runtime = DefaultPresentationRuntime()
    val artifact = Path.of(args.single())
    GeneratedProviderLoader()
        .load(
            artifacts = listOf(GeneratedProviderArtifact(ArtifactId("fixture:generated-provider"), artifact)),
            facts = DeploymentFacts(),
            domain = DiscoveryDomains.Realm,
            acceptedKinds =
                setOf(
                    GeneratedProviderKind.Type,
                    GeneratedProviderKind.NativeBinding,
                    GeneratedProviderKind.Relation,
                    GeneratedProviderKind.EndpointBindings,
                    GeneratedProviderKind.Configuration,
                    GeneratedProviderKind.Presentation,
                    GeneratedProviderKind.ResourceDisplay,
                ),
            runtimeServices = mapOf(PresentationRuntime::class.java to runtime),
            parentClassLoader = FixtureParent(requireNotNull(Example::class.java.classLoader)),
        ).use { deployment ->
            val contributions = deployment.providers.contributions
            val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "fixture")))
            requirement("the loaded artifact publishes the display and search key in the editor catalog") {
                contributions.displays.single().provider.target shouldBe ResourceTarget.type(ExampleDefinition.id.namedTemplate())
                assembly.editorCatalog.resourceDisplays.single().target shouldBe
                    skirout.editor.v1.type_catalog.ResourceTarget.TypeWrapper(ExampleDefinition.id.template())
                assembly.editorCatalog.types.single { it.definition.id == ExampleDefinition.id }.searchKey shouldBe "example"
            }
            requirement("configuration rules reach nested, item, key and value paths") {
                contributions.configurations shouldHaveSize 1
                val configuredPaths =
                    assembly.configuration.filter { it.rules.isNotEmpty() }.map { recipe ->
                        recipe.relativePath.segments.joinToString(".") { segment ->
                            when (segment) {
                                is skirout.editor.v1.type_catalog.FieldPatternSegment.FieldWrapper -> segment.name
                                skirout.editor.v1.type_catalog.FieldPatternSegment.ITEMS -> "items"
                                skirout.editor.v1.type_catalog.FieldPatternSegment.KEYS -> "keys"
                                skirout.editor.v1.type_catalog.FieldPatternSegment.VALUES -> "values"
                                else -> error("Unknown field pattern segment.")
                            }
                        }
                    }
                configuredPaths.shouldContainAll("title", "details.title", "rows.items.title", "labels.keys", "labels.values.title")
            }
            requirement("sampling defaults reports a failing native default instead of throwing") {
                val checked =
                    when (val resolved = assembly.checked.resolve(ExampleDefinition.id.use())) {
                        is Resolution.Ready -> resolved.value
                        is Resolution.Invalid -> error(resolved.diagnostics.joinToString())
                    }
                assembly.bindings.sampleDefaults(checked, emptyMap()).shouldBeInstanceOf<CaptureResult.Unavailable>()
                    .reasons.single().code shouldBe "native_default_capture_failed"
            }
            val probeLoader =
                contributions.nativeBindings.single { it.factory.definition == DependentDefaultsDefinition.id }
                    .factory.nativeClass!!.java.classLoader
            fun counts(): Pair<*, *> =
                probeLoader.loadClass("fixture.GeneratedProviderRoundtrip").getMethod("evaluationCounts").invoke(null) as Pair<*, *>
            val initializer = DefaultInitializationRuntime(assembly.checked, assembly.bindings)
            fun prepare(type: NamedTypeUse, fields: Map<String, DataValue>) =
                initializer.prepareNow(
                    ValuePreparationRequest(
                        catalog = assembly.checked.generation,
                        target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(type)),
                        suppliedValue = DataValue.record(fields),
                    ),
                )
            fun fieldsOf(content: PreparedContent) = content.shouldBeInstanceOf<PreparedContent.RecordWrapper>().value.fieldMap
            val supplied = mapOf("seed" to integer(7), "nullable" to DataValue.NULL, "guarded" to integer(20))
            requirement("dependent defaults compute from supplied fields once and never for complete or blocked input") {
                val preparedDefaults = prepare(DependentDefaultsDefinition.use, supplied)
                preparedDefaults.findings.shouldBeEmpty()
                val defaults = fieldsOf(preparedDefaults.content)
                defaults["derived"] shouldBe integer(21)
                defaults["nullable"] shouldBe DataValue.NULL
                counts() shouldBe (1 to 1)

                val completeInputs = defaults + ("derived" to DataValue.UNFILLED)
                val explicitUnfinished = prepare(DependentDefaultsDefinition.use, completeInputs)
                explicitUnfinished.findings.shouldBeEmpty()
                fieldsOf(explicitUnfinished.content) shouldBe completeInputs
                counts() shouldBe (1 to 1)

                val blocked = prepare(DependentDefaultsDefinition.use, supplied + ("seed" to DataValue.UNFILLED))
                blocked.findings.single().relativePath?.segments shouldBe listOf(PathSegment.createField(name = "seed"))
                counts() shouldBe (1 to 1)

                prepare(DependentDefaultsDefinition.use, mapOf("derived" to integer(99))).findings.single().message shouldBe
                    "guarded must be supplied"
                counts() shouldBe (1 to 1)
            }
            requirement("transient, generic and value class defaults prepare their computed fields") {
                val transient = prepare(TransientDefaultsDefinition.use, emptyMap())
                transient.findings.shouldBeEmpty()
                fieldsOf(transient.content) shouldBe mapOf("derived" to integer(10))
                val intType = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
                val generic = prepare(GenericDefaultsDefinition.applied(listOf(intType)), mapOf("value" to integer(9)))
                generic.findings.shouldBeEmpty()
                fieldsOf(generic.content)["duplicate"] shouldBe integer(9)
                val wrapped = prepare(WrappedDefaultsDefinition.use, mapOf("count" to DataValue.named(DefaultCountDefinition.use, integer(8))))
                wrapped.findings.shouldBeEmpty()
                fieldsOf(wrapped.content)["doubled"] shouldBe integer(16)
            }
            requirement("a cancelled default cancels preparation") {
                shouldThrow<kotlinx.coroutines.CancellationException> { prepare(CancelledDefaultsDefinition.use, emptyMap()) }
            }
            requirement("generated providers operate under a freshly assembled catalog and resolver") {
                var replacementCountBindings = 0
                val replacementContributions =
                    contributions.copy(
                        nativeBindings =
                            contributions.nativeBindings.map { owned ->
                                if (owned.factory.definition != DefaultCountDefinition.id) {
                                    owned
                                } else {
                                    owned.copy(
                                        factory =
                                            object : com.typewritermc.types.NativeBindingFactory by owned.factory {
                                                override fun bind(
                                                    actual: com.typewritermc.types.catalog.CheckedType,
                                                    arguments: com.typewritermc.authoring.AppliedNativeArguments,
                                                ): com.typewritermc.types.NativeBinding<*> {
                                                    replacementCountBindings += 1
                                                    return owned.factory.bind(actual, arguments)
                                                }
                                            },
                                    )
                                }
                            },
                    )
                val replacement = replacementContributions.assemble(CatalogAssemblyContext(CatalogGeneration(value = "fixture replacement")))
                val replacementInitializer = DefaultInitializationRuntime(replacement.checked, replacement.bindings)
                fun prepareReplacement(type: NamedTypeUse, fields: Map<String, DataValue>) =
                    replacementInitializer.prepareNow(
                        ValuePreparationRequest(
                            catalog = replacement.checked.generation,
                            target = PreparationTarget.RecordWrapper(TypeSelection.CompleteWrapper(type)),
                            suppliedValue = DataValue.record(fields),
                        ),
                    )
                replacementCountBindings = 0
                val replacementWrapped =
                    prepareReplacement(WrappedDefaultsDefinition.use, mapOf("count" to DataValue.named(DefaultCountDefinition.use, integer(8))))
                replacementWrapped.findings.shouldBeEmpty()
                fieldsOf(replacementWrapped.content)["doubled"] shouldBe integer(16)
                replacementCountBindings shouldBe 1
                val replacementDefaults = prepareReplacement(DependentDefaultsDefinition.use, supplied)
                replacementDefaults.findings.shouldBeEmpty()
                fieldsOf(replacementDefaults.content)["derived"] shouldBe integer(21)
                counts() shouldBe (2 to 2)
            }
            requirement("the inspector draws one collection graph per declared root field") {
                contributions.presentations shouldHaveSize 1
                val material = assembly.editorCatalog.presentationMaterials.single()
                material.dependencies.collections.single().relations.single().relationId shouldBe "identity"
                material.layout.collectionGraphRootFields() shouldContainExactlyInAnyOrder listOf("selectedTag", "selectedTags")
            }
        }
}

/**
 * The root field each collection graph anywhere in this layout reads, found in the readable wire form so the check
 * holds whatever containers wrap the graphs.
 */
private fun PresentationNode.collectionGraphRootFields(): List<String> {
    val graphs = mutableListOf<JsonObject>()
    fun visit(element: JsonElement) {
        when (element) {
            is JsonObject -> {
                if (element["kind"]?.jsonPrimitive?.content == "collection_graph") graphs += element.getValue("value").jsonObject
                element.values.forEach(::visit)
            }
            is JsonArray -> element.forEach(::visit)
            else -> Unit
        }
    }
    visit(PresentationNode.serializer.toJson(this, JsonFlavor.READABLE))
    return graphs.map { graph ->
        val names = mutableListOf<String>()
        fun fieldNames(element: JsonElement) {
            when (element) {
                is JsonObject -> {
                    if (element["kind"]?.jsonPrimitive?.content == "field") {
                        names += element.getValue("value").jsonObject.getValue("name").jsonPrimitive.content
                    }
                    element.values.forEach(::fieldNames)
                }
                is JsonArray -> element.forEach(::fieldNames)
                else -> Unit
            }
        }
        fieldNames(graph.getValue("roots"))
        names.single()
    }
}
