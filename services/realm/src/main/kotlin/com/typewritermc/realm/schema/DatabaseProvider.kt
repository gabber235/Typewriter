package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.surrealdb.signin.BearerCredential
import com.surrealdb.signin.DatabaseCredential
import com.surrealdb.signin.NamespaceCredential
import com.surrealdb.signin.RootCredential
import com.typewritermc.realm.SURREALDB_EMBEDDED_VERSION
import com.typewritermc.realm.SURREALDB_SERVER_VERSION
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.withErrorSlug

private val DATABASE_CONNECT_FAILURE = ErrorSlug.of("realm-database-connect-failed")

interface RealmDatabaseProvider {
    context(_: MainSpanScope)
    fun connect(): Surreal
}

class DatabaseProvider(
    private val configuration: RealmDatabaseConfiguration,
) : RealmDatabaseProvider {
    context(_: MainSpanScope)
    override fun connect(): Surreal =
        childSpanBlocking("realm.database.connect") { child ->
            withErrorSlug(DATABASE_CONNECT_FAILURE) {
                child.annotate {
                    attribute("db.connection.type", configuration.endpoint.connectionType)
                    attribute("db.namespace", configuration.namespace)
                    attribute("db.database", configuration.database)
                }
                val db = Surreal()

                try {
                    requireSupportedEmbeddedEngine(configuration.endpoint)
                    db.connect(configuration.endpoint.connectionString)
                    val serverVersion = db.version()
                    requireSupportedDatabaseVersion(serverVersion, configuration.endpoint.expectedVersion)
                    child.annotate { attribute("db.version", serverVersion) }
                    db.authenticate(configuration)

                    db.useNs(configuration.namespace).useDb(configuration.database)
                    SchemaMigrator(db).migrate()
                    db
                } catch (failure: Throwable) {
                    runCatching(db::close).exceptionOrNull()?.let(failure::addSuppressed)
                    throw failure
                }
            }
        }
}

private fun Surreal.authenticate(configuration: RealmDatabaseConfiguration) {
    val authentication = configuration.authentication
    when (authentication) {
        DatabaseAuthentication.None -> {
        }

        is DatabaseAuthentication.Root -> {
            signin(RootCredential(authentication.username, authentication.password))
        }

        is DatabaseAuthentication.Namespace -> {
            signin(
                NamespaceCredential(
                    authentication.username,
                    authentication.password,
                    configuration.namespace,
                ),
            )
        }

        is DatabaseAuthentication.Database -> {
            signin(
                DatabaseCredential(
                    authentication.username,
                    authentication.password,
                    configuration.namespace,
                    configuration.database,
                ),
            )
        }

        is DatabaseAuthentication.Bearer -> {
            signin(BearerCredential(authentication.token))
        }
    }
}

internal fun requireSupportedEmbeddedEngine(endpoint: DatabaseEndpoint) {
    if (endpoint !is DatabaseEndpoint.Embedded.RocksDb) return
    throw UnsupportedDatabaseEngineException("RocksDB is not available in the configured SurrealDB Java SDK")
}

internal fun requireSupportedDatabaseVersion(
    version: String,
    expected: String,
) {
    val normalizedVersion = version.removePrefix("surrealdb-").substringBefore('+')
    if (normalizedVersion != expected) {
        throw UnsupportedDatabaseVersionException(
            expected = expected,
            actual = normalizedVersion,
        )
    }
}

private val DatabaseEndpoint.expectedVersion: String
    get() =
        when (this) {
            is DatabaseEndpoint.Remote -> SURREALDB_SERVER_VERSION
            is DatabaseEndpoint.Embedded -> SURREALDB_EMBEDDED_VERSION
        }

private val DatabaseEndpoint.connectionType: String
    get() =
        when (this) {
            is DatabaseEndpoint.Remote -> "remote"
            is DatabaseEndpoint.Embedded.Memory -> "embedded.memory"
            is DatabaseEndpoint.Embedded.SurrealKv -> "embedded.surrealkv"
            is DatabaseEndpoint.Embedded.RocksDb -> "embedded.rocksdb"
        }

internal class UnsupportedDatabaseVersionException(
    expected: String,
    actual: String,
) : IllegalStateException("Realm requires SurrealDB $expected but connected to $actual")

internal class UnsupportedDatabaseEngineException(
    message: String,
) : IllegalStateException(message)
