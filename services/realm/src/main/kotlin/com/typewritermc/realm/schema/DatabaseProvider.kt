package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.surrealdb.signin.Root
import com.typewritermc.services.libs.telemetry.withSpan
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.Tracer
import java.net.InetSocketAddress
import java.net.Socket

private const val AUTO_DETECT_HOST = "localhost"
private const val AUTO_DETECT_PORT = 8235
private const val CONNECTION_TIMEOUT_MS = 500

enum class ConnectionMode {
    EMBEDDED,
    EXTERNAL,
}

class DatabaseProvider(
    private val url: String,
    private val username: String,
    private val password: String,
    private val namespace: String,
    private val database: String,
    private val tracer: Tracer,
) {

    fun connect(): Surreal = tracer.withSpan("realm.database.connect") { s ->
        val mode = with(s) { resolveConnectionMode() }
        s.setAttribute("db.mode", mode.name)

        val db = Surreal()

        when (mode) {
            ConnectionMode.EMBEDDED -> {
                db.connect("surrealkv+versioned://database")
                s.addEvent("Connected to embedded SurrealKV")
            }

            ConnectionMode.EXTERNAL -> {
                val effectiveUrl = url.ifBlank { "ws://$AUTO_DETECT_HOST:$AUTO_DETECT_PORT" }
                val effectiveUsername = username.ifBlank { "root" }
                val effectivePassword = password.ifBlank { "root" }
                db.connect(effectiveUrl)
                db.signin(Root(effectiveUsername, effectivePassword))
                s.setAttribute("db.url", effectiveUrl)
                s.addEvent("Connected to external SurrealDB")
            }
        }

        s.setAttribute("db.namespace", namespace)
        s.setAttribute("db.database", database)
        db.useNs(namespace).useDb(database)
        SchemaMigrator(db, tracer).migrate()

        db
    }

    context(span: Span)
    internal fun resolveConnectionMode(): ConnectionMode {
        if (url.isNotBlank()) {
            span.setAttribute("db.url", url)
            span.addEvent("Explicit URL provided, using external mode")
            return ConnectionMode.EXTERNAL
        }

        val probeTarget = "$AUTO_DETECT_HOST:$AUTO_DETECT_PORT"
        span.setAttribute("db.auto_detect.target", probeTarget)
        if (isPortOpen(AUTO_DETECT_HOST, AUTO_DETECT_PORT)) {
            span.addEvent("SurrealDB detected, using external mode")
            return ConnectionMode.EXTERNAL
        }

        span.addEvent("No SurrealDB detected, using embedded mode")
        return ConnectionMode.EMBEDDED
    }

    private fun isPortOpen(host: String, port: Int): Boolean {
        return try {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(host, port), CONNECTION_TIMEOUT_MS)
                true
            }
        } catch (_: Exception) {
            false
        }
    }
}
