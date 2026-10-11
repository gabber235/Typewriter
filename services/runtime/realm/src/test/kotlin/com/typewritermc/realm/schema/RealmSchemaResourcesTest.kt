package com.typewritermc.realm.schema

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RealmSchemaResourcesTest by testSuite {
    test("Realm schema contains only authored resources, relations, and publication attempts") {
        val schema = MigrationResources().loadRealmSchema()
        schema.map(SchemaResource::path) shouldBe
            listOf(
                "search/authoring_text.surql",
                "resource/resource.surql",
                "resource/resource_relation.surql",
                "compile/publication_attempt.surql",
            )
        schema.sumOf { Regex("DEFINE TABLE").findAll(it.script).count() } shouldBe 3
    }
    test("publication results and diagnostics use native objects") {
        val schema = MigrationResources().loadRealmSchema().last().script
        schema.contains("result ON publication_attempt TYPE option<object> FLEXIBLE") shouldBe true
        schema.contains("findings.* ON publication_attempt TYPE object FLEXIBLE") shouldBe true
    }

    test("Realm schema catalog preserves declared dependency order") {
        val resources =
            migrationResources(
                "schema/realm/_index.txt" to "kernel/functions.surql\nbook.surql",
                "schema/realm/kernel/functions.surql" to "DEFINE FUNCTION fn::valid() { RETURN true; };",
                "schema/realm/book.surql" to "DEFINE TABLE book SCHEMAFULL;",
            )

        resources.loadRealmSchema().map(SchemaResource::path) shouldBe
            listOf("kernel/functions.surql", "book.surql")
    }

    test("Realm schema catalog rejects duplicate resources") {
        val resources =
            migrationResources(
                "schema/realm/_index.txt" to "book.surql\nbook.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadRealmSchema() }
    }

    test("Realm schema catalog rejects paths outside its directory") {
        val resources =
            migrationResources(
                "schema/realm/_index.txt" to "../migration.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadRealmSchema() }
    }

    test("Realm schema catalog fails when an indexed resource is missing") {
        val resources =
            migrationResources(
                "schema/realm/_index.txt" to "missing.surql",
            )

        shouldThrow<MissingMigrationResourceException> { resources.loadRealmSchema() }
    }
}
