package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.of
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.repository.utils.decodeSkir
import com.typewritermc.realm.repository.utils.encodeSkir
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.bytes
import com.typewritermc.types.fields
import com.typewritermc.types.integer
import com.typewritermc.types.items
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.namedUse
import com.typewritermc.types.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.type_catalog.AuthoringRecord
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.TypeSelection
import java.math.BigInteger

val NativeAuthoringStorageTestSuite by testSuite {
    test("native nested values preserve authored distinctions and stable identities") {
        val record =
            AuthoringRecord.of(
                TypeSelection.CompleteWrapper(TEST_TYPE.namedUse()),
                mapOf(
                    "empty" to DataValue.UNFILLED,
                    "nullable" to DataValue.NULL,
                    "integer" to DataValue.integer(BigInteger("9007199254740993123456789")),
                    "decimal" to DataValue.DecimalWrapper("1.234567890123456789"),
                    "bytes" to DataValue.bytes(byteArrayOf(0, 1, 127, -128)),
                    "list" to
                        DataValue.listValue(listOf(ListItem(id = ItemId(value = "stable"), value = DataValue.StringValueWrapper("Quest")))),
                    "map" to
                        DataValue.mapValue(
                            listOf(
                                MapRow(
                                    id = ItemId(value = "row"),
                                    key = DataValue.StringValueWrapper("key"),
                                    value =
                                        DataValue.record(
                                            mapOf("nested" to DataValue.NULL),
                                        ),
                                ),
                            ),
                        ),
                ),
            )
        Surreal().use { database ->
            database.openTestDatabase("native_authored")
            database.query("DEFINE TABLE resource SCHEMAFULL; DEFINE FIELD content ON resource TYPE object FLEXIBLE;")
            database
                .query(
                    "CREATE resource:quest SET content = \$content;",
                    mapOf("content" to encodeSkir(AuthoringRecord.serializer, record)),
                ).take(0)
            val content = database.query("SELECT VALUE content FROM ONLY resource:quest;").take(0)
            content.isObject shouldBe true
            content.getObject().get("fields").isArray shouldBe true
            decodeSkir(AuthoringRecord.serializer, content) shouldBe record
            val title =
                database
                    .query(
                        "SELECT VALUE content.fields[WHERE name = 'list'][0].value.value.items[0].value.value FROM ONLY resource:quest;",
                    ).take(0)
            title.getString() shouldBe "Quest"
        }
    }
}
