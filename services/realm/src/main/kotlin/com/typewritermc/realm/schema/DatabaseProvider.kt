package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.surrealdb.signin.RootCredential
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.withErrorSlug

private val DATABASE_CONNECT_FAILURE = ErrorSlug.of("realm-database-connect-failed")

class DatabaseProvider(
    private val url: String,
    private val username: String,
    private val password: String,
    private val namespace: String,
    private val database: String,
) {

    init {
        require(url.isNotBlank()) { "Database URL must not be blank" }
        require(username.isBlank() == password.isBlank()) {
            "Database username and password must either both be set or both be blank"
        }
        require(namespace.isNotBlank()) { "Database namespace must not be blank" }
        require(database.isNotBlank()) { "Database name must not be blank" }
    }

    context(_: MainSpanScope)
    fun connect(): Surreal = childSpanBlocking("realm.database.connect") { child ->
        withErrorSlug(DATABASE_CONNECT_FAILURE) {
            child.annotate {
                attribute("db.url", url)
                attribute("db.namespace", namespace)
                attribute("db.database", database)
            }
            val db = Surreal()

            try {
                db.connect(url)
                val serverVersion = db.version()
                requireSupportedDatabaseVersion(serverVersion)
                child.annotate { attribute("db.version", serverVersion) }
                if (username.isNotBlank()) {
                    db.signin(RootCredential(username, password))
                }

                db.useNs(namespace).useDb(database)
                SchemaMigrator(db).migrate()
                db
            } catch (failure: Throwable) {
                runCatching(db::close).exceptionOrNull()?.let(failure::addSuppressed)
                throw failure
            }
        }
    }
}

internal fun requireSupportedDatabaseVersion(version: String) {
    val normalizedVersion = version.removePrefix("surrealdb-").substringBefore('+')
    if (normalizedVersion != SURREALDB_SERVER_VERSION) {
        throw UnsupportedDatabaseVersionException(
            expected = SURREALDB_SERVER_VERSION,
            actual = normalizedVersion,
        )
    }
}

internal class UnsupportedDatabaseVersionException(expected: String, actual: String) :
    IllegalStateException("Realm requires SurrealDB $expected but connected to $actual")
