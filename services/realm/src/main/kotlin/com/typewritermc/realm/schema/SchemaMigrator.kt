package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import com.typewritermc.services.libs.telemetry.withSpan
import io.opentelemetry.api.trace.Tracer

class SchemaMigrator(
    private val db: Surreal,
    private val tracer: Tracer,
) {

    private val patchRunner = PatchRunner(db, tracer)

    fun migrate() = tracer.withSpan("realm.migrate") { s ->
        s.addEvent("Starting schema migration")

        applySchema(s)
        patchRunner.runPendingPatches(s)

        s.addEvent("Schema migration complete")
    }

    private fun applySchema(s: io.opentelemetry.api.trace.Span) {
        val schema = loadResource("schema/realm.surql")
        if (schema.isBlank()) {
            s.addEvent("Empty schema file, skipping schema application")
            return
        }

        s.addEvent("Applying schema")
        db.query(schema)
        s.addEvent("Schema applied successfully")
    }

    private fun loadResource(path: String): String {
        return this::class.java.classLoader
            .getResourceAsStream(path)
            ?.use { it.bufferedReader().readText() }
            ?: throw IllegalStateException("Resource not found: $path")
    }
}
