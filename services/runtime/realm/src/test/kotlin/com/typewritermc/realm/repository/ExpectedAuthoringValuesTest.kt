package com.typewritermc.realm.repository

import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.LinkProjection
import com.typewritermc.authoring.PathSegment
import com.typewritermc.authoring.TraversalDirection
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.realm.checking.record
import com.typewritermc.types.DataValue
import com.typewritermc.types.RelationId
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe

val ExpectedAuthoringValuesTestSuite by testSuite {
    val resource = ResourceId("quest")
    val at = ValueLocation(resource, ValuePath(listOf(PathSegment.Field("name"))))
    val original = record(name = "Quest")
    val expected =
        listOf(
            EditExpectation.ResourceExists(resource, true),
            EditExpectation.Configuration(ValueLocation(resource, ValuePath()), original.configuration),
            EditExpectation.Value(at, DataValue.StringValue("Quest")),
        )

    test("returning to the expected value accepts the original expectations") {
        CapturedAuthoringValues(mapOf(resource to record(name = "Story")), emptyList()).conflicts(expected) shouldHaveSize 1
        CapturedAuthoringValues(mapOf(resource to original), emptyList()).conflicts(expected).shouldBeEmpty()
    }

    test("unrelated fields do not conflict with a focused field expectation") {
        val changed = original.copy(fields = original.fields + ("description" to DataValue.StringValue("Changed")))
        CapturedAuthoringValues(mapOf(resource to changed), emptyList()).conflicts(expected).shouldBeEmpty()
        CapturedAuthoringValues(mapOf(resource to changed), emptyList())
            .conflicts(listOf(EditExpectation.Resource(resource, original))) shouldHaveSize 1
    }

    test("missing values are distinct from authored null values") {
        val empty = CapturedAuthoringValues(emptyMap(), emptyList())
        empty.actual(EditExpectation.Value(at, DataValue.Null)) shouldBe EditExpectation.Value(at, null)
        empty.conflicts(listOf(EditExpectation.Value(at, DataValue.Null))) shouldHaveSize 1
        empty.conflicts(listOf(EditExpectation.Value(at, null))).shouldBeEmpty()
        empty.conflicts(expected) shouldHaveSize 3
    }

    test("nested configuration guards the named type independently of its fields") {
        val chapterType =
            TypeUse.Named(
                TypeDefinitionId(
                    com.typewritermc.types.TypeId
                        .Qualified("test", "chapter"),
                    1,
                ),
            )
        val chapter =
            DataValue.Named(
                chapterType,
                DataValue.Record(
                    mapOf(
                        "title" to DataValue.StringValue("Quest"),
                        "description" to DataValue.StringValue("Original"),
                    ),
                ),
            )
        val chapterAt = ValueLocation(resource, ValuePath(listOf(PathSegment.Field("chapter"))))
        val titleAt = chapterAt.copy(path = ValuePath(chapterAt.path.segments + PathSegment.Field("title")))
        val expected =
            listOf(
                EditExpectation.Configuration(chapterAt, TypeSelection.Complete(chapterType)),
                EditExpectation.Value(titleAt, DataValue.StringValue("Quest")),
            )
        val changed =
            chapter.copy(
                payload =
                    DataValue.Record(
                        mapOf(
                            "title" to DataValue.StringValue("Quest"),
                            "description" to DataValue.StringValue("Changed"),
                        ),
                    ),
            )
        val values = CapturedAuthoringValues(mapOf(resource to original.copy(fields = mapOf("chapter" to changed))), emptyList())
        values.conflicts(expected).shouldBeEmpty()
        val retagged =
            changed.copy(
                actualType =
                    TypeUse.Named(
                        TypeDefinitionId(
                            com.typewritermc.types.TypeId
                                .Qualified("test", "other_chapter"),
                            1,
                        ),
                    ),
            )
        CapturedAuthoringValues(mapOf(resource to original.copy(fields = mapOf("chapter" to retagged))), emptyList())
            .conflicts(expected) shouldHaveSize 1
    }

    test("resource directory expectations notice new candidates") {
        val values = CapturedAuthoringValues(mapOf(resource to original), emptyList())
        values.conflicts(listOf(EditExpectation.ResourceIds(emptySet()))) shouldHaveSize 1
    }

    test("relation expectations compare semantic sets in the selected direction") {
        val relation = RelationId("ownership")
        val child = ResourceId("child")
        val edge = LinkProjection(relation, resource, child, null, null)
        val values = CapturedAuthoringValues(mapOf(resource to original), listOf(edge, edge))
        values.links(resource, relation, TraversalDirection.Forward) shouldBe setOf(edge)
        values.links(resource, relation, TraversalDirection.Reverse).shouldBeEmpty()
        values.conflicts(listOf(EditExpectation.Links(resource, relation, TraversalDirection.Forward, setOf(edge)))).shouldBeEmpty()
    }
}
