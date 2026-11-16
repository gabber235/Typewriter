package com.typewritermc.engine.runtime

import com.typewritermc.engine.Root
import com.typewritermc.engine.canonicalized
import com.typewritermc.engine.decodeResourceGraphShard
import com.typewritermc.engine.encodeShard
import com.typewritermc.engine.runtime.testing.AdmissionRejection
import com.typewritermc.engine.runtime.testing.admissionCatalog
import com.typewritermc.engine.runtime.testing.admissionFacts
import com.typewritermc.engine.runtime.testing.admissionPage
import com.typewritermc.engine.runtime.testing.contentRecord
import com.typewritermc.engine.runtime.testing.gateway
import com.typewritermc.engine.runtime.testing.payloadDefinition
import com.typewritermc.engine.runtime.testing.publicationOf
import com.typewritermc.engine.runtime.testing.resourceDefinition
import com.typewritermc.engine.runtime.testing.unrelatedDefinition
import com.typewritermc.engine.semanticDigest
import com.typewritermc.types.ResourceId
import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.contentField
import com.typewritermc.types.catalog.derived
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.compiled_content.CompilationContext
import skirout.editor.v1.compiled_content.CompiledResource
import skirout.editor.v1.compiled_content.CompiledResourceKey
import skirout.editor.v1.compiled_content.RuntimeCompilationFacts
import skirout.editor.v1.compiled_content.RuntimeRelationFact
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.NamedValue
import skirout.editor.v1.type_catalog.NativeBindingId
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter

val RuntimeCompilationEncodingTest by testSuite {
    val boolean = RepresentationTemplate.createScalar(kind = ScalarKind.BOOLEAN)

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
            admissionFacts(types = listOf(resourceDefinition, TypeDefinition.partial(id = payloadDefinition.id, representation = boolean))),
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

    test("an artifact with an invalid content declaration is refused") {
        val generic =
            TypeDefinition.partial(
                id = TypeDefinitionId.content(admissionPage, "k1"),
                parameters =
                    listOf(
                        TypeParameter(
                            key = ParameterKey(owner = TypeDefinitionId.content(admissionPage, "k1"), index = 0),
                            name = "T",
                            bounds = emptyList(),
                            derived = false,
                        ),
                    ),
                representation = RepresentationTemplate.createRecord(fields = emptyList(), form = RecordForm.CONCRETE),
            )
        shouldThrow<IllegalArgumentException> {
            gateway().apply(publicationOf(admissionFacts(types = listOf(resourceDefinition, generic), payload = generic.id)))
        }.message shouldBe "Compiled content declarations are invalid."
    }

    test("an artifact that names a field key is refused") {
        val reward =
            contentRecord(
                TypeDefinitionId.content(admissionPage, "k1"),
                "gold" to TypeDefinitionId.contentField(admissionPage, "value").use(),
            )
        shouldThrow<IllegalArgumentException> {
            gateway().apply(publicationOf(admissionFacts(types = listOf(resourceDefinition, reward), payload = reward.id)))
        }.message shouldBe "Compiled content names a field key; the compiler expands them."
    }

    test("an artifact's derived declaration is admitted like a creator declaration, so only a later mismatch refuses it") {
        val rows = contentRecord(TypeDefinitionId.derived(admissionPage, "V"), "gold" to payloadDefinition.id.use())
        val changed = TypeDefinition.partial(id = resourceDefinition.id, representation = boolean)
        shouldThrow<IllegalArgumentException> {
            gateway().apply(publicationOf(admissionFacts(types = listOf(changed, rows, payloadDefinition), payload = rows.id)))
        }.message shouldBe "Compiled runtime type facts do not equal the accepted declaration closure."
    }

    test("an artifact whose code type differs from the engine catalog is still refused") {
        val reward = contentRecord(TypeDefinitionId.content(admissionPage, "k1"), "gold" to payloadDefinition.id.use())
        val changed = TypeDefinition.partial(id = resourceDefinition.id, representation = boolean)
        shouldThrow<IllegalArgumentException> {
            gateway().apply(publicationOf(admissionFacts(types = listOf(changed, reward, payloadDefinition), payload = reward.id)))
        }.message shouldBe "Compiled runtime type facts do not equal the accepted declaration closure."
    }
}
