package com.typewritermc.realm.checking

import com.typewritermc.authoring.id
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.authoring.with
import com.typewritermc.checking.CheckInput
import com.typewritermc.realm.authoring.INT_USE
import com.typewritermc.realm.authoring.LIST_USE
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.ViewReadLimits
import com.typewritermc.realm.authoring.listItemAt
import com.typewritermc.realm.authoring.record
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.FieldPatternSegment
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.ParameterKey
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeParameter
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath

val RealmCheckInputsTest by testSuite {
    val mapType = TypeDefinitionId.qualified("typewriter", "map")

    val intKind = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)

    test("a check over map keys and values pairs them per row and reports only the mismatching row") {
        val mapParameterKey = ParameterKey(owner = mapType, index = 0)
        val mapParameterValue = ParameterKey(owner = mapType, index = 1)
        val mapUse = mapType.namedUse(listOf(INT_USE, INT_USE))
        val root =
            TypeDefinition.partial(
                id = TEST_TYPE,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = TEST_TYPE, name = "mapping"),
                                    type = mapType.template(listOf(intKind.template, intKind.template)),
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            )
        val map =
            TypeDefinition.partial(
                id = mapType,
                parameters =
                    listOf(
                        TypeParameter.partial(key = mapParameterKey, name = "K"),
                        TypeParameter.partial(key = mapParameterValue, name = "V"),
                    ),
                representation =
                    RepresentationTemplate.createMapping(
                        key = mapParameterKey.template,
                        value = mapParameterValue.template,
                    ),
            )
        val record =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                mapOf(
                    "mapping" to
                        DataValue.named(
                            mapUse,
                            DataValue.mapValue(
                                listOf(
                                    MapRow(id = ItemId(value = "a"), key = DataValue.integer(1L), value = DataValue.integer(1L)),
                                    MapRow(id = ItemId(value = "b"), key = DataValue.integer(2L), value = DataValue.integer(2L)),
                                    MapRow(id = ItemId(value = "c"), key = DataValue.integer(3L), value = DataValue.integer(4L)),
                                ),
                            ),
                        ),
                ),
            )
        val recipe =
            recipe(
                listOf(
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.KEYS), intKind.template),
                    CheckInput(TEST_TYPE, pattern("mapping", FieldPatternSegment.VALUES), intKind.template),
                ),
                predicate(listOf(intKind.template, intKind.template)) { values -> values[0].value == values[1].value },
            )

        val (result) = evaluate(recipe, record, definitions = listOf(root, map))

        result.outcome shouldBe CheckOutcome.FINISHED
        result.findings.map { it.primary } shouldBe
            listOf(
                ValueLocation.of(
                    RESOURCE,
                    ValuePath(
                        segments =
                            listOf(
                                PathSegment.createField(name = "mapping"),
                                PathSegment.createItem(id = ItemId(value = "c")),
                                PathSegment.MAP_KEY,
                            ),
                    ),
                ),
            )
    }

    test("findings of complete occurrences stay visible when another occurrence needs input") {
        val record =
            record(numbers = emptyList()).with(
                "numbers",
                DataValue.named(
                    LIST_USE,
                    DataValue.listValue(
                        listOf(
                            ListItem(id = ItemId(value = "missing"), value = DataValue.UNFILLED),
                            ListItem(id = ItemId(value = "known"), value = DataValue.integer(2L)),
                        ),
                    ),
                ),
            )
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.ITEMS), intKind.template)),
                predicate(listOf(intKind.template)) { false },
            )

        val (result) = evaluate(recipe, record)

        result.outcome shouldBe CheckOutcome.NeedsInputWrapper(listOf(listItemAt(RESOURCE, "numbers", "missing")))
        result.findings.map { it.primary } shouldBe listOf(listItemAt(RESOURCE, "numbers", "known"))
    }

    test("occurrences beyond the tuple budget make the check incomplete instead of silently partial") {
        val recipe =
            recipe(
                listOf(CheckInput(TEST_TYPE, pattern("numbers", FieldPatternSegment.ITEMS), intKind.template)),
                predicate(listOf(intKind.template)) { false },
            )

        val (result, health) = evaluate(recipe, record(numbers = listOf("a" to 1, "b" to 2)), ViewReadLimits(maxCheckTuples = 1))

        health.outcome(recipe.owner) shouldBe CheckOutcome.IncompleteWrapper("check occurrence tuple limit exceeded")
        result.findings.map { it.primary } shouldBe listOf(listItemAt(RESOURCE, "numbers", "a"))
    }
}
