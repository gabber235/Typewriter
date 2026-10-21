package com.typewritermc.types

import build.skir.JsonFlavor
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.TypeSelection
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonObject
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.EnumVariant
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

val TypeValidationTest by testSuite {
    test("declared ids parse into one canonical form and reject any other text") {
        DeclaredTypeId.parse("0199A8AA-46F5-7C17-B956-BAA44C629A25") shouldBe DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25")
        DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25").requireValid()
        shouldThrow<IllegalArgumentException> { DeclaredTypeId(value = "0199A8AA46F57C17B956BAA44C629A25").requireValid() }
        shouldThrow<IllegalArgumentException> { DeclaredTypeId(value = "0199a8aa-46f5-7c17-b956-baa44c629a25").requireValid() }
    }

    test("identities require qualified names, positive revisions and non negative parameter indexes") {
        shouldThrow<IllegalArgumentException> { TypeId.createQualified(namespace = " ", name = "type").requireValid() }
        shouldThrow<IllegalArgumentException> { TypeId.createQualified(namespace = "test", name = "").requireValid() }
        shouldThrow<IllegalArgumentException> { TypeId.UNKNOWN.requireValid() }
        shouldThrow<IllegalArgumentException> { TypeDefinitionId.qualified("test", "type", revision = 0).requireValid() }
        shouldThrow<IllegalArgumentException> { ParameterKey(owner = OWNER, index = -1).requireValid() }
        ParameterKey(owner = OWNER, index = 0).requireValid()
    }

    test("declarations require named parameters, fields, enum keys, endpoints and local identities") {
        shouldThrow<IllegalArgumentException> {
            TypeParameter(key = ParameterKey(owner = OWNER, index = 0), name = "", bounds = emptyList()).requireValid()
        }
        shouldThrow<IllegalArgumentException> { FieldOwner(definition = OWNER, name = " ").requireValid() }
        shouldThrow<IllegalArgumentException> { EnumVariant(key = "").requireValid() }
        shouldThrow<IllegalArgumentException> { EndpointId(value = "").requireValid() }
        shouldThrow<IllegalArgumentException> {
            DeclarationOwner(source = contributionKey(), localIdentity = "").requireValid()
        }
        shouldThrow<IllegalArgumentException> {
            TypeDefinition(
                id = OWNER,
                parameters = emptyList(),
                representation = RepresentationTemplate.createEnumeration(cases = listOf(EnumVariant(key = " "))),
                parents = emptyList(),
            ).requireValid()
        }
    }

    test("unknown variants are rejected wherever they nest") {
        shouldThrow<IllegalArgumentException> { TypeUse.UNKNOWN.requireValid() }
        shouldThrow<IllegalArgumentException> { TypeTemplate.UNKNOWN.requireValid() }
        shouldThrow<IllegalArgumentException> { OWNER.use(listOf(TypeUse.UNKNOWN)).requireValid() }
        shouldThrow<IllegalArgumentException> { integerScalar(IntegerWidth.UNKNOWN).use.requireValid() }
        shouldThrow<IllegalArgumentException> { RepresentationTemplate.UNKNOWN.requireValid() }
        ScalarKind.TEXT.use
            .nullable()
            .requireValid()
    }

    test("stored type values embed their readable Skir JSON and are checked when read back") {
        val use = OWNER.namedUse(listOf(ScalarKind.TEXT.use))
        val record = AuthoringRecord(TypeSelection.Complete(use), emptyMap())
        val encoded = Json.encodeToJsonElement(AuthoringRecord.serializer(), record)
        encoded.jsonObject
            .getValue("configuration")
            .jsonObject
            .getValue("use") shouldBe
            NamedTypeUse.serializer.toJson(use, JsonFlavor.READABLE)
        Json.decodeFromJsonElement(AuthoringRecord.serializer(), encoded) shouldBe record

        val blankRevision =
            JsonObject(
                encoded.jsonObject +
                    (
                        "configuration" to
                            Json.encodeToJsonElement(
                                TypeSelection.serializer(),
                                TypeSelection.Pending(TypeDefinitionId.qualified("test", "type", revision = 0), emptyList()),
                            )
                    ),
            )
        shouldThrow<SerializationException> { Json.decodeFromJsonElement(AuthoringRecord.serializer(), blankRevision) }
    }
}

private val OWNER = TypeDefinitionId.qualified("test", "owner")

private fun contributionKey() =
    com.typewritermc.discovery.contributionKey(
        source = com.typewritermc.imprint.ContributionSourceId("test"),
        sourcePart = "main",
        producer = com.typewritermc.imprint.ProducerId("test"),
        name = com.typewritermc.imprint.ContributionName("owner"),
    )
