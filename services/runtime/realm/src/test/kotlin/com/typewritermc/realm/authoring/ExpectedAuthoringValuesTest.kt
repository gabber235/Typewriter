package com.typewritermc.realm.repository

import com.typewritermc.authoring.field
import com.typewritermc.authoring.links
import com.typewritermc.authoring.of
import com.typewritermc.authoring.resourceIds
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.realm.checking.record
import com.typewritermc.types.actualType
import com.typewritermc.types.fields
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.authoring_facts.LinkProjection
import skirout.editor.v1.authoring_facts.TraversalDirection
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.ResourceId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val ExpectedAuthoringValuesTestSuite by testSuite {
    val resource = ResourceId(value = "quest")
    val at = ValueLocation.of(resource, ValuePath.root.field("name"))
    val original = record(name = "Quest")
    val expected =
        listOf(
            EditExpectation.createResourceExists(id = resource, expected = true),
            EditExpectation.createConfiguration(at = ValueLocation.of(resource), expected = original.configuration),
            EditExpectation.createValue(at = at, expected = DataValue.StringValueWrapper("Quest")),
        )

    test("returning to the expected value accepts the original expectations") {
        CapturedAuthoringValues(mapOf(resource to record(name = "Story")), emptyList()).conflicts(expected) shouldHaveSize 1
        CapturedAuthoringValues(mapOf(resource to original), emptyList()).conflicts(expected).shouldBeEmpty()
    }

    test("unrelated fields do not conflict with a focused field expectation") {
        val changed = original.with("description", DataValue.StringValueWrapper("Changed"))
        CapturedAuthoringValues(mapOf(resource to changed), emptyList()).conflicts(expected).shouldBeEmpty()
        CapturedAuthoringValues(mapOf(resource to changed), emptyList())
            .conflicts(listOf(EditExpectation.createResource(id = resource, expected = original))) shouldHaveSize 1
    }

    test("missing values are distinct from authored null values") {
        val empty = CapturedAuthoringValues(emptyMap(), emptyList())
        empty.actual(EditExpectation.createValue(at = at, expected = DataValue.NULL)) shouldBe
            EditExpectation.createValue(at = at, expected = null)
        empty.conflicts(listOf(EditExpectation.createValue(at = at, expected = DataValue.NULL))) shouldHaveSize 1
        empty.conflicts(listOf(EditExpectation.createValue(at = at, expected = null))).shouldBeEmpty()
        empty.conflicts(expected) shouldHaveSize 3
    }

    test("nested configuration guards the named type independently of its fields") {
        val chapterType =
            TypeDefinitionId.qualified("test", "chapter").namedUse()
        val chapter =
            DataValue.named(
                chapterType,
                DataValue.record(
                    mapOf(
                        "title" to DataValue.StringValueWrapper("Quest"),
                        "description" to DataValue.StringValueWrapper("Original"),
                    ),
                ),
            )
        val chapterAt = ValueLocation.of(resource, ValuePath.root.field("chapter"))
        val titleAt = chapterAt.copy(path = ValuePath(segments = chapterAt.path.segments + PathSegment.createField(name = "title")))
        val expected =
            listOf(
                EditExpectation.createConfiguration(at = chapterAt, expected = TypeSelection.CompleteWrapper(chapterType)),
                EditExpectation.createValue(at = titleAt, expected = DataValue.StringValueWrapper("Quest")),
            )
        val changed =
            DataValue.named(
                chapter.actualType,
                DataValue.record(
                    mapOf(
                        "title" to DataValue.StringValueWrapper("Quest"),
                        "description" to DataValue.StringValueWrapper("Changed"),
                    ),
                ),
            )
        val values =
            CapturedAuthoringValues(mapOf(resource to AuthoringRecord.of(original.configuration, mapOf("chapter" to changed))), emptyList())
        values.conflicts(expected).shouldBeEmpty()
        val retagged =
            DataValue.named(TypeDefinitionId.qualified("test", "other_chapter").namedUse(), changed.payload)
        CapturedAuthoringValues(mapOf(resource to AuthoringRecord.of(original.configuration, mapOf("chapter" to retagged))), emptyList())
            .conflicts(expected) shouldHaveSize 1
    }

    test("resource directory expectations notice new candidates") {
        val values = CapturedAuthoringValues(mapOf(resource to original), emptyList())
        values.conflicts(listOf(EditExpectation.resourceIds(emptySet()))) shouldHaveSize 1
    }

    test("relation expectations compare semantic sets in the selected direction") {
        val relation = RelationId(value = "ownership")
        val child = ResourceId(value = "child")
        val edge = LinkProjection(contract = relation, first = resource, second = child, firstLocation = null, secondLocation = null)
        val values = CapturedAuthoringValues(mapOf(resource to original), listOf(edge, edge))
        values.links(resource, relation, TraversalDirection.FORWARD) shouldBe setOf(edge)
        values.links(resource, relation, TraversalDirection.REVERSE).shouldBeEmpty()
        values.conflicts(listOf(EditExpectation.links(resource, relation, TraversalDirection.FORWARD, setOf(edge)))).shouldBeEmpty()
    }
}
