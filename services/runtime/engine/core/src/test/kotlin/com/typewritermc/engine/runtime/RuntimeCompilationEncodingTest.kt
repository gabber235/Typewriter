package com.typewritermc.engine.runtime

import com.typewritermc.engine.Root
import com.typewritermc.engine.canonicalized
import com.typewritermc.engine.decodeResourceGraphShard
import com.typewritermc.engine.encodeShard
import com.typewritermc.engine.semanticDigest
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.compiled_content.RuntimeRelationFact
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId

val RuntimeCompilationEncodingTest by testSuite {
    test("conflicting declarations with one identity are rejected before canonical encoding") {
        val id = TypeDefinitionId.qualified("test", "runtime")
        val facts =
            RuntimeCompilationFacts(
                formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
                root = CompiledResourceKey(source = ResourceId("page").toSkir(), context = CompilationContext.Root),
                resources = emptyList(),
                edges = emptyList(),
                types =
                    listOf(
                        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT)),
                        TypeDefinition.partial(id = id, representation = RepresentationTemplate.createScalar(kind = ScalarKind.BOOLEAN)),
                    ),
                relations = emptyList(),
            )

        shouldThrow<IllegalArgumentException> { facts.canonicalized() }.message shouldBe
            "Runtime facts contain duplicate type declarations."
    }

    test("admission accepts facts that declare exactly the types their resources reach") {
        admissionFacts().requireAccepted(admissionCatalog(), emptyList())
    }

    listOf(
        AdmissionRejection(
            "a type reached only through a nested value is missing",
            admissionFacts(types = listOf(resourceDefinition)),
            "Compiled runtime type facts do not equal the accepted declaration closure.",
        ),
        AdmissionRejection(
            "a type is declared twice",
            admissionFacts(types = listOf(resourceDefinition, payloadDefinition, payloadDefinition)),
            "Compiled runtime facts contain duplicate type declarations.",
        ),
        AdmissionRejection(
            "a type no resource reaches is declared",
            admissionFacts(types = listOf(resourceDefinition, payloadDefinition, unrelatedDefinition)),
            "Compiled runtime type facts do not equal the accepted declaration closure.",
        ),
        AdmissionRejection(
            "a declared type means something else than in the runtime catalog",
            admissionFacts(types = listOf(resourceDefinition, TypeDefinition.partial(id = payloadDefinition.id, representation = BOOLEAN))),
            "Compiled runtime type facts do not equal the accepted declaration closure.",
        ),
        AdmissionRejection(
            "a relation no edge uses is declared",
            admissionFacts(relations = listOf(RuntimeRelationFact(relation = RelationId(value = "test.unused"), ownsResources = false))),
            "Compiled relation facts do not cover the incident runtime relations.",
        ),
    ).forEach { (name, facts, reason) ->
        test("admission rejects facts when $name") {
            shouldThrow<IllegalArgumentException> { facts.requireAccepted(admissionCatalog(), emptyList()) }.message shouldBe reason
        }
    }

    test("a shard decodes to its canonical facts and rejects invalid ones") {
        val definition =
            TypeDefinition.partial(
                id = TypeDefinitionId.qualified("test", "resource"),
                representation = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT),
            )
        val key = CompiledResourceKey(source = ResourceId("page").toSkir(), context = CompilationContext.Root)
        val facts =
            RuntimeCompilationFacts(
                formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
                root = key,
                resources =
                    listOf(
                        CompiledResource(
                            key = key,
                            actualType = definition.id.namedUse(),
                            bindingProvider = NativeBindingId(value = "test"),
                            bindingSignature = "test:v1",
                            value = NamedValue(actualType = definition.id.namedUse(), payload = DataValue.StringValueWrapper("value")),
                        ),
                    ),
                edges = emptyList(),
                types = listOf(definition),
                relations = emptyList(),
            )
        val shard = facts.encodeShard()

        shard.decodeResourceGraphShard().facts shouldBe facts.canonicalized()
        shard.decodeResourceGraphShard().semanticDigest shouldBe facts.semanticDigest()
        shouldThrow<IllegalArgumentException> {
            shard
                .decodeToString()
                .replace("\"page\"", "\"\"")
                .encodeToByteArray()
                .decodeResourceGraphShard()
        }.message shouldBe "Resource ids must not be blank."
    }
}

private data class AdmissionRejection(
    val name: String,
    val facts: RuntimeCompilationFacts,
    val reason: String,
)

private val TEXT = RepresentationTemplate.createScalar(kind = ScalarKind.TEXT)
private val BOOLEAN = RepresentationTemplate.createScalar(kind = ScalarKind.BOOLEAN)
private val resourceDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "resource"), representation = TEXT)
private val payloadDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "payload"), representation = TEXT)
private val unrelatedDefinition = TypeDefinition.partial(id = TypeDefinitionId.qualified("test", "unrelated"), representation = TEXT)

private fun admissionCatalog() =
    DefaultCheckedCatalog(
        CatalogGeneration(value = "runtime encoding test"),
        listOf(resourceDefinition, payloadDefinition, unrelatedDefinition),
    )

/** A page resource of the resource type whose value nests a value of the payload type. */
private fun admissionFacts(
    types: List<TypeDefinition> = listOf(resourceDefinition, payloadDefinition),
    relations: List<RuntimeRelationFact> = emptyList(),
): RuntimeCompilationFacts {
    val key = CompiledResourceKey(source = ResourceId("page").toSkir(), context = CompilationContext.Root)
    return RuntimeCompilationFacts(
        formatRevision = com.typewritermc.engine.RESOURCE_GRAPH_FORMAT_REVISION,
        root = key,
        resources =
            listOf(
                CompiledResource(
                    key = key,
                    actualType = resourceDefinition.id.namedUse(),
                    bindingProvider = NativeBindingId(value = "test"),
                    bindingSignature = "test:v1",
                    value =
                        (
                            DataValue.named(
                                payloadDefinition.id.namedUse(),
                                DataValue.StringValueWrapper("value"),
                            ) as DataValue.NamedWrapper
                        ).value,
                ),
            ),
        edges = emptyList(),
        types = types,
        relations = relations,
    )
}
