package com.typewritermc.realm.schema

import com.surrealdb.Surreal
import io.github.oshai.kotlinlogging.KotlinLogging

private val logger = KotlinLogging.logger {}

class SchemaMigrator(private val db: Surreal) {

    private val patchRunner = PatchRunner(db)

    fun migrate() {
        logger.info { "Starting schema migration..." }

        applySchema()
        patchRunner.runPendingPatches()

        logger.info { "Schema migration complete" }
    }

    private fun applySchema() {
        val schema = loadResource("schema/realm.surql")
        if (schema.isBlank()) {
            logger.warn { "Empty schema file, skipping schema application" }
            return
        }

        logger.info { "Applying schema..." }
        db.query(schema)
        logger.info { "Schema applied successfully" }
    }

    private fun loadResource(path: String): String {
        return this::class.java.classLoader
            .getResourceAsStream(path)
            ?.bufferedReader()
            ?.readText()
            ?: throw IllegalStateException("Resource not found: $path")
    }
}
