package com.typewritermc.authoring

import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ScalarKind
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val PortableValueTreeTest by testSuite {
    test("map rows remain distinct locations and expose structural observations") {
        val row = ItemId("row")
        val path =
            ValuePath(
                listOf(
                    PathSegment.Field("mapping"),
                    PathSegment.Item(row),
                    PathSegment.MapValue,
                ),
            )
        val value =
            DataValue.Record(
                mapOf(
                    "mapping" to
                        DataValue.Named(
                            TypeUse.Named(TypeDefinitionId(TypeId.Qualified("test", "mapping"), 1)),
                            DataValue.MapValue(
                                listOf(
                                    MapRow(
                                        row,
                                        DataValue.StringValue("key"),
                                        DataValue.StringValue("value"),
                                    ),
                                ),
                            ),
                        ),
                ),
            )
        val steps = mutableListOf<StructuralStep>()

        value.locate(path, steps::add) shouldBe LocatedPortableValue.Value(DataValue.StringValue("value"))
        steps shouldContainExactly
            listOf(
                StructuralStep.Form(ValuePath()),
                StructuralStep.Form(ValuePath(listOf(PathSegment.Field("mapping")))),
                StructuralStep.Membership(ValuePath(listOf(PathSegment.Field("mapping")))),
                StructuralStep.Form(
                    ValuePath(
                        listOf(
                            PathSegment.Field("mapping"),
                            PathSegment.Item(row),
                        ),
                    ),
                ),
            )
    }

    test("field writing distinguishes terminal insertion from a missing parent") {
        val root = DataValue.Record(emptyMap())
        val terminal = ValuePath(listOf(PathSegment.Field("created")))
        val nested = ValuePath(listOf(PathSegment.Field("missing"), PathSegment.Field("child")))

        root.replace(terminal, DataValue.StringValue("value")) shouldBe ValueReplacement.Unavailable(terminal)
        root.writeField(terminal, DataValue.StringValue("value")) shouldBe
            ValueReplacement.Replaced(
                DataValue.Record(mapOf("created" to DataValue.StringValue("value"))),
            )
        root.writeField(nested, DataValue.StringValue("value")) shouldBe ValueReplacement.Unavailable(nested)
    }

    test("descendants preserve named wrappers and map branch paths") {
        val row = ItemId("row")
        val field = ValuePath(listOf(PathSegment.Field("wrapped")))
        val value =
            DataValue.Record(
                mapOf(
                    "wrapped" to
                        DataValue.Named(
                            TypeUse.Named(
                                TypeDefinitionId(TypeId.Qualified("test", "wrapped"), 1),
                                listOf(TypeUse.Scalar(ScalarKind.Text)),
                            ),
                            DataValue.MapValue(
                                listOf(
                                    MapRow(
                                        row,
                                        DataValue.StringValue("key"),
                                        DataValue.ListValue(
                                            listOf(ListItem(ItemId("value"), DataValue.StringValue("nested"))),
                                        ),
                                    ),
                                ),
                            ),
                        ),
                ),
            )

        value.descendants().map(LocatedValueNode::path).toList() shouldContainExactly
            listOf(
                ValuePath(),
                field,
                field,
                ValuePath(listOf(PathSegment.Field("wrapped"), PathSegment.Item(row), PathSegment.MapKey)),
                ValuePath(listOf(PathSegment.Field("wrapped"), PathSegment.Item(row), PathSegment.MapValue)),
                ValuePath(
                    listOf(
                        PathSegment.Field("wrapped"),
                        PathSegment.Item(row),
                        PathSegment.MapValue,
                        PathSegment.Item(ItemId("value")),
                    ),
                ),
            )
    }
}
