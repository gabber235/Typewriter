package com.typewritermc.authoring

import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.record
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId

val PortableValueTreeTest by testSuite {
    test("map rows remain distinct locations and expose structural observations") {
        val row = ItemId(value = "row")
        val path =
            ValuePath(
                listOf(
                    PathSegment.Field("mapping"),
                    PathSegment.Item(row),
                    PathSegment.MapValue,
                ),
            )
        val value =
            DataValue.record(
                mapOf(
                    "mapping" to
                        DataValue.named(
                            TypeDefinitionId.qualified("test", "mapping").namedUse(),
                            DataValue.mapValue(
                                listOf(
                                    MapRow(
                                        id = row,
                                        key = DataValue.StringValueWrapper("key"),
                                        value = DataValue.StringValueWrapper("value"),
                                    ),
                                ),
                            ),
                        ),
                ),
            )
        val steps = mutableListOf<StructuralStep>()

        value.locate(path, steps::add) shouldBe LocatedPortableValue.Value(DataValue.StringValueWrapper("value"))
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
        val root = DataValue.record(emptyMap())
        val terminal = ValuePath(listOf(PathSegment.Field("created")))
        val nested = ValuePath(listOf(PathSegment.Field("missing"), PathSegment.Field("child")))

        root.replace(terminal, DataValue.StringValueWrapper("value")) shouldBe ValueReplacement.Unavailable(terminal)
        root.writeField(terminal, DataValue.StringValueWrapper("value")) shouldBe
            ValueReplacement.Replaced(
                DataValue.record(mapOf("created" to DataValue.StringValueWrapper("value"))),
            )
        root.writeField(nested, DataValue.StringValueWrapper("value")) shouldBe ValueReplacement.Unavailable(nested)
    }

    test("descendants preserve named wrappers and map branch paths") {
        val row = ItemId(value = "row")
        val field = ValuePath(listOf(PathSegment.Field("wrapped")))
        val value =
            DataValue.record(
                mapOf(
                    "wrapped" to
                        DataValue.named(
                            TypeDefinitionId.qualified("test", "wrapped").namedUse(listOf(ScalarKind.TEXT.use)),
                            DataValue.mapValue(
                                listOf(
                                    MapRow(
                                        id = row,
                                        key = DataValue.StringValueWrapper("key"),
                                        value =
                                            DataValue.listValue(
                                                listOf(
                                                    ListItem(id = ItemId(value = "value"), value = DataValue.StringValueWrapper("nested")),
                                                ),
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
                        PathSegment.Item(ItemId(value = "value")),
                    ),
                ),
            )
    }
}
