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
import com.typewritermc.types.with
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldBeEmpty
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring.UnsetValue
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RecordPayload
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
    val shelf = id("shelf")
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
                                        field("holder", "bonus", coin.template()).copy(hasConstructorDefault = true),
                                    ),
                                form = RecordForm.CONCRETE,
                            ),
                    ),
                    TypeDefinition.partial(
                        id = shelf,
                        representation =
                            RepresentationTemplate.createRecord(
                                fields = listOf(field("shelf", "holders", StandardTypes.list.template(listOf(holder.template())))),
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
        (record.typedAt(holderResource, ValuePath.root.field("spare"), catalog) as TypedPosition.Value).declared shouldBe
            coin.use().nullable()
        record.authoredTypeAt(holderResource, ValuePath.root.field("spare"), catalog) shouldBe coin.use()
    }

    test("an item of a map stops at its row until a key or value segment picks a part") {
        val row = ValuePath.root.field("table").item(ItemId(value = "r"))

        record.authoredTypeAt(holderResource, row, catalog) shouldBe null
        (record.typedAt(holderResource, row.mapValue(), catalog) as TypedPosition.Value).value shouldBe DataValue.integer(2)
    }

    val bonus = ValuePath.root.field("bonus")
    val asked = mutableListOf<Triple<TypeUse, Set<String>, String>>()
    val unset =
        UnsetFields { owner, stored, field ->
            asked += Triple(owner.use, stored.value.fields.mapView.keys, field)
            DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(9)))
        }

    test("an unset field reads as what the unset fields give for its owner and stored fields, marked unset, and the walk steps into it") {
        val position = record.typedAt(holderResource, bonus, catalog, unset) as TypedPosition.Value

        position.unset shouldBe true
        position.declared shouldBe coin.use()
        position.value shouldBe DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(9)))
        (record.typedAt(holderResource, bonus.field("worth"), catalog, unset) as TypedPosition.Value).value shouldBe DataValue.integer(9)
        asked.first() shouldBe Triple(holder.use(), setOf("prize", "items", "table", "maybe", "spare"), "bonus")
        (record.typedAt(holderResource, ValuePath.root.field("spare"), catalog, unset) as TypedPosition.Value).unset shouldBe false
    }

    test("without unset fields to ask, an unset field reads as unfilled and is still marked unset") {
        val position = record.typedAt(holderResource, bonus, catalog) as TypedPosition.Value

        position.unset shouldBe true
        position.value shouldBe DataValue.UNFILLED
    }

    test("materializing a path below an unset field stores that field as it reads, and leaves a stored path alone") {
        val materialized = record.materialized(holderResource, bonus.field("worth"), catalog, unset)

        materialized.field("bonus") shouldBe DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(9)))
        record.materialized(holderResource, ValuePath.root.field("spare").field("worth"), catalog, unset) shouldBe record
    }

    test("filling unset fields stores every unset field at any depth as it reads, and keeps every stored value") {
        val holders = StandardTypes.list.namedUse(listOf(holder.use()))
        val shelved = { payload: RecordPayload ->
            DataValue.named(
                shelf.namedUse(),
                DataValue.record(
                    "holders" to
                        DataValue.named(
                            holders,
                            DataValue.listValue(
                                listOf(
                                    ListItem(
                                        id = ItemId(value = "h"),
                                        value = DataValue.named(holder.namedUse(), DataValue.RecordWrapper(payload)),
                                    ),
                                ),
                            ),
                        ),
                ),
            )
        }
        val shelfType = (catalog.resolve(shelf.use()) as Resolution.Ready).value
        val complete = (shelfType.complete(shelved(record.payload)) as CompletenessResult.Complete).value

        val filled = complete.withUnsetFields(catalog, unset)

        filled.value shouldBe
            shelved(record.payload.with("bonus", DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(9)))))
    }

    test("listing unset fields gives each at its path from the record root, inside items too, with the value it reads as") {
        val nine = DataValue.named(coin.namedUse(), DataValue.record("worth" to DataValue.integer(9)))
        val shelved =
            AuthoringRecord.of(
                TypeSelection.of(shelf.namedUse()),
                mapOf(
                    "holders" to
                        DataValue.named(
                            StandardTypes.list.namedUse(listOf(holder.use())),
                            DataValue.listValue(
                                listOf(
                                    ListItem(
                                        id = ItemId(value = "h"),
                                        value = DataValue.named(holder.namedUse(), DataValue.RecordWrapper(record.payload)),
                                    ),
                                ),
                            ),
                        ),
                ),
            )

        shelved.unsetValues(ResourceId(value = "shelf"), catalog, unset) shouldBe
            listOf(
                UnsetValue(
                    path =
                        ValuePath.root
                            .field("holders")
                            .item(ItemId(value = "h"))
                            .field("bonus"),
                    value = nine,
                ),
            )
    }
}
