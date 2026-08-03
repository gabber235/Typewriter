package com.typewritermc.realm.repository

import com.surrealdb.Surreal
import com.typewritermc.realm.schema.SchemaMigrator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.services.libs.utils.asDeferredProvider
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey

internal class RepositoryFixture : AutoCloseable {
    private val telemetry = TelemetryTestHarness.create()
    private val database =
        Surreal().apply {
            connect("memory")
            useNs("realm_repository_test").useDb("realm_repository_test")
        }
    private val provider = database.asDeferredProvider()

    val books = SurrealBookRepository(provider)
    val pages = SurrealPageRepository(provider)
    val tags = SurrealTagRepository(provider)

    init {
        telemetry.telemetry.mainSpanBlocking(
            name = "test.realm.migrate",
            unhandledFailureSlug = ErrorSlug.of("test-realm-migrate-failed"),
        ) {
            SchemaMigrator(database).migrate()
        }
    }

    override fun close() {
        try {
            database.close()
        } finally {
            telemetry.close()
        }
    }
}

internal fun recordId(
    table: String,
    key: String,
) = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

internal fun <Value> RepositoryResult<Value>.successValue(): Value =
    when (this) {
        is RepositoryResult.Success -> value
        is RepositoryResult.DomainFailure -> error("Expected success but received $slug")
    }

internal fun RepositoryResult<*>.failureSlug(): String =
    when (this) {
        is RepositoryResult.Success -> error("Expected domain failure")
        is RepositoryResult.DomainFailure -> slug
    }
