package com.typewritermc.engine.runtime.testing

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
import com.typewritermc.engine.Root
import com.typewritermc.engine.runtime.CompiledResourceGraph
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledEdge
import skirout.editor.v1.compiled_content.CompiledEdgeOrigin
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse

/** One refused publication: the case name, the shards it arrives in, and the start of the refusal message. */
data class GraphRejection(
    val name: String,
    val facts: List<RuntimeCompilationFacts>,
    val reason: String,
)

/** The resource key of the page that roots the publication in the fixtures. */
val PAGE = key("page")

/** The resource key of the second resource that edges point at in the fixtures. */
val OTHER = key("other")

private val TEXT_TYPE = TypeDefinitionId.qualified("test", "text")
private val PROVIDER = NativeBindingId(value = "test")
private const val SIGNATURE = "test:v1"
private val catalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "compiled resource graph test"),
        listOf(TypeDefinition.partial(id = TEXT_TYPE, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))),
    )

/** Assembles [facts] with the fixture catalog and the text binding factory. */
fun assemble(facts: List<RuntimeCompilationFacts>) =
    CompiledResourceGraph.assemble(facts, emptyList(), catalog, FactoryNativeBindingRegistry(catalog, listOf(TextBindingFactory)))

/** A resource key for [resource] in the root compilation context. */
fun key(resource: String) = CompiledResourceKey(source = ResourceId(resource).toSkir(), context = CompilationContext.Root)

/** Publication facts rooted at [PAGE] with the given [resources] and [edges]. */
fun facts(
    vararg resources: CompiledResource,
    edges: List<CompiledEdge> = emptyList(),
) = RuntimeCompilationFacts(
    formatRevision = RESOURCE_GRAPH_FORMAT_REVISION,
    root = PAGE,
    resources = resources.toList(),
    edges = edges,
    types = emptyList(),
    relations = emptyList(),
)

/** A compiled text resource at [key] that was bound by the fixture provider, unless the arguments override it. */
fun resource(
    key: CompiledResourceKey,
    type: TypeDefinitionId = TEXT_TYPE,
    payload: DataValue = DataValue.StringValueWrapper("value"),
    provider: NativeBindingId = PROVIDER,
    signature: String = SIGNATURE,
) = CompiledResource(
    key = key,
    actualType = type.namedUse(),
    bindingProvider = provider,
    bindingSignature = signature,
    value = NamedValue(actualType = type.namedUse(), payload = payload),
)

/** A relation edge from [PAGE] to [OTHER] carrying [relation]. */
fun edge(relation: RelationId) =
    CompiledEdge(
        source = PAGE,
        target = OTHER,
        origin = CompiledEdgeOrigin.createRelation(relation = relation, firstLocation = null, secondLocation = null),
    )

/** Binds the text type the way a generated provider binds its declared type. */
object TextBindingFactory : NativeBindingFactory {
    override val definition = TEXT_TYPE
    override val provider = PROVIDER

    override fun bind(
        actual: CheckedType,
        arguments: AppliedNativeArguments,
    ): NativeBinding<*> =
        object : NativeBinding<String> {
            override val provider = PROVIDER
            override val signature = SIGNATURE
            override val actualType: TypeUse = actual.use

            override fun encode(value: String): DataValue = DataValue.StringValueWrapper(value)

            override fun decode(value: CompleteValue): String = "hydrated value"
        }
}
