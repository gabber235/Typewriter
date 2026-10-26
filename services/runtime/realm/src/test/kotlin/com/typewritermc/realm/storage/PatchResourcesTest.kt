package com.typewritermc.realm.storage

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe

val PatchResourcesTest by testSuite {
    test("patch catalog loads patches in index order") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_first.surql\n0002_second.surql\n",
                "schema/patches/0001_first.surql" to "RETURN 1;",
                "schema/patches/0002_second.surql" to "RETURN 2;",
            )

        resources.loadPatches().map(DatabasePatch::id) shouldBe listOf("0001_first", "0002_second")
    }

    test("a patch checksum is the SHA 256 of its exact script and differs for a different script") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_first.surql\n0002_second.surql\n",
                "schema/patches/0001_first.surql" to "RETURN 1;",
                "schema/patches/0002_second.surql" to "RETURN 2;",
            )

        val (first, second) = resources.loadPatches()

        first.checksum shouldBe "c0c56fa4c8d922c6511fedebd6c98d3c18fb707f7cd96b0812f7f9d459327178"
        second.checksum shouldNotBe first.checksum
    }

    test("empty patch catalog is valid for a fresh schema") {
        val resources = migrationResources("schema/patches/_index.txt" to "")

        resources.loadPatches() shouldBe emptyList()
    }

    test("patch catalog rejects unsorted entries") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0002_second.surql\n0001_first.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }.message shouldBe
            "Patch index must be sorted in ascending filename order"
    }

    test("patch catalog rejects duplicate entries") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_first.surql\n0001_first.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }.message shouldBe
            "Resource index contains duplicate filenames: schema/patches/_index.txt"
    }

    test("patch catalog rejects invalid filenames") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "first.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }.message shouldBe "Invalid patch filename: first.surql"
    }

    test("patch catalog fails when an indexed patch is missing") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_missing.surql",
            )

        shouldThrow<MissingMigrationResourceException> { resources.loadPatches() }.message shouldBe
            "Migration resource not found: schema/patches/0001_missing.surql"
    }
}
