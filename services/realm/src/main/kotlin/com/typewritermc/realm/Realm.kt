package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.utils.DeferredProvider
import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger

class Realm(
    val database: DeferredProvider<Surreal>
) {
    private val logger: KLogger = logger {}

    fun initialize() {
        logger.info { "Initializing Realm" }

        val db = Surreal()
        db.connect("surrealkv+versioned://database")
        db.useNs("typewriter").useDb("realm")

        SchemaMigrator(db).migrate()

        database.set(db)
        logger.info { "Realm initialized with database connection" }
    }

    fun shutdown() {
        logger.info { "Shutting down Realm" }
    }
}