package com.typewritermc.engine.runtime

import com.typewritermc.authoring.AppliedNativeArguments
import com.typewritermc.authoring.CompleteValue
import com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION
import com.typewritermc.engine.Root
import com.typewritermc.types.FactoryNativeBindingRegistry
import com.typewritermc.types.NativeBinding
import com.typewritermc.types.NativeBindingFactory
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.CheckedType
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
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

val CompiledResourceGraphTest by testSuite {
    test("a complete publication hydrates every resource through its native binding") {
        val graph = assemble(listOf(facts(resource(PAGE))))

        graph.resources shouldBe mapOf(PAGE to "hydrated value")
    }

    listOf(
        GraphRejection(
            "its root is missing from its shard",
            listOf(facts(resource(OTHER))),
            "Compiled Page root is absent from its shard.",
        ),
        GraphRejection(
            "a resource key appears in two shards",
            listOf(facts(resource(PAGE)), facts(resource(PAGE))),
            "Compiled resource $PAGE appears in more than one shard.",
        ),
        GraphRejection(
            "an edge names a relation the runtime catalog does not declare",
            listOf(facts(resource(PAGE), edges = listOf(edge(RelationId(value = "test.unknown"))))),
            "Compiled edge uses unknown relation test.unknown.",
        ),
        GraphRejection(
            "a resource type is unknown to the runtime catalog",
            listOf(facts(resource(PAGE, type = UNKNOWN_TYPE))),
            "Compiled resource $PAGE has an unresolved actual type",
        ),
        GraphRejection(
            "a resource is unfinished",
            listOf(facts(resource(PAGE, payload = DataValue.UNFILLED))),
            "Compiled resource $PAGE is unfinished",
        ),
        GraphRejection(
            "a resource value does not fit its type",
            listOf(facts(resource(PAGE, payload = DataValue.BooleanWrapper(true)))),
            "Compiled resource $PAGE is invalid",
        ),
        GraphRejection(
            "a resource was compiled by another binding provider",
            listOf(facts(resource(PAGE, provider = NativeBindingId(value = "replaced")))),
            "Compiled resource $PAGE uses a different native binding implementation.",
        ),
        GraphRejection(
            "a resource was compiled by another binding signature",
            listOf(facts(resource(PAGE, signature = "test:v2"))),
            "Compiled resource $PAGE uses a different native binding implementation.",
        ),
    ).forEach { (name, facts, reason) ->
        test("a publication is refused when $name") {
            shouldThrow<RuntimeException> { assemble(facts) }.message.orEmpty() shouldStartWith reason
        }
    }
}

private data class GraphRejection(
    val name: String,
    val facts: List<RuntimeCompilationFacts>,
    val reason: String,
)

private val TEXT_TYPE = TypeDefinitionId.qualified("test", "text")
private val UNKNOWN_TYPE = TypeDefinitionId.qualified("test", "unknown")
private val PROVIDER = NativeBindingId(value = "test")
private const val SIGNATURE = "test:v1"
private val PAGE = key("page")
private val OTHER = key("other")
private val catalog =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "compiled resource graph test"),
        listOf(TypeDefinition.partial(id = TEXT_TYPE, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT))),
    )

private fun assemble(facts: List<RuntimeCompilationFacts>) =
    CompiledResourceGraph.assemble(facts, emptyList(), catalog, FactoryNativeBindingRegistry(catalog, listOf(TextBindingFactory)))

private fun key(resource: String) = CompiledResourceKey(source = ResourceId(resource).toSkir(), context = CompilationContext.Root)

private fun facts(
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

private fun resource(
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

private fun edge(relation: RelationId) =
    CompiledEdge(
        source = PAGE,
        target = OTHER,
        origin = CompiledEdgeOrigin.createRelation(relation = relation, firstLocation = null, secondLocation = null),
    )

/** Binds the text type the way a generated provider binds its declared type. */
private object TextBindingFactory : NativeBindingFactory {
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
