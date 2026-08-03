package com.typewritermc.realm.schema

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val RealmSchemaResourcesTest by testSuite {
    test("packaged Realm schema catalog exposes its dependency order") {
        MigrationResources().loadRealmSchema().map(SchemaResource::path) shouldBe
            listOf(
                "book/book.surql",
                "kernel/color.surql",
                "kernel/id.surql",
                "page/page.surql",
                "relations/bears.surql",
                "relations/inherits.surql",
                "tag/tag.surql",
            )
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
