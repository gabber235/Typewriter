package com.typewritermc.authoring

import com.typewritermc.types.StandardTypes
import com.typewritermc.types.catalog.ContentSource
import com.typewritermc.types.catalog.DefaultCheckedCatalog
import com.typewritermc.types.catalog.content
import com.typewritermc.types.catalog.contentField
import com.typewritermc.types.integer
import com.typewritermc.types.integerScalar
import com.typewritermc.types.listValue
import com.typewritermc.types.named
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import com.typewritermc.types.template
import com.typewritermc.types.use
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContain
import io.kotest.matchers.collections.shouldContainAll
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldDeclaration
import skirout.editor.v1.type_catalog.FieldOwner
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.RecordForm
import skirout.editor.v1.type_catalog.RepresentationTemplate
import skirout.editor.v1.type_catalog.ScalarKind
import skirout.editor.v1.type_catalog.TypeDefinition
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

val ValueAdmissionTest by testSuite {
    val int = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).use
    val owner = ResourceId(value = "prizes")
    val prize = TypeDefinitionId.content(owner, "prize")
    val declarations =
        listOf(
            TypeDefinition.partial(
                id = prize,
                representation =
                    RepresentationTemplate.createRecord(
                        fields =
                            listOf(
                                FieldDeclaration.partial(
                                    owner = FieldOwner(definition = prize, name = "gold"),
                                    type = integerScalar(IntegerWidth.SIGNED_THIRTY_TWO).template,
                                ),
                            ),
                        form = RecordForm.CONCRETE,
                    ),
            ),
        )
    val catalog =
        DefaultCheckedCatalog(CatalogGeneration(value = "walk"), StandardTypes.definitions).withContent(
            object : ContentSource {
                override fun declarations(owner: ResourceId): List<TypeDefinition> =
                    if (owner.value ==
                        "prizes"
                    ) {
                        declarations
                    } else {
                        emptyList()
                    }

                override fun heldType(
                    owner: ResourceId,
                    field: String,
                ): TypeUse? = if (field == "alias") prize.use() else null
            },
        )
    val at = ValueLocation.of(ResourceId(value = "holder"))

    test("each list item reaches the visitor at its own item location") {
        val list = StandardTypes.list.namedUse(listOf(int))
        val value = DataValue.named(list, DataValue.listValue(listOf(ListItem(id = ItemId(value = "a"), value = DataValue.integer(1)))))
        walked(catalog, value, list.use, at).visited shouldContain Visited("scalar", at.item(ItemId(value = "a")))
    }

    test("a map key and its value reach the visitor at the row's key and value locations") {
        val map = StandardTypes.map.namedUse(listOf(ScalarKind.TEXT.use, int))
        val row = MapRow(id = ItemId(value = "r"), key = DataValue.StringValueWrapper("k"), value = DataValue.integer(2))
        val value = DataValue.named(map, DataValue.createMapValue(rows = listOf(row)))
        walked(catalog, value, map.use, at).visited shouldContainAll
            listOf(Visited("scalar", at.item(ItemId(value = "r")).mapKey()), Visited("scalar", at.item(ItemId(value = "r")).mapValue()))
    }

    test("a named value reaches the visitor at its own location with its expanded actual type") {
        val alias = TypeDefinitionId.contentField(owner, "alias")
        val value = DataValue.named(alias.namedUse(), DataValue.record("gold" to DataValue.integer(5)))
        walked(catalog, value, alias.use(), at).visited shouldContain Visited("record", at, prize.use())
    }

    test("two missing content types in one stored type use are two misfits at that location") {
        val first = TypeDefinitionId.content(ResourceId(value = "gone"), "first")
        val second = TypeDefinitionId.content(ResourceId(value = "gone"), "second")
        val held = StandardTypes.map.use(listOf(first.use(), second.use()))
        val reported = walked(catalog, DataValue.TypeUseWrapper(held), ScalarKind.TYPE.use, at).reported.filter { it.type != null }
        reported.map { it.at to it.type } shouldBe listOf(at to first, at to second)
    }
}
