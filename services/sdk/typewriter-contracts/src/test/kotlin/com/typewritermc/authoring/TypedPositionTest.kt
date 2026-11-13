package com.typewritermc.authoring

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.TEXT
import com.typewritermc.types.TEXT_TEMPLATE
import com.typewritermc.types.bareRecord
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.Resolution
import com.typewritermc.types.field
import com.typewritermc.types.id
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.namedTemplate
import com.typewritermc.types.namedUse
import com.typewritermc.types.nullable
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeSelection
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

val TypedPositionTest by testSuite {
    val holderResource = ResourceId(value = "holder")
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
    val prize = id("prize")
    val coin = id("coin")
    val gem = id("gem")
    val holder = id("holder")
    val catalog =
        DefaultCheckedCatalog(
            CatalogGeneration(value = "typed"),
            StandardTypes.definitions +
                listOf("coin" to "worth", "gem" to "carat").map { (definition, name) ->
                    TypeDefinition.partial(
                        id = id(definition),
                        representation =
                            RepresentationTemplate.createRecord(
                                fields = listOf(field(definition, name, int.template)),
                                form = RecordForm.CONCRETE,
                            ),
                        parents = listOf(prize.namedTemplate()),
                    )
                } +
                listOf(
                    bareRecord(prize, RecordForm.OPEN),
                    TypeDefinition.partial(
                        id = holder,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields =
                                    listOf(
                                        field("holder", "prize", prize.template()),
                                        field("holder", "items", StandardTypes.list.template(listOf(prize.template()))),
                                        field("holder", "table", StandardTypes.map.template(listOf(TEXT_TEMPLATE, int.template))),
                                        field("holder", "maybe", coin.template().nullable()),
                                        field("holder", "spare", coin.template().nullable()),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                ),
        )
    val record =
        AuthoringRecord.of(
            TypeSelection.of(holder.namedUse()),
            mapOf(
                "prize" to DataValue.named(gem.namedUse(), DataValue.record("carat" to DataValue.integer(3))),
                "items" to
                    DataValue.named(
                        StandardTypes.list.namedUse(listOf(prize.use())),
                        DataValue.listValue(
                            listOf(
                                ListItem(
                                    id = ItemId(value = "a"),
                                    value =
                                        DataValue.named(
                                            coin.namedUse(),
                                            DataValue.record("worth" to DataValue.integer(1)),
                                        ),
                                ),
                            ),
                        ),
                    ),
                "table" to
                    DataValue.named(
                        StandardTypes.map.namedUse(listOf(TEXT, int.use)),
                        DataValue.mapValue(
                            listOf(MapRow(id = ItemId(value = "r"), key = DataValue.StringValueWrapper("k"), value = DataValue.integer(2))),
                        ),
                    ),
                "maybe" to DataValue.NULL,
                "spare" to DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(4))),
            ),
        )
    test("every location the value walk visits is found by typedAt, with the type the walk read there") {
        val root = ValueLocation.of(holderResource)
        val walk = walked(catalog, DataValue.named(holder.namedUse(), DataValue.RecordWrapper(record.payload)), holder.use(), root)

        val schemaOf = { use: TypeUse -> (catalog.resolve(use) as? Resolution.Ready)?.value?.schema }
        walk.reported.shouldBeEmpty()
        val disagreeing =
            walk.visited.filter { visited ->
                val position = record.typedAt(holderResource, visited.at.path, catalog) as? TypedPosition.Value
                position == null || (visited.actual != null && schemaOf(position.actual) != schemaOf(visited.actual))
            }
        disagreeing shouldBe emptyList()
    }

    test("a field of a union case is found under the case its value names, and the other case's field is not") {
        val prizePath = ValuePath.root.field("prize")

        (record.typedAt(holderResource, prizePath.field("carat"), catalog) as TypedPosition.Value).declared shouldBe int.use
        record.typedAt(holderResource, prizePath.field("worth"), catalog) shouldBe null
    }

    test("a nullable field keeps its nullable declared type while it holds a value") {
        (record.typedAt(holderResource, ValuePath.root.field("spare"), catalog) as TypedPosition.Value).declared shouldBe coin.use().nullable()
        record.authoredTypeAt(holderResource, ValuePath.root.field("spare"), catalog) shouldBe coin.use()
    }

    test("an item of a map stops at its row until a key or value segment picks a part") {
        val row = ValuePath.root.field("table").item(ItemId(value = "r"))

        record.authoredTypeAt(holderResource, row, catalog) shouldBe null
        (record.typedAt(holderResource, row.mapValue(), catalog) as TypedPosition.Value).value shouldBe DataValue.integer(2)
    }
}
