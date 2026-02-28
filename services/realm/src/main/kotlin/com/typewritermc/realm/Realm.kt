package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.services.libs.telemetry.withSpan
import com.typewritermc.services.libs.utils.DeferredProvider
import io.opentelemetry.api.trace.Tracer

class Realm(
    val database: DeferredProvider<Surreal>,
    private val databaseProvider: DatabaseProvider,
    private val tracer: Tracer,
) {

    fun initialize(): Unit = tracer.withSpan("realm.initialize") { s ->
        s.addEvent("Initializing Realm")

        val db = databaseProvider.connect()
        database.set(db)

        s.addEvent("Realm initialized")
    }

    fun shutdown(): Unit = tracer.withSpan("realm.shutdown") { s ->
        s.addEvent("Shutting down Realm")
    }
}
