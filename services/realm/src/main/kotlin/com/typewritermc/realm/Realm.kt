package com.typewritermc.realm

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.DatabaseProvider
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.utils.DeferredProvider

class Realm(
    val database: DeferredProvider<Surreal>,
    private val databaseProvider: DatabaseProvider,
    private val telemetry: ServiceTelemetry,
) {
    context(main: MainSpanScope)
    fun initialize(): Unit = childSpanBlocking("realm.initialize") { child ->
        child.annotate { dbOperationName("connect") }
        val db = databaseProvider.connect()
        database.set(db)
    }

    fun shutdown(): Unit = telemetry.mainSpanBlocking(
        name = "realm.shutdown",
        unhandledFailureSlug = ErrorSlug.of("realm-shutdown-failed"),
    ) { main ->
        main.annotate { operationOutcome("completed") }
    }
}
