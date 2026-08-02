package com.typewritermc.realm.schema

import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe

val DatabaseProviderTest by testSuite {
    fun provider(
        url: String = "ws://localhost:8235",
        username: String = "root",
        password: String = "root",
        namespace: String = "typewriter",
        database: String = "realm",
    ) = DatabaseProvider(
        url = url,
        username = username,
        password = password,
        namespace = namespace,
        database = database,
    )

    testSuite("configuration") {
        test("blank URL is rejected") {
            shouldThrow<IllegalArgumentException> { provider(url = " ") }
        }

        test("partial credentials are rejected") {
            shouldThrow<IllegalArgumentException> { provider(password = "") }
            shouldThrow<IllegalArgumentException> { provider(username = "") }
        }

        test("blank credentials are allowed for an unauthenticated server") {
            provider(username = "", password = "")
        }

        test("blank namespace is rejected") {
            shouldThrow<IllegalArgumentException> { provider(namespace = " ") }
        }

        test("blank database name is rejected") {
            shouldThrow<IllegalArgumentException> { provider(database = " ") }
        }
    }

    testSuite("server version") {
        test("exact configured server version is accepted") {
            requireSupportedDatabaseVersion(SURREALDB_SERVER_VERSION)
            requireSupportedDatabaseVersion("surrealdb-$SURREALDB_SERVER_VERSION")
            requireSupportedDatabaseVersion("$SURREALDB_SERVER_VERSION+20260721.40522d1")
        }

        test("different server version is rejected") {
            val error = shouldThrow<UnsupportedDatabaseVersionException> {
                requireSupportedDatabaseVersion("3.1.5")
            }

            error.message shouldBe
                "Realm requires SurrealDB $SURREALDB_SERVER_VERSION but connected to 3.1.5"
        }
    }
}
