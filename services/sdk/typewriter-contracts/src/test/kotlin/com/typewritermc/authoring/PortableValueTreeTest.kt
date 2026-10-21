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
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValuePath

val PortableValueTreeTest by testSuite {
    test("map rows remain distinct locations and expose structural observations") {
        val row = ItemId(value = "row")
        val path =
            ValuePath(
                segments =
                    listOf(
                        PathSegment.createField(name = "mapping"),
                        PathSegment.createItem(id = row),
                        PathSegment.MAP_VALUE,
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
                StructuralStep.Form(ValuePath.root),
                StructuralStep.Form(ValuePath.root.field("mapping")),
                StructuralStep.Membership(ValuePath.root.field("mapping")),
                StructuralStep.Form(
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "mapping"),
                                PathSegment.createItem(id = row),
                            ),
                    ),
                ),
            )
    }

    test("field writing distinguishes terminal insertion from a missing parent") {
        val root = DataValue.record(emptyMap())
        val terminal = ValuePath.root.field("created")
        val nested = ValuePath(segments = listOf(PathSegment.createField(name = "missing"), PathSegment.createField(name = "child")))

        root.replace(terminal, DataValue.StringValueWrapper("value")) shouldBe ValueReplacement.Unavailable(terminal)
        root.writeField(terminal, DataValue.StringValueWrapper("value")) shouldBe
            ValueReplacement.Replaced(
                DataValue.record(mapOf("created" to DataValue.StringValueWrapper("value"))),
            )
        root.writeField(nested, DataValue.StringValueWrapper("value")) shouldBe ValueReplacement.Unavailable(nested)
    }

    test("descendants preserve named wrappers and map branch paths") {
        val row = ItemId(value = "row")
        val field = ValuePath.root.field("wrapped")
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
                ValuePath.root,
                field,
                field,
                ValuePath(
                    segments = listOf(PathSegment.createField(name = "wrapped"), PathSegment.createItem(id = row), PathSegment.MAP_KEY),
                ),
                ValuePath(
                    segments = listOf(PathSegment.createField(name = "wrapped"), PathSegment.createItem(id = row), PathSegment.MAP_VALUE),
                ),
                ValuePath(
                    segments =
                        listOf(
                            PathSegment.createField(name = "wrapped"),
                            PathSegment.createItem(id = row),
                            PathSegment.MAP_VALUE,
                            PathSegment.createItem(id = ItemId(value = "value")),
                        ),
                ),
            )
    }
}
