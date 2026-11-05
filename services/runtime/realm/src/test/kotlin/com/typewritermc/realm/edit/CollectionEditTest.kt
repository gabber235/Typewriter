package com.typewritermc.realm.edit

import com.typewritermc.authoring.field
import com.typewritermc.authoring.item
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.realm.testing.DefinitionCatalog
import com.typewritermc.realm.testing.RealmFixture
import com.typewritermc.realm.testing.completeRecord
import com.typewritermc.realm.testing.expectRefused
import com.typewritermc.realm.testing.shouldBeCommitted
import com.typewritermc.realm.testing.textItem
import com.typewritermc.testkit.definitions
import com.typewritermc.types.actualType
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.payload
import com.typewritermc.types.qualified
import com.typewritermc.types.template
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import skirout.editor.v1.authoring.EditIntent
import skirout.editor.v1.type_catalog.CollectionKind
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val CollectionEditTest by testSuite {
    val holder = ResourceId(value = "holder")

    val holderType = TypeDefinitionId.qualified("test", "holder")

    val textsType = TypeDefinitionId.qualified("test", "texts")

    val values = ValueLocation.of(holder, ValuePath.root.field("values"))

    /** A holder whose `values` field is a list of text. */
    val listHolder =
        DefinitionCatalog(
            definitions {
                record(holderType) { field("values", textsType.template()) }
                sequence(textsType, ScalarKind.TEXT.template, CollectionKind.LIST)
            },
        )

    val emptyHolding =
        mapOf(holder to completeRecord(holderType, "values" to DataValue.named(textsType.namedUse(), DataValue.listValue(emptyList()))))

    val holdingA =
        mapOf(
            holder to
                completeRecord(holderType, "values" to DataValue.named(textsType.namedUse(), DataValue.listValue(listOf(textItem("a"))))),
        )

    val holdingAB =
        mapOf(
            holder to
                completeRecord(
                    holderType,
                    "values" to DataValue.named(textsType.namedUse(), DataValue.listValue(listOf(textItem("a"), textItem("b")))),
                ),
        )

    listOf(CollectionKind.LIST to "list", CollectionKind.SET to "set").forEach { (kind, name) ->
        test("inserting into an unfilled $name saves the $name with the item") {
            val catalog =
                DefinitionCatalog(
                    definitions {
                        record(holderType) { field("values", textsType.template()) }
                        sequence(textsType, ScalarKind.TEXT.template, kind)
                    },
                )
            val seed = mapOf(holder to completeRecord(holderType, "values" to DataValue.UNFILLED))
            RealmFixture.of(catalog, seed).use { realm ->
                val item = textItem("stable_item", "value")

                realm.commit(EditIntent.createInsert(at = values, after = null, item = item)).shouldBeCommitted()

                val saved =
                    realm.resources
                        .getValue(
                            holder,
                        ).fields
                        .single { it.name == "values" }
                        .value
                        .shouldBeInstanceOf<DataValue.NamedWrapper>()
                saved.actualType shouldBe textsType.namedUse()
                when (kind) {
                    CollectionKind.LIST -> saved.payload.shouldBeInstanceOf<DataValue.ListValueWrapper>().items shouldBe listOf(item)
                    else -> saved.payload.shouldBeInstanceOf<DataValue.SetValueWrapper>().items shouldBe listOf(item)
                }
            }
        }
    }

    test("inserting an item of the wrong type is refused at that item") {
        RealmFixture.of(listHolder, emptyHolding).use { realm ->
            val flag = ListItem(id = ItemId(value = "flag"), value = DataValue.BooleanWrapper(true))

            realm.expectRefused(EditIntent.createInsert(at = values, after = null, item = flag)).map { it.location to it.code } shouldBe
                listOf(values.item(flag.id) to "wrong_scalar")
        }
    }

    test("inserting an item under an id the collection already holds is refused") {
        RealmFixture.of(listHolder, holdingA).use { realm ->
            realm
                .expectRefused(
                    EditIntent.createInsert(at = values, after = null, item = textItem("a", "again")),
                ).map { it.location to it.code } shouldBe
                listOf(values to "duplicate_item_id")
        }
    }

    test("writing into an item the collection does not hold is refused at that item") {
        RealmFixture.of(listHolder, holdingA).use { realm ->
            val absent = values.item(ItemId(value = "gone"))

            realm.expectRefused(EditIntent.createSetValue(at = absent, value = DataValue.StringValueWrapper("x"))).map {
                it.location to
                    it.code
            } shouldBe
                listOf(absent to "location_missing")
        }
    }

    test("moving an item after itself is refused") {
        RealmFixture.of(listHolder, holdingAB).use { realm ->
            realm.expectRefused(EditIntent.createMove(at = values, item = ItemId(value = "a"), after = ItemId(value = "a"))).map {
                it.location to
                    it.code
            } shouldBe
                listOf(values to "item_cannot_follow_itself")
        }
    }

    test("moving an item after an anchor the collection does not hold is refused") {
        RealmFixture.of(listHolder, holdingAB).use { realm ->
            realm.expectRefused(EditIntent.createMove(at = values, item = ItemId(value = "a"), after = ItemId(value = "gone"))).map {
                it.location to
                    it.code
            } shouldBe
                listOf(values to "anchor_missing")
        }
    }
}
