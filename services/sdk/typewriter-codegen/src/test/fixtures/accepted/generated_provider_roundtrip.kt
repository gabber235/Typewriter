@file:JvmName("GeneratedProviderRoundtrip")

package fixture

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.authoring.DefaultInitializationRuntime
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.PreparedContent
import com.typewritermc.authoring.PreparationTarget
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.types.DataValue
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ScalarKind
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
import com.typewritermc.expression.portableExpression
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.authoring.ValuePath
import skirout.editor.v1.expression.ExpressionNode
import com.typewritermc.imprint.ArtifactId
import com.typewritermc.presentation.CollectionProjection
import com.typewritermc.presentation.DefaultPresentationRuntime
import com.typewritermc.presentation.PresentationBuildBinding
import com.typewritermc.presentation.PresentationRuntime
import com.typewritermc.presentation.TypewriterCollectionProjection
import com.typewritermc.presentation.collectionProjection
import com.typewritermc.presentation.projectedCollectionSource
import com.typewritermc.types.PresentationRole
import com.typewritermc.types.RepresentationTemplate
import com.typewritermc.types.DeletionPolicy
import com.typewritermc.types.Many
import com.typewritermc.types.One
import com.typewritermc.types.Owning
import com.typewritermc.types.Ref
import com.typewritermc.types.ReferenceContract
import com.typewritermc.types.RelationDeletePolicy
import com.typewritermc.types.Resource
import com.typewritermc.types.ResourceTarget
import com.typewritermc.types.TypeTemplate
import com.typewritermc.authoring.defaultLabel
import com.typewritermc.expression.orIfBlank
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDisplay
import com.typewritermc.types.TypeUse
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType
import com.typewritermc.types.TypewriterTypeImports
import com.typewritermc.types.catalog.Resolution
import java.nio.file.Path
import skirout.editor.v1.presentation.ChildrenElement
import skirout.editor.v1.presentation.PresentationElement
import skirout.editor.v1.presentation.PresentationNode
import skirout.editor.v1.type_catalog.PathSegment

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
        root = com.typewritermc.types.TypeTemplate.Named(ExampleDefinition.id),
        rowType = com.typewritermc.types.TypeTemplate.Named(ExampleRowDefinition.id),
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

fun main(args: Array<String>) {
    check(
        StoredContractDefinition.display ==
            TypeDisplay(
                name = "Stored contract",
                description = "",
                icon = TypeDisplay.DEFAULT_ICON,
                color = TypeDisplay.DEFAULT_COLOR,
            ),
    )
    check(StoredContractDefinition.searchKey == null)
    check(
        ExampleDefinition.display ==
            TypeDisplay(
                name = "Example",
                description = "Generated provider display fixture",
                icon = com.typewritermc.types.Icon.Iconify("material-symbols:description"),
                color = com.typewritermc.types.Color(0xFF123456u),
            ),
    )
    check(ExampleDefinition.searchKey == "example")
    val contractRepresentation = StoredContractDefinition.declaration.representation as RepresentationTemplate.Record
    check(contractRepresentation.fields.map { it.owner.name } == listOf("stored"))
    val valueRepresentation = StoredValueDefinition.declaration.representation as RepresentationTemplate.Record
    check(valueRepresentation.fields.map { it.owner.name } == listOf("stored"))
    val source = com.typewritermc.expression.input<Any?>(ExpressionBindingId("fixture"))
    val rowExpressions = ExampleRowExpressionsFactory.create(source)
    check(rowExpressions.title.toNode() == com.typewritermc.expression.input<Any?>(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("title")))).toNode())
    check(rowExpressions.value.toNode() == com.typewritermc.expression.input<Any?>(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("value")))).toNode())
    check(rowExpressions.receiverExpression.toNode() == com.typewritermc.expression.input<Any?>(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("receiverExpression")))).toNode())
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
            check(contributions.configurations.size == 1)
            check(contributions.presentations.size == 1)
            check(contributions.displays.single().provider.target == ResourceTarget.Type(TypeTemplate.Named(ExampleDefinition.id)))
            val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration("fixture")))
            check(assembly.snapshot.resourceDisplays.single().target == ResourceTarget.Type(TypeTemplate.Named(ExampleDefinition.id)))
            check(assembly.snapshot.types.single { it.definition.id == ExampleDefinition.id }.searchKey == "example")
            val configuredPaths = assembly.snapshot.configuration.filter { it.rules.isNotEmpty() }
                .map { recipe -> recipe.relativePath.segments.joinToString(".") { segment ->
                    when (segment) {
                        is com.typewritermc.configuration.FieldPatternSegment.Field -> segment.name
                        com.typewritermc.configuration.FieldPatternSegment.Items -> "items"
                        com.typewritermc.configuration.FieldPatternSegment.Keys -> "keys"
                        com.typewritermc.configuration.FieldPatternSegment.Values -> "values"
                    }
                } }.toSet()
            check(configuredPaths.containsAll(setOf("title", "details.title", "rows.items.title", "labels.keys", "labels.values.title")))
            val checked =
                when (val resolved = assembly.checked.resolve(TypeUse.Named(ExampleDefinition.id))) {
                    is Resolution.Ready -> resolved.value
                    is Resolution.Invalid -> error(resolved.diagnostics.joinToString())
                }
            val capture = assembly.bindings.sampleDefaults(checked, emptyMap())
            check((capture as CaptureResult.Unavailable).reasons.single().code == "native_default_capture_failed")
            val probeLoader = contributions.nativeBindings.single { it.factory.definition == DependentDefaultsDefinition.id }
                .factory.nativeClass!!.java.classLoader
            fun counts(): Pair<*, *> = probeLoader.loadClass("fixture.GeneratedProviderRoundtrip").getMethod("evaluationCounts").invoke(null) as Pair<*, *>
            val initializer = DefaultInitializationRuntime(assembly.checked, assembly.bindings)
            fun prepare(type: TypeUse.Named, fields: Map<String, DataValue>) = initializer.prepareNow(
                InitializationRequest(assembly.snapshot.generation, PreparationTarget.Record(TypeSelection.Complete(type)), DataValue.Record(fields)),
            )
            fun integer(value: Int) = DataValue.Integer(BigInteger.valueOf(value.toLong()))
            val supplied = mapOf("seed" to integer(7), "nullable" to DataValue.Null, "guarded" to integer(20))
            val preparedDefaults = prepare(DependentDefaultsDefinition.use, supplied)
            val defaults = (preparedDefaults.content as PreparedContent.Record).record.fields
            check(preparedDefaults.findings.isEmpty())
            check(defaults["derived"] == integer(21) && defaults["nullable"] == DataValue.Null)
            check(counts() == (1 to 1))
            val completeInputs = defaults + ("derived" to DataValue.Unfilled)
            val explicitUnfinished = prepare(DependentDefaultsDefinition.use, completeInputs)
            check(explicitUnfinished.findings.isEmpty())
            check((explicitUnfinished.content as PreparedContent.Record).record.fields == completeInputs)
            check(counts() == (1 to 1))
            val blocked = prepare(DependentDefaultsDefinition.use, supplied + ("seed" to DataValue.Unfilled))
            check(blocked.findings.single().relativePath?.segments == listOf(com.typewritermc.authoring.PathSegment.Field("seed")))
            check(counts() == (1 to 1))
            val throwing = prepare(DependentDefaultsDefinition.use, mapOf("derived" to integer(99)))
            check(throwing.findings.single().message == "guarded must be supplied")
            check(counts() == (1 to 1))
            val transient = prepare(TransientDefaultsDefinition.use, emptyMap())
            check(transient.findings.isEmpty())
            check((transient.content as PreparedContent.Record).record.fields == mapOf("derived" to integer(10)))
            val intType = TypeUse.Scalar(ScalarKind.Integer(IntegerWidth.SIGNED_32))
            val generic = prepare(GenericDefaultsDefinition.applied(listOf(intType)), mapOf("value" to integer(9)))
            check(generic.findings.isEmpty())
            check((generic.content as PreparedContent.Record).record.fields["duplicate"] == integer(9))
            val wrapped = prepare(WrappedDefaultsDefinition.use, mapOf("count" to DataValue.Named(DefaultCountDefinition.use, integer(8))))
            check(wrapped.findings.isEmpty())
            check((wrapped.content as PreparedContent.Record).record.fields["doubled"] == integer(16))
            check(runCatching { prepare(CancelledDefaultsDefinition.use, emptyMap()) }.exceptionOrNull() is kotlinx.coroutines.CancellationException)
            // One generated provider also operates under a freshly assembled catalog and resolver.
            var replacementCountBindings = 0
            val replacementContributions = contributions.copy(nativeBindings = contributions.nativeBindings.map { owned ->
                if (owned.factory.definition != DefaultCountDefinition.id) owned else owned.copy(factory = object : com.typewritermc.types.NativeBindingFactory by owned.factory {
                    override fun bind(actual: com.typewritermc.types.catalog.CheckedType, arguments: com.typewritermc.authoring.AppliedNativeArguments): com.typewritermc.types.NativeBinding<*> {
                        replacementCountBindings += 1
                        return owned.factory.bind(actual, arguments)
                    }
                })
            })
            val replacement = replacementContributions.assemble(CatalogAssemblyContext(CatalogGeneration("fixture replacement")))
            replacementCountBindings = 0
            val replacementWrapped = DefaultInitializationRuntime(replacement.checked, replacement.bindings).prepareNow(
                InitializationRequest(replacement.snapshot.generation, PreparationTarget.Record(TypeSelection.Complete(WrappedDefaultsDefinition.use)),
                    DataValue.Record(mapOf("count" to DataValue.Named(DefaultCountDefinition.use, integer(8))))),
            )
            check(replacementWrapped.findings.isEmpty())
            check((replacementWrapped.content as PreparedContent.Record).record.fields["doubled"] == integer(16))
            check(replacementCountBindings == 1)
            val replacementDefaults = DefaultInitializationRuntime(replacement.checked, replacement.bindings).prepareNow(
                InitializationRequest(replacement.snapshot.generation, PreparationTarget.Record(TypeSelection.Complete(DependentDefaultsDefinition.use)), DataValue.Record(supplied)),
            )
            check(replacementDefaults.findings.isEmpty())
            check((replacementDefaults.content as PreparedContent.Record).record.fields["derived"] == integer(21))
            check(counts() == (2 to 2))
            val material = assembly.snapshot.presentationMaterials.single()
            check(material.layout.nodeId.isNotEmpty())
            check(material.dependencies.collections.single().relations.single().relationId == "identity")
            val graphs =
                material.layout
                    .fixedChildren()
                    .map(PresentationNode::element)
                    .filterIsInstance<PresentationElement.CollectionGraphWrapper>()
            check(graphs.size == 2)
            check(graphs.map { it.value.rootFieldName() } == listOf("selectedTag", "selectedTags"))
        }
}

private fun PresentationNode.fixedChildren(): List<PresentationNode> {
    val column = (element as PresentationElement.ChildrenWrapper).value as ChildrenElement.ColumnWrapper
    return column.value.children.map {
        (it as skirout.editor.v1.presentation.AxisChild.FixedWrapper).value
    }
}

private fun skirout.editor.v1.presentation.CollectionGraphElement.rootFieldName(): String {
    val read = roots as skirout.editor.v1.expression.ExpressionNode.InputWrapper
    val segment = read.value.path.segments.single() as PathSegment.FieldWrapper
    return segment.value.name
}
