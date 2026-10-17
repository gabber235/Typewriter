package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.ItemId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.realm.authoring.authoredDatabaseValues
import com.typewritermc.realm.checking.TEST_TYPE
import com.typewritermc.realm.schema.openTestDatabase
import com.typewritermc.types.DataValue
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import java.math.BigInteger

val NativeAuthoringStorageTestSuite by testSuite {
    test("native nested values preserve authored distinctions and stable identities") {
        val record =
            AuthoringRecord(
                TypeSelection.Complete(TypeUse.Named(TEST_TYPE)),
                mapOf(
                    "empty" to DataValue.Unfilled,
                    "nullable" to DataValue.Null,
                    "integer" to DataValue.Integer(BigInteger("9007199254740993123456789")),
                    "decimal" to DataValue.Decimal("1.234567890123456789"),
                    "bytes" to DataValue.Bytes(byteArrayOf(0, 1, 127, -128)),
                    "list" to DataValue.ListValue(listOf(ListItem(ItemId("stable"), DataValue.StringValue("Quest")))),
                    "map" to
                        DataValue.MapValue(
                            listOf(
                                MapRow(ItemId("row"), DataValue.StringValue("key"), DataValue.Record(mapOf("nested" to DataValue.Null))),
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
                    mapOf("content" to authoredDatabaseValues.encode(AuthoringRecord.serializer(), record)),
                ).take(0)
            val content = database.query("SELECT VALUE content FROM ONLY resource:quest;").take(0)
            assertTrue(content.isObject)
            assertTrue(content.getObject().get("fields").isObject)
            assertEquals(record, authoredDatabaseValues.decode(AuthoringRecord.serializer(), content))
            val title = database.query("SELECT VALUE content.fields.list.items[0].value.value FROM ONLY resource:quest;").take(0)
            assertEquals("Quest", title.getString())
        }
    }
}
