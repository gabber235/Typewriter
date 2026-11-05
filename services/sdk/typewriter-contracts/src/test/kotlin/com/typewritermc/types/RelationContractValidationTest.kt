package com.typewritermc.types

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.EndpointSlot
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId

val RelationContractValidationTest by testSuite {
    val first =
        EndpointDefinition(
            id = EndpointId(value = "book:tags"),
            slot = EndpointSlot.FIRST,
            resource = TypeDefinitionId.qualified("test", "Book").namedTemplate(),
            cardinality = EndpointCardinality.MANY,
            onDelete = RelationDeletePolicy.CLEAR,
        )
    val second = first.copy(id = EndpointId(value = "tag:books"), slot = EndpointSlot.SECOND)
    val valid = RelationContract(id = RelationId(value = "book.tags"), first = first, second = second, families = emptyList())

    test("a relation contract with ordered unique families and both slots in place is valid") {
        val families = listOf(RelationFamilyId(value = "a.family"), RelationFamilyId(value = "b.family"))

        valid.copy(families = families).requireValid() shouldBe valid.copy(families = families)
    }

    test("building a relation contract puts its families in id order") {
        RelationContract.of(valid.id, first, second, setOf(RelationFamilyId(value = "b"), RelationFamilyId(value = "a"))).families shouldBe
            listOf(RelationFamilyId(value = "a"), RelationFamilyId(value = "b"))
    }

    mapOf(
        "unsorted families" to
            (
                valid.copy(families = listOf(RelationFamilyId(value = "b"), RelationFamilyId(value = "a"))) to
                    "Relation families must be unique and in id order."
            ),
        "duplicate families" to
            (
                valid.copy(families = listOf(RelationFamilyId(value = "a"), RelationFamilyId(value = "a"))) to
                    "Relation families must be unique and in id order."
            ),
        "a first endpoint in the second slot" to
            (valid.copy(first = first.copy(slot = EndpointSlot.SECOND)) to "First endpoint must use the first slot."),
        "a second endpoint in the first slot" to
            (valid.copy(second = second.copy(slot = EndpointSlot.FIRST)) to "Second endpoint must use the second slot."),
        "an unknown cardinality" to
            (valid.copy(second = second.copy(cardinality = EndpointCardinality.UNKNOWN)) to "Unknown endpoint cardinality."),
        "an unknown delete policy" to
            (valid.copy(first = first.copy(onDelete = RelationDeletePolicy.UNKNOWN)) to "Unknown relation delete policy."),
        "a blank relation id" to (valid.copy(id = RelationId(value = " ")) to "Relation ids must not be blank."),
        "a blank endpoint id" to (valid.copy(first = first.copy(id = EndpointId(value = ""))) to "Endpoint ids must not be blank."),
    ).forEach { (case, rejection) ->
        test("an external relation contract with $case is refused") {
            shouldThrow<IllegalArgumentException> { rejection.first.requireValid() }.message shouldBe rejection.second
        }
    }
}
