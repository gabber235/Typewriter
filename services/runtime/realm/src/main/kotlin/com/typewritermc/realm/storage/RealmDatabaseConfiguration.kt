package com.typewritermc.realm.storage

import java.net.URI
import java.nio.file.Path

/**
 * Selects a Realm database endpoint, authentication scope, namespace, and database.
 *
 * Embedded storage requires no authentication. Nonblank names and endpoint syntax are checked here, while
 * supported engine and exact version checks occur on connection against [expectedVersion].
 */
data class RealmDatabaseConfiguration(
    val endpoint: DatabaseEndpoint,
    val authentication: DatabaseAuthentication,
    val namespace: String,
    val database: String,
    /** The SurrealDB version this Realm build was tested against; a server reporting another one is refused. */
    val expectedVersion: String,
) {
    init {
        require(namespace.isNotBlank()) { "Database namespace must not be blank" }
        require(database.isNotBlank()) { "Database name must not be blank" }
        require(endpoint !is DatabaseEndpoint.Embedded || authentication == DatabaseAuthentication.None) {
            "Embedded databases do not support authentication"
        }
    }
}

/**
 * Separates remote database URLs from embedded engine configuration.
 *
 * Embedded file paths are resolved against runtime state by composition. Representing an endpoint does not
 * guarantee the pinned SDK supports that engine.
 */
sealed interface DatabaseEndpoint {
    val connectionString: String

    data class Remote(
        val uri: URI,
    ) : DatabaseEndpoint {
        init {
            require(uri.scheme in REMOTE_DATABASE_SCHEMES) {
                "Remote database URL must use HTTP or WebSocket"
            }
            require(uri.host != null) { "Remote database URL must include a host" }
            require(uri.userInfo == null) { "Remote database URL must not contain credentials" }
        }

        override val connectionString: String = uri.toString()
    }

    sealed interface Embedded : DatabaseEndpoint {
        val retention: String?

        data class Memory(
            override val retention: String? = null,
        ) : Embedded {
            override val connectionString: String = embeddedConnectionString("mem", null, retention)
        }

        data class SurrealKv(
            val path: Path,
            override val retention: String? = null,
        ) : Embedded {
            override val connectionString: String = embeddedConnectionString("surrealkv", path, retention)
        }

        data class RocksDb(
            val path: Path,
            override val retention: String? = null,
        ) : Embedded {
            override val connectionString: String = embeddedConnectionString("rocksdb", path, retention)
        }
    }
}

/**
 * Selects root, namespace, database, bearer, or unauthenticated connection credentials.
 *
 * Secret rendering is redacted, but authentication fields remain plaintext in memory and are used only by the
 * connection boundary.
 */
sealed interface DatabaseAuthentication {
    data object None : DatabaseAuthentication

    data class Root(
        val username: String,
        val password: String,
    ) : DatabaseAuthentication {
        init {
            requireCredentials(username, password)
        }

        override fun toString(): String = "Root(username=$username, password=[redacted])"
    }

    data class Namespace(
        val username: String,
        val password: String,
    ) : DatabaseAuthentication {
        init {
            requireCredentials(username, password)
        }

        override fun toString(): String = "Namespace(username=$username, password=[redacted])"
    }

    data class Database(
        val username: String,
        val password: String,
    ) : DatabaseAuthentication {
        init {
            requireCredentials(username, password)
        }

        override fun toString(): String = "Database(username=$username, password=[redacted])"
    }

    data class Bearer(
        val token: String,
    ) : DatabaseAuthentication {
        init {
            require(token.isNotBlank()) { "Database bearer token must not be blank" }
        }

        override fun toString(): String = "Bearer(token=[redacted])"
    }
}

private fun embeddedConnectionString(
    scheme: String,
    path: Path?,
    retention: String?,
): String {
    require(retention == null || retention.isNotBlank()) { "Database retention must not be blank" }
    val query =
        buildList {
            add("versioned=true")
            retention?.let { add("retention=${encodeUriComponent(it)}") }
        }.joinToString("&")
    if (path == null) return "$scheme://?$query"

    val normalizedPath = path.normalize().toString().replace('\\', '/')
    require(normalizedPath.isNotBlank()) { "Embedded database path must not be blank" }
    val encodedPath = URI(null, null, normalizedPath, null).rawPath
    return "$scheme://$encodedPath?$query"
}

private fun encodeUriComponent(value: String): String = URI(null, null, value, null).rawPath

private fun requireCredentials(
    username: String,
    password: String,
) {
    require(username.isNotBlank()) { "Database username must not be blank" }
    require(password.isNotBlank()) { "Database password must not be blank" }
}

private val REMOTE_DATABASE_SCHEMES = setOf("http", "https", "ws", "wss")
