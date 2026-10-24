package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.toSkir
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.PreparedEdit
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val EditExpectationCodecTest by testSuite {
    test("all six focused facts round trip through the shared editor contract") {
        val resource = ResourceId("quest").toSkir()
        val chapter = ResourceId("chapter").toSkir()
        val at = ValueLocation.of(resource, ValuePath.root.field("chapter"))
        val selection = TypeSelection.CompleteWrapper(TypeDefinitionId.qualified("test", "chapter").namedUse())
        val record = AuthoringRecord.of(selection, mapOf("title" to DataValue.StringValueWrapper("Quest")))
        val projection =
            LinkProjection(
                contract = RelationId(value = "chapters"),
                first = resource,
                second = chapter,
                firstLocation = at.path,
                secondLocation = null,
            )
        val expectations =
            listOf(
                EditExpectation.createValue(at = at, expected = null),
                EditExpectation.createValue(at = at, expected = DataValue.NULL),
                EditExpectation.createResource(id = resource, expected = record),
                EditExpectation.createResourceExists(id = resource, expected = true),
                EditExpectation.createConfiguration(at = at, expected = selection),
                EditExpectation.resourceIds(setOf(resource, chapter)),
                EditExpectation.links(resource, projection.contract, TraversalDirection.BOTH, setOf(projection)),
            )
        val prepared = PreparedEdit(catalog = CatalogGeneration(value = "catalog"), expectations = expectations, intents = emptyList())

        PreparedEdit.serializer.fromBytes(PreparedEdit.serializer.toBytes(prepared).toByteArray()).requireValid() shouldBe prepared
    }

    test("set facts are canonical: duplicates collapse and members follow one order") {
        val quest = ResourceId("quest").toSkir()
        val chapter = ResourceId("chapter").toSkir()

        EditExpectation.ResourceIdsWrapper(listOf(quest, chapter, quest)).requireValid() shouldBe
            EditExpectation.resourceIds(listOf(chapter, quest))
        shouldThrow<IllegalArgumentException> {
            EditExpectation.ResourceIdsWrapper(listOf(ResourceId("quest").toSkir().copy(value = ""))).requireValid()
        }
    }
}
