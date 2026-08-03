package com.typewritermc.realm.schema

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val MigrationResourcesTest by testSuite {
    fun resources(vararg entries: Pair<String, String>): MigrationResources {
        val content = mapOf(
            "schema/migration.surql" to "RETURN true;",
            "schema/realm/_index.txt" to "domain.surql",
            "schema/realm/domain.surql" to "RETURN true;",
            *entries,
        )
        return MigrationResources(content::get)
    }

    test("packaged Realm schema catalog exposes its dependency order") {
        MigrationResources().loadRealmSchema().map(SchemaResource::path) shouldBe listOf(
                "book/book.surql",
                "kernel/color.surql",
                "kernel/id.surql",
                "page/page.surql",
            "relations/bears.surql",
            "relations/inherits.surql",
            "tag/tag.surql",
        )
    }

    test("Realm schema catalog preserves dependency order") {
        val resources = resources(
            "schema/realm/_index.txt" to "kernel/functions.surql\nbook.surql",
            "schema/realm/kernel/functions.surql" to "DEFINE FUNCTION fn::valid() { RETURN true; };",
            "schema/realm/book.surql" to "DEFINE TABLE book SCHEMAFULL;",
        )

        resources.loadRealmSchema().map(SchemaResource::path) shouldBe
            listOf("kernel/functions.surql", "book.surql")
    }

    test("Realm schema catalog rejects duplicate resources") {
        val resources = resources(
            "schema/realm/_index.txt" to "book.surql\nbook.surql",
        )

        shouldThrow<IllegalArgumentException> { resources.loadRealmSchema() }
    }

    test("Realm schema catalog rejects paths outside its directory") {
        val resources = resources(
            "schema/realm/_index.txt" to "../migration.surql",
        )

        shouldThrow<IllegalArgumentException> { resources.loadRealmSchema() }
    }

    test("Realm schema catalog fails when an indexed resource is missing") {
        val resources = resources(
            "schema/realm/_index.txt" to "missing.surql",
        )

        shouldThrow<MissingMigrationResourceException> { resources.loadRealmSchema() }
    }

    test("catalog loads sorted patches and computes stable checksums") {
        val resources = resources(
            "schema/patches/_index.txt" to "0001_first.surql\n0002_second.surql\n",
            "schema/patches/0001_first.surql" to "RETURN 1;",
            "schema/patches/0002_second.surql" to "RETURN 2;",
        )

        val patches = resources.loadPatches()

        patches.map(DatabasePatch::id) shouldBe listOf("0001_first", "0002_second")
        patches.map { it.checksum.length } shouldBe listOf(64, 64)
        patches[0].checksum shouldBe resources.loadPatches()[0].checksum
    }

    test("empty catalog is valid for a fresh schema") {
        val resources = resources("schema/patches/_index.txt" to "")

        resources.loadPatches() shouldBe emptyList()
    }

    test("catalog rejects unsorted entries") {
        val resources = resources(
            "schema/patches/_index.txt" to "0002_second.surql\n0001_first.surql",
        )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("catalog rejects duplicate entries") {
        val resources = resources(
            "schema/patches/_index.txt" to "0001_first.surql\n0001_first.surql",
        )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("catalog rejects invalid filenames") {
        val resources = resources(
            "schema/patches/_index.txt" to "first.surql",
        )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("catalog fails when an indexed patch is missing") {
        val resources = resources(
            "schema/patches/_index.txt" to "0001_missing.surql",
        )

        shouldThrow<MissingMigrationResourceException> { resources.loadPatches() }
    }
}
