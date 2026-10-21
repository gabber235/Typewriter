package com.typewritermc.realm.compiler

import build.skir.Serializers
import com.surrealdb.Surreal
import com.typewritermc.engine.requireValid
import com.typewritermc.realm.repository.utils.decodeSkir
import com.typewritermc.types.requireValid
import skirout.editor.v1.compiled_content.PublishedContent
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.type_catalog.PublicationId

data class PublicationReport(
    val id: PublicationId,
    val state: PublicationState,
    val findings: List<Diagnostic>,
)

/** Reads the Realm selected runtime descriptor separately from the latest durable publication attempt report. */
interface PublicationResults {
    suspend fun selected(): PublishedContent?

    suspend fun latestReport(): PublicationReport?
}

/** Published descriptors and attempt findings are native objects in the attempt record. */
class SurrealRegisteredCompiledContentRepository(
    private val database: Surreal,
) : PublicationResults {
    override suspend fun selected(): PublishedContent? {
        val rows =
            database
                .query(
                    "SELECT result FROM publication_attempt WHERE selected = true AND state = 'complete';",
                ).take(0)
                .getArray()
                .toList()
        check(rows.size <= 1) { "More than one publication is selected" }
        return rows
            .singleOrNull()
            ?.getObject()
            ?.get("result")
            ?.let { decodeSkir(PublishedContent.serializer, it).requireValid() }
    }

    override suspend fun latestReport(): PublicationReport? {
        val row =
            database
                .query(
                    "SELECT id, state, findings, started_at FROM publication_attempt ORDER BY started_at DESC, id DESC LIMIT 1;",
                ).take(0)
                .getArray()
                .firstOrNull()
                ?.getObject()
                ?: return null
        val findings = decodeSkir(Serializers.list(Diagnostic.serializer), row.get("findings")).map { it.requireValid() }
        val state =
            when (row.get("state").getString()) {
                "checking" -> PublicationState.Checking
                "compiling" -> PublicationState.Compiling
                "activating" -> PublicationState.Activating
                "complete" -> PublicationState.Complete
                "blocked" -> PublicationState.Blocked(findings)
                "interrupted" -> PublicationState.Interrupted
                else -> error("Unknown publication state")
            }
        return PublicationReport(
            PublicationId(
                value =
                    row
                        .get("id")
                        .getRecordId()
                        .toString()
                        .substringAfter(':'),
            ),
            state,
            findings,
        )
    }
}
