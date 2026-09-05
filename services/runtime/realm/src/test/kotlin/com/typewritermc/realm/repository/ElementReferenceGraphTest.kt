package com.typewritermc.realm.repository

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe

val ElementReferenceGraphTest by testSuite {
    test("element references support forward and reverse graph traversal") {
        RepositoryFixture().use { fixture ->
            fixture.database.query(ELEMENT_FIXTURES).consumeAll()
            fixture.database
                .query(
                    "RELATE element:source->element_reference:[element:source, 'target']->element:target " +
                        "SET slot = 'target', expected_type = 'test/Entry';",
                ).consumeAll()

            fixture.database
                .query("RETURN element:source->element_reference->element;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:target")
            fixture.database
                .query("RETURN element:target<-element_reference<-element;")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:source")
        }
    }

    test("dangling element reference edges persist without enforced endpoints") {
        RepositoryFixture().use { fixture ->
            fixture.database.query(ELEMENT_FIXTURES).consumeAll()
            fixture.database
                .query(
                    "RELATE element:source->element_reference:[element:source, 'missing']->element:missing " +
                        "SET slot = 'missing', expected_type = 'test/Entry';",
                ).consumeAll()

            fixture.database
                .query("SELECT VALUE out FROM element_reference WHERE slot = 'missing';")
                .take(0)
                .getArray()
                .map { it.getRecordId().toString() } shouldContainExactly listOf("element:missing")
            fixture.database
                .query("SELECT VALUE record::exists(out) FROM element_reference WHERE slot = 'missing';")
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
        name: 'Source',
        value: {},
        placement: { kind: 'graph_v1', x: 0, y: 0, width: 1, height: 1 }
    };
    CREATE element:target CONTENT {
        element_type: 'test:entry',
        schema_revision: 1,
        name: 'Target',
        value: {},
        placement: { kind: 'graph_v1', x: 1, y: 1, width: 1, height: 1 }
    };
    """
