package com.typewritermc.realm.schema

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val PatchResourcesTest by testSuite {
    test("patch catalog loads sorted patches and computes stable checksums") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_first.surql\n0002_second.surql\n",
                "schema/patches/0001_first.surql" to "RETURN 1;",
                "schema/patches/0002_second.surql" to "RETURN 2;",
            )

        val patches = resources.loadPatches()

        patches.map(DatabasePatch::id) shouldBe listOf("0001_first", "0002_second")
        patches.map { it.checksum.length } shouldBe listOf(64, 64)
        patches[0].checksum shouldBe resources.loadPatches()[0].checksum
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

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("patch catalog rejects duplicate entries") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_first.surql\n0001_first.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("patch catalog rejects invalid filenames") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "first.surql",
            )

        shouldThrow<IllegalArgumentException> { resources.loadPatches() }
    }

    test("patch catalog fails when an indexed patch is missing") {
        val resources =
            migrationResources(
                "schema/patches/_index.txt" to "0001_missing.surql",
            )

        shouldThrow<MissingMigrationResourceException> { resources.loadPatches() }
    }
}
