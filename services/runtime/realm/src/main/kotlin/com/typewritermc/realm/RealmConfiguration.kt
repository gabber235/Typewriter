package com.typewritermc.realm

import com.typewritermc.realm.storage.DatabaseAuthentication
import com.typewritermc.realm.storage.DatabaseEndpoint
import com.typewritermc.realm.storage.RealmDatabaseConfiguration
import java.net.URI
import java.nio.file.Path

/**
 * Collects resolved diagnostic and database policy before Realm composition.
 *
 * The settings adapter defaults unknown diagnostic levels to WARN; database configuration performs its own
 * validation.
 */
internal data class RealmApplicationConfiguration(
    val diagnosticLevel: RealmDiagnosticLevel,
    val database: RealmDatabaseConfiguration,
)

internal enum class RealmDiagnosticLevel {
    ALL,
    TRACE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
    OFF,
}

internal fun RealmSettings.applicationConfiguration(): RealmApplicationConfiguration =
    RealmApplicationConfiguration(
        diagnosticLevel =
            get("TYPEWRITER_DIAGNOSTIC_LEVEL")
                ?.uppercase()
                ?.let { value -> RealmDiagnosticLevel.entries.firstOrNull { it.name == value } }
                ?: RealmDiagnosticLevel.WARN,
        database = databaseConfiguration(),
    )

internal fun RealmSettings.databaseConfiguration(): RealmDatabaseConfiguration {
    val endpoint = databaseEndpoint()
    val authentication = databaseAuthentication()
    return RealmDatabaseConfiguration(
        endpoint = endpoint,
        authentication = authentication,
        namespace = get("REALM_DB_NAMESPACE", "typewriter")!!,
        database = get("REALM_DB_DATABASE", "realm")!!,
        expectedVersion =
            when (endpoint) {
                is DatabaseEndpoint.Remote -> SURREALDB_SERVER_VERSION
                is DatabaseEndpoint.Embedded -> SURREALDB_EMBEDDED_VERSION
            },
    )
}

private fun RealmSettings.databaseEndpoint(): DatabaseEndpoint =
    when (get("REALM_DB_ENDPOINT_TYPE", "embedded")!!.lowercase()) {
        "embedded" -> embeddedDatabaseEndpoint()
        "remote" -> DatabaseEndpoint.Remote(URI(getRequired("REALM_DB_URL")))
        else -> error("Unknown Realm database endpoint type")
    }

private fun RealmSettings.embeddedDatabaseEndpoint(): DatabaseEndpoint.Embedded {
    val retention = get("REALM_DB_RETENTION")
    return when (get("REALM_DB_ENGINE", "surrealkv")!!.lowercase()) {
        "memory" -> DatabaseEndpoint.Embedded.Memory(retention)
        "surrealkv" -> DatabaseEndpoint.Embedded.SurrealKv(Path.of(get("REALM_DB_PATH", "database/realm")!!), retention)
        "rocksdb" -> DatabaseEndpoint.Embedded.RocksDb(Path.of(get("REALM_DB_PATH", "database/realm")!!), retention)
        else -> error("Unknown embedded Realm database engine")
    }
}

private fun RealmSettings.databaseAuthentication(): DatabaseAuthentication =
    when (get("REALM_DB_AUTHENTICATION", "none")!!.lowercase()) {
        "none" -> {
            DatabaseAuthentication.None
        }

        "root" -> {
            DatabaseAuthentication.Root(getRequired("REALM_DB_USERNAME"), getRequired("REALM_DB_PASSWORD"))
        }

        "namespace" -> {
            DatabaseAuthentication.Namespace(getRequired("REALM_DB_USERNAME"), getRequired("REALM_DB_PASSWORD"))
        }

        "database" -> {
            DatabaseAuthentication.Database(getRequired("REALM_DB_USERNAME"), getRequired("REALM_DB_PASSWORD"))
        }

        "bearer" -> {
            DatabaseAuthentication.Bearer(getRequired("REALM_DB_TOKEN"))
        }

        else -> {
            error("Unknown Realm database authentication type")
        }
    }

private fun RealmSettings.getRequired(name: String): String = requireNotNull(get(name)) { "Realm setting $name must be configured" }
