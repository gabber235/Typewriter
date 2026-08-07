package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.realm.SURREALDB_EMBEDDED_VERSION
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import java.nio.file.Files

val DatabaseProviderTest by testSuite {
    testSuite("database version") {
        test("exact configured versions are accepted") {
            requireSupportedDatabaseVersion(SURREALDB_SERVER_VERSION, SURREALDB_SERVER_VERSION)
            requireSupportedDatabaseVersion("surrealdb-$SURREALDB_EMBEDDED_VERSION", SURREALDB_EMBEDDED_VERSION)
            requireSupportedDatabaseVersion(
                "$SURREALDB_SERVER_VERSION+20260721.40522d1",
                SURREALDB_SERVER_VERSION,
            )
        }

        test("different database version is rejected") {
            val error =
                shouldThrow<UnsupportedDatabaseVersionException> {
                    requireSupportedDatabaseVersion("3.1.5", "3.2.3")
                }

            error.message shouldBe "Realm requires SurrealDB 3.2.3 but connected to 3.1.5"
        }
    }

    test("unavailable embedded engine is rejected") {
        val error =
            shouldThrow<UnsupportedDatabaseEngineException> {
                requireSupportedEmbeddedEngine(
                    DatabaseEndpoint.Embedded.RocksDb(
                        java.nio.file.Path
                            .of("database"),
                    ),
                )
            }

        error.message shouldBe "RocksDB is not available in the configured SurrealDB Java SDK"
    }

    test("versioned embedded engine matches the configured version") {
        Surreal().use { database ->
            database.connect(DatabaseEndpoint.Embedded.Memory().connectionString)
            database.version() shouldBe SURREALDB_EMBEDDED_VERSION
        }
    }

    test("versioned SurrealKV opens persistent storage") {
        val directory = Files.createTempDirectory("realm_surrealkv_versioned")
        try {
            Surreal().use { database ->
                database.connect(DatabaseEndpoint.Embedded.SurrealKv(directory).connectionString)
                database.version() shouldBe SURREALDB_EMBEDDED_VERSION
            }
        } finally {
            directory.toFile().deleteRecursively()
        }
    }
}
