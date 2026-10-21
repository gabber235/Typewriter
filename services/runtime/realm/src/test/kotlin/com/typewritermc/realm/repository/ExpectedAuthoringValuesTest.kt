package com.typewritermc.realm.repository

import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.field
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.realm.checking.record
import com.typewritermc.types.ResourceId
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
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val ExpectedAuthoringValuesTestSuite by testSuite {
    val resource = ResourceId("quest")
    val at = ValueLocation.of(resource, ValuePath.root.field("name"))
    val original = record(name = "Quest")
    val expected =
        listOf(
            EditExpectation.ResourceExists(resource, true),
            EditExpectation.Configuration(ValueLocation.of(resource), original.configuration),
            EditExpectation.Value(at, DataValue.StringValueWrapper("Quest")),
        )

    test("returning to the expected value accepts the original expectations") {
        CapturedAuthoringValues(mapOf(resource to record(name = "Story")), emptyList()).conflicts(expected) shouldHaveSize 1
        CapturedAuthoringValues(mapOf(resource to original), emptyList()).conflicts(expected).shouldBeEmpty()
    }

    test("unrelated fields do not conflict with a focused field expectation") {
        val changed = original.with("description", DataValue.StringValueWrapper("Changed"))
        CapturedAuthoringValues(mapOf(resource to changed), emptyList()).conflicts(expected).shouldBeEmpty()
        CapturedAuthoringValues(mapOf(resource to changed), emptyList())
            .conflicts(listOf(EditExpectation.Resource(resource, original))) shouldHaveSize 1
    }

    test("missing values are distinct from authored null values") {
        val empty = CapturedAuthoringValues(emptyMap(), emptyList())
        empty.actual(EditExpectation.Value(at, DataValue.NULL)) shouldBe EditExpectation.Value(at, null)
        empty.conflicts(listOf(EditExpectation.Value(at, DataValue.NULL))) shouldHaveSize 1
        empty.conflicts(listOf(EditExpectation.Value(at, null))).shouldBeEmpty()
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
                EditExpectation.Configuration(chapterAt, TypeSelection.CompleteWrapper(chapterType)),
                EditExpectation.Value(titleAt, DataValue.StringValueWrapper("Quest")),
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
        values.conflicts(listOf(EditExpectation.ResourceIds(emptySet()))) shouldHaveSize 1
    }

    test("relation expectations compare semantic sets in the selected direction") {
        val relation = RelationId(value = "ownership")
        val child = ResourceId("child")
        val edge = LinkProjection(relation, resource, child, null, null)
        val values = CapturedAuthoringValues(mapOf(resource to original), listOf(edge, edge))
        values.links(resource, relation, TraversalDirection.Forward) shouldBe setOf(edge)
        values.links(resource, relation, TraversalDirection.Reverse).shouldBeEmpty()
        values.conflicts(listOf(EditExpectation.Links(resource, relation, TraversalDirection.Forward, setOf(edge)))).shouldBeEmpty()
    }
}
