package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.surrealdb.signin.RootCredential
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import java.util.UUID

/** Runs storage scenarios in a fresh database, optionally on the pinned remote server. */
internal fun Surreal.openTestDatabase(name: String) {
    val endpoint = System.getenv("TYPEWRITER_TEST_SURREAL_ENDPOINT")
    connect(endpoint ?: "mem://")
    if (endpoint != null) {
        requireSupportedDatabaseVersion(version(), SURREALDB_SERVER_VERSION)
        println("Remote Realm storage server: ${version()}")
        val username = System.getenv("TYPEWRITER_TEST_SURREAL_USERNAME")
        if (username != null) {
            signin(RootCredential(username, requireNotNull(System.getenv("TYPEWRITER_TEST_SURREAL_PASSWORD"))))
        }
    }
    useNs("typewriter_tests").useDb(name + "_" + UUID.randomUUID().toString().replace("-", ""))
}
