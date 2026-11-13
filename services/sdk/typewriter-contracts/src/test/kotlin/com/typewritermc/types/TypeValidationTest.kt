package com.typewritermc.types

import build.skir.JsonFlavor
import com.typewritermc.authoring.of
import com.typewritermc.testkit.Rejection
import com.typewritermc.testkit.rejectionOf
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.ChosenArgument
import skirout.editor.v1.type_catalog.DeclarationOwner
import skirout.editor.v1.type_catalog.DeclaredTypeId
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeTemplate
import skirout.editor.v1.type_catalog.TypeUse

val TypeValidationTest by testSuite {
    val ownerType = TypeDefinitionId.qualified("test", "owner")

    val ownerContribution =
        com.typewritermc.discovery.contributionKey(
            source = com.typewritermc.imprint.ContributionSourceId("test"),
            sourcePart = "main",
            producer = com.typewritermc.imprint.ProducerId("test"),
            name = com.typewritermc.imprint.ContributionName("owner"),
        )

    val invalidDeclarations: Map<String, Rejection> =
        mapOf(
            "a blank type namespace" to
                Rejection("Type namespace must not be blank.") { TypeId.createQualified(namespace = " ", name = "type").requireValid() },
            "a blank type name" to
                Rejection("Type name must not be blank.") { TypeId.createQualified(namespace = "test", name = "").requireValid() },
            "an unknown type identity" to Rejection("Unknown type identity variant.") { TypeId.UNKNOWN.requireValid() },
            "a zero revision" to
                Rejection("Type revision must be positive.") { TypeDefinitionId.qualified("test", "type", revision = 0).requireValid() },
            "a negative parameter index" to
                Rejection("Parameter index must not be negative.") { ParameterKey(owner = ownerType, index = -1).requireValid() },
            "a blank parameter name" to
                Rejection("Type parameter name must not be blank.") {
                    TypeParameter(key = ParameterKey(owner = ownerType, index = 0), name = "", bounds = emptyList()).requireValid()
                },
            "a blank field name" to
                Rejection(
                    "Field name must not be blank.",
                ) { FieldOwner(definition = ownerType, name = " ").requireValid() },
            "a blank member name" to Rejection("Member name must not be blank.") { ownerType.member(" ").requireValid() },
            "a blank endpoint" to Rejection("Endpoint ids must not be blank.") { EndpointId(value = "").requireValid() },
            "a blank local identity" to
                Rejection("Local declaration identity must not be blank.") {
                    DeclarationOwner(source = ownerContribution, localIdentity = "").requireValid()
                },
            "a closed record with a blank case" to
                Rejection("Member name must not be blank.") {
                    closedRecord(ownerType, listOf(ownerType.member(" "))).requireValid()
                },
            "an unknown type use" to Rejection("Unknown type use variant.") { TypeUse.UNKNOWN.requireValid() },
            "an unknown type template" to Rejection("Unknown type template variant.") { TypeTemplate.UNKNOWN.requireValid() },
            "an unknown type use nested as an argument" to
                Rejection("Unknown type use variant.") { ownerType.use(listOf(TypeUse.UNKNOWN)).requireValid() },
            "an unknown integer width" to Rejection("Unknown integer width.") { integerScalar(IntegerWidth.UNKNOWN).use.requireValid() },
            "an unknown representation" to Rejection("Unknown representation template.") { RepresentationTemplate.UNKNOWN.requireValid() },
            "a type selection that chooses one parameter twice" to
                Rejection("Type argument parameter 0 is chosen twice.") {
                    TypeSelection(
                        definition = ownerType,
                        arguments = listOf(ChosenArgument(parameter = 0, type = ScalarKind.TEXT.use), ChosenArgument(parameter = 0, type = ScalarKind.TEXT.use)),
                    ).requireValid()
                },
            "a type selection that chooses a negative parameter" to
                Rejection("Type argument parameter -1 is negative.") {
                    TypeSelection(definition = ownerType, arguments = listOf(ChosenArgument(parameter = -1, type = ScalarKind.TEXT.use))).requireValid()
                },
        )

    test("declared ids parse into one canonical form and reject any other text") {
        DeclaredTypeId.parse("0199A8AA-46F5-7C17-B956-BAA44C629A25") shouldBe DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25")
        DeclaredTypeId.parse("0199a8aa46f57c17b956baa44c629a25").requireValid()
        for (text in listOf("0199A8AA46F57C17B956BAA44C629A25", "0199a8aa-46f5-7c17-b956-baa44c629a25")) {
            rejectionOf { DeclaredTypeId(value = text).requireValid() } shouldBe
                "Declared type id must be a 32 character lowercase hexadecimal UUID."
        }
    }

    for ((name, rejected) in invalidDeclarations) {
        test("$name is rejected with its reason") {
            rejectionOf(rejected.check) shouldBe rejected.reason
        }
    }

    test("a parameter at index zero and a nullable text use are valid") {
        ParameterKey(owner = ownerType, index = 0).requireValid()
        ScalarKind.TEXT.use
            .nullable()
            .requireValid()
    }

    test("an authored record read back from readable Skir JSON keeps its configuration") {
        val record = AuthoringRecord.of(TypeSelection.of(ownerType.namedUse(listOf(ScalarKind.TEXT.use))))
        val encoded = AuthoringRecord.serializer.toJson(record, JsonFlavor.READABLE)

        AuthoringRecord.serializer
            .fromJson(encoded)
            .requireValid() shouldBe record
    }

    test("an authored record read from JSON with a zero revision is rejected") {
        val invalid =
            AuthoringRecord.of(
                TypeSelection.of(TypeDefinitionId.qualified("test", "type", revision = 0)),
            )
        val decoded = AuthoringRecord.serializer.fromJson(AuthoringRecord.serializer.toJson(invalid, JsonFlavor.READABLE))

        rejectionOf { decoded.requireValid() } shouldBe "Type revision must be positive."
    }
}
