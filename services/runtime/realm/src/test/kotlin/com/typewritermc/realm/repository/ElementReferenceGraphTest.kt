package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrowAny
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val ElementReferenceGraphTest by testSuite {
    test("normal reference records retain missing targets and cascade with their source") {
        RepositoryFixture().use { fixture ->
            fixture.database
                .query(
                    """
                    DEFINE TABLE retained_reference SCHEMAFULL TYPE NORMAL;
                    DEFINE FIELD source ON retained_reference
                        TYPE record<element> REFERENCE ON DELETE CASCADE;
                    DEFINE FIELD target ON retained_reference
                        TYPE record<element> REFERENCE ON DELETE IGNORE;
                    DEFINE FIELD slot ON retained_reference TYPE string;
                    DEFINE INDEX retained_reference_source_slot
                        ON retained_reference FIELDS source, slot UNIQUE;
                    DEFINE INDEX retained_reference_target
                        ON retained_reference FIELDS target;
                    """.trimIndent(),
                ).consumeAll()
            fixture.database.query(ELEMENT_FIXTURES).consumeAll()
            fixture.database
                .query(
                    "CREATE retained_reference:first SET " +
                        "source = element:source, target = element:target, slot = 'target';",
                ).consumeAll()

            shouldThrowAny {
                fixture.database
                    .query(
                        "CREATE retained_reference:duplicate SET " +
                            "source = element:source, target = element:target, slot = 'target';",
                    ).consumeAll()
            }

            fixture.database.query("DELETE element:target;").consumeAll()
            fixture.database
                .query("SELECT VALUE target FROM retained_reference WHERE target = element:target;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:target")

            fixture.database.query("DELETE element:source;").consumeAll()
            fixture.database
                .query("SELECT VALUE id FROM retained_reference;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldBe emptyList()
        }
    }

    test("resource references support forward and reverse lookup") {
        RepositoryFixture().use { fixture ->
            fixture.database.query(ELEMENT_FIXTURES).consumeAll()
            fixture.database
                .query(
                    "CREATE resource_reference:[element:source, 'target'] CONTENT { " +
                        "source: element:source, target: element:target, " +
                        "slot: 'target', expected_type: 'test/Entry' };",
                ).consumeAll()

            fixture.database
                .query("SELECT VALUE target FROM resource_reference WHERE source = element:source;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:target")
            fixture.database
                .query("SELECT VALUE source FROM resource_reference WHERE target = element:target;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:source")
        }
    }

    test("dangling resource references preserve target identity") {
        RepositoryFixture().use { fixture ->
            fixture.database.query(ELEMENT_FIXTURES).consumeAll()
            fixture.database
                .query(
                    "CREATE resource_reference:[element:source, 'missing'] CONTENT { " +
                        "source: element:source, target: element:missing, " +
                        "slot: 'missing', expected_type: 'test/Entry' };",
                ).consumeAll()

            fixture.database
                .query("SELECT VALUE target FROM resource_reference WHERE slot = 'missing';")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:missing")
            fixture.database
                .query("SELECT VALUE record::exists(target) FROM resource_reference WHERE slot = 'missing';")
                .take(0)
                .getArray()
                .map { it.getBoolean() } shouldContainExactly listOf(false)
        }
    }
}

private fun com.surrealdb.Response.consumeAll() {
    for (index in 0 until size()) take(index)
}

private const val ELEMENT_FIXTURES =
    """
    CREATE element:source CONTENT {
        element_type: 'test:entry',
        schema_revision: 1,
        value: { format: 1, data: { kind: 'record', fields: { id: { kind: 'string', value: 'source' }, name: { kind: 'string', value: 'Source' } } } },
        placement: { kind: 'graph_v1', x: 0, y: 0, width: 1, height: 1 }
    };
    CREATE element:target CONTENT {
        element_type: 'test:entry',
        schema_revision: 1,
        value: { format: 1, data: { kind: 'record', fields: { id: { kind: 'string', value: 'target' }, name: { kind: 'string', value: 'Target' } } } },
        placement: { kind: 'graph_v1', x: 1, y: 1, width: 1, height: 1 }
    };
    """
