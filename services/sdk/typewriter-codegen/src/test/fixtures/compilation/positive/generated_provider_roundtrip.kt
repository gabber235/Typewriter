package fixture

import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.authoring.CaptureResult
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.SamplingInputs
import com.typewritermc.authoring.TypewriterResourceDefinition
import com.typewritermc.discovery.CatalogAssemblyContext
import com.typewritermc.discovery.DeploymentFacts
import com.typewritermc.discovery.DiscoveryDomains
import com.typewritermc.discovery.GeneratedProviderArtifact
import com.typewritermc.discovery.GeneratedProviderInstantiator
import com.typewritermc.discovery.GeneratedProviderKind
import com.typewritermc.discovery.GeneratedProviderLoader
import com.typewritermc.discovery.assemble
import com.typewritermc.expression.literal
import com.typewritermc.expression.eq
import com.typewritermc.expression.orElse
import com.typewritermc.expression.portableExpression
import com.typewritermc.expression.ExpressionBindingId
import com.typewritermc.authoring.ValuePath
import com.typewritermc.presentation.ExpressionNode
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
import com.typewritermc.types.Resource
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

object FixtureResources {
    @TypewriterResourceDefinition("fixture.example", Example::class)
    val EXAMPLE = ResourceDefinitionId("fixture.example")
}

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

fun main() {
    check(StoredContractDefinition.display == null)
    check(
        ExampleDefinition.display ==
            TypeDisplay(
                name = "Example",
                description = "Generated provider display fixture",
                icon = "material-symbols:description",
                color = "#123456",
            ),
    )
    val contractRepresentation = StoredContractDefinition.declaration.representation as RepresentationTemplate.Record
    check(contractRepresentation.fields.map { it.owner.name } == listOf("stored"))
    val valueRepresentation = StoredValueDefinition.declaration.representation as RepresentationTemplate.Record
    check(valueRepresentation.fields.map { it.owner.name } == listOf("stored"))
    val source = portableExpression<Any?>(ExpressionNode.Read(ExpressionBindingId("fixture"), ValuePath()))
    val rowExpressions = ExampleRowExpressionsFactory.create(source)
    check(rowExpressions.title.node == ExpressionNode.Read(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("title")))))
    check(rowExpressions.value.node == ExpressionNode.Read(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("value")))))
    check(rowExpressions.receiverExpression.node == ExpressionNode.Read(ExpressionBindingId("fixture"), ValuePath(listOf(com.typewritermc.authoring.PathSegment.Field("receiverExpression")))))
    val runtime = DefaultPresentationRuntime()
    val artifact = Path.of(requireNotNull(System.getProperty("fixtureArtifact")))
    GeneratedProviderLoader()
        .load(
            artifacts = listOf(GeneratedProviderArtifact(ArtifactId("fixture:generated-provider"), artifact)),
            facts = DeploymentFacts(),
            domain = DiscoveryDomains.Realm,
            acceptedKinds =
                setOf(
                    GeneratedProviderKind.Type,
                    GeneratedProviderKind.NativeBinding,
                    GeneratedProviderKind.Resource,
                    GeneratedProviderKind.Configuration,
                    GeneratedProviderKind.Presentation,
                ),
            instantiator =
                GeneratedProviderInstantiator.resolving { requested ->
                    require(requested == PresentationRuntime::class.java)
                    runtime
                },
            parentClassLoader = FixtureParent(requireNotNull(Example::class.java.classLoader)),
        ).use { deployment ->
            val contributions = deployment.providers.contributions
            check(contributions.configurations.size == 1)
            check(contributions.presentations.size == 1)
            check(contributions.resources.single().root == ExampleDefinition.id)
            val assembly = contributions.assemble(CatalogAssemblyContext(CatalogGeneration("fixture")))
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
            val capture = assembly.bindings.sampleDefaults(checked, SamplingInputs(emptyMap()))
            check((capture as CaptureResult.Unavailable).reasons.single().code == "native_default_capture_failed")
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
    val read = roots as skirout.editor.v1.expression.ExpressionNode.ReadWrapper
    val segment = read.value.path.segments.single() as PathSegment.FieldWrapper
    return segment.value.name
}
