package com.typewritermc.realm.compiler

import com.surrealdb.Surreal
import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.Diagnostic
import com.typewritermc.engine.CompilationRoot
import com.typewritermc.engine.PublishedContent
import kotlinx.serialization.builtins.ListSerializer

sealed interface RegisteredCompiledState {
    data object NotCompiled : RegisteredCompiledState

    data class Active(
        val publication: PublicationId,
    ) : RegisteredCompiledState
}

data class PublicationReport(
    val id: PublicationId,
    val state: PublicationState,
    val findings: List<Diagnostic>,
)

interface PublicationResults {
    suspend fun selected(): PublishedContent?

    suspend fun latestReport(): PublicationReport?

    suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState>
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
            ?.let { publicationsCodec.decode(PublishedContent.serializer(), it) }
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
        val findings = publicationsCodec.decode(ListSerializer(Diagnostic.serializer()), row.get("findings"))
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

    override suspend fun states(roots: Set<CompilationRoot>): Map<CompilationRoot, RegisteredCompiledState> {
        val result = selected()
        val available = result?.outputs?.mapTo(hashSetOf()) { it.reference.root }.orEmpty()
        return roots.associateWith { root ->
            if (root in
                available
            ) {
                RegisteredCompiledState.Active(requireNotNull(result).publication)
            } else {
                RegisteredCompiledState.NotCompiled
            }
        }
    }
}
