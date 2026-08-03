package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.repository.utils.invalidRecordId
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.realm.repository.utils.toSkirRecordId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.kernel.v1.record_id.*
import java.util.*
import com.surrealdb.RecordId as SurrealRecordId

val RecordIdConversionTest by testSuite {
    test("primitive record keys convert in both directions") {
        val uuid = UUID.fromString("28aaad1f-9355-45c7-8313-80d3f034d549")

        rid(RecordIdKey.StringWrapper("alpha")).surrealId("book").toString() shouldBe "book:alpha"
        rid(RecordIdKey.NumberWrapper(42)).surrealId("book").toString() shouldBe "book:42"
        rid(RecordIdKey.UuidWrapper(uuid.toString())).surrealId("book").toString() shouldBe "book:u'$uuid'"
        SurrealRecordId("book", "alpha").toSkirRecordId() shouldBe rid(RecordIdKey.StringWrapper("alpha"))
        SurrealRecordId("book", 42).toSkirRecordId() shouldBe rid(RecordIdKey.NumberWrapper(42))
        SurrealRecordId("book", uuid).toSkirRecordId() shouldBe rid(RecordIdKey.UuidWrapper(uuid.toString()))
    }

    test("array and object keys retain nested values") {
        val array = RecordIdKey.ArrayWrapper(
            listOf(
                RecordIdValue.NumberWrapper(4),
                RecordIdValue.StringWrapper("chapter"),
                RecordIdValue.BooleanWrapper(true),
                RecordIdValue.NULL,
            ),
        )
        val objectKey = RecordIdKey.ObjectWrapper(
            listOf(
                ObjectRecordIdKey(key = "name", value = RecordIdValue.StringWrapper("alpha")),
                ObjectRecordIdKey(
                    key = "nested",
                    value = RecordIdValue.ObjectWrapper(
                        listOf(
                            ObjectRecordIdValue(
                                key = "enabled",
                                value = RecordIdValue.BooleanWrapper(true),
                            ),
                        ),
                    ),
                ),
            ),
        )

        rid(array).surrealId("book").toString() shouldBe "book:[4, 'chapter', true, NULL]"

        shouldThrow<UnsupportedOperationException> {
            rid(objectKey).surrealId("book")
        }
    }

    test("complex SurrealDB record keys round trip into Skir") {
        Surreal().use { database ->
            database.connect("memory")
            database.useNs("record_id_test").useDb("record_id_test")

            val array = database.query("RETURN type::record('book', [4, 'chapter']);").take(0).recordId
            val objectKey = database.query("RETURN type::record('book', { name: 'alpha', order: 2 });")
                .take(0).recordId

            array.toSkirRecordId().surrealId("book").toString() shouldBe "book:[4, 'chapter']"
            shouldThrow<UnsupportedOperationException> {
                objectKey.toSkirRecordId().surrealId("book")
            }
        }
    }

    test("table validation reports every distinct wrong table") {
        listOf(rid("page", "one"), rid("tag", "two"), rid("page", "three")).invalidRecordId("book") shouldBe
                skirout.kernel.v1.errors.InvalidRecordIdError(
                    expectedTable = "book",
                    givenTables = listOf("page", "tag"),
                )
        listOf(rid("book", "one")).invalidRecordId("book") shouldBe null
        rid("page", "one").invalidRecordId("book") shouldBe skirout.kernel.v1.errors.InvalidRecordIdError(
            expectedTable = "book",
            givenTables = listOf("page"),
        )
        shouldThrow<IllegalArgumentException> { rid("page", "one").surrealId("book") }
    }

    test("unknown record key values fail explicitly") {
        shouldThrow<IllegalStateException> { rid(RecordIdKey.UNKNOWN).surrealId("book") }
        shouldThrow<IllegalStateException> {
            rid(RecordIdKey.ArrayWrapper(listOf(RecordIdValue.UNKNOWN))).surrealId("book")
        }
    }
}

private fun rid(key: RecordIdKey) = RecordId(table = "book", key = key)

private fun rid(table: String, key: String) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))
