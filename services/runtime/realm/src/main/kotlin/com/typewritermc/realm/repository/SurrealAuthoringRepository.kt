package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutator
import com.typewritermc.library.BookId
import com.typewritermc.library.PageId
import com.typewritermc.pages.PageAuthoringRuleContext
import com.typewritermc.pages.PageCatalog
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.search.SurrealAuthoringSearchRepository
import com.typewritermc.realm.repository.utils.advanceCollaborationRevision
import com.typewritermc.realm.repository.utils.inPreviewTransaction
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.types.TypeGraph
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

/**
 * Applies authoring changes and idempotency replay records in one Surreal transaction.
 *
 * Identical replay returns the stored result; reuse with a different payload fails. Applied batches advance
 * collaboration sequence, and relevant changes also advance compiler source revision. Domain rejection unwinds the
 * transaction before becoming a result.
 */
internal class SurrealAuthoringRepository(
    private val database: Surreal,
    private val pageDocuments: SurrealPageDocumentRepository,
    private val typeGraphs: () -> Map<ElementTypeId, TypeGraph>,
    private val search: SurrealAuthoringSearchRepository? = null,
    private val valueMutator: ElementValueMutator = ElementValueMutator(),
    private val pageCatalog: () -> PageCatalog? = { null },
) : AuthoringRepository {
    /**
     * Captures all requested scopes before the transaction commits, giving every slice one collaboration sequence.
     */
    override suspend fun snapshot(scopes: Set<AuthoringSnapshotScope>): AuthoringSnapshotResult =
        database.inTransaction { transaction ->
            val sequence = transaction.currentCollaborationSequence()
            val slices = scopes.map { transaction.snapshot(it) }
            AuthoringSnapshotResult(sequence, slices)
        }

    /**
     * Runs mutation, sequence advancement, compiler invalidation, and replay storage in one transaction.
     *
     * The compiler revision advances only for operations that change compiler inputs. The collaboration sequence
     * advances for every applied batch, including edits that affect editor state without changing compiled output.
     */
    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult =
        try {
            database.inTransaction { transaction ->
                val requestHash = canonicalJson.encodeToString(batch).sha256()
                transaction.replay(batch.id, requestHash)?.let { return@inTransaction it }
                val catalog = pageCatalog()?.takeIf { it.hasAuthoringRules() }
                val documentsBefore = catalog?.let { pageDocuments.loadAll(transaction) }.orEmpty()
                val mutation = AuthoringMutation(transaction, typeGraphs(), valueMutator)
                batch.operations.forEach(mutation::apply)
                catalog?.let { transaction.validatePageRules(it, documentsBefore) }
                search?.update(transaction, mutation.dirtyElementIds)
                val sequence = transaction.advanceCollaborationRevision()
                if (mutation.affectsCompilation) {
                    transaction.query("UPDATE ONLY authoring_head:current SET revision += 1;").take(0)
                }
                val result =
                    AuthoringBatchResult.Applied(
                        AuthoringChanged(
                            sequence = sequence,
                            batchId = batch.id,
                            changes = mutation.changes,
                            indirectlyAffectedResources = mutation.indirectResources(),
                        ),
                        affectsCompilation = mutation.affectsCompilation,
                    )
                transaction.store(batch.id, requestHash, result)
                result
            }
        } catch (rejected: AuthoringRejected) {
            rejected.result
        }

    override suspend fun preview(operations: List<AuthoringOperation>): AuthoringPreviewResult {
        require(operations.isNotEmpty()) { "Authoring previews must not be empty." }
        require(operations.map(AuthoringOperation::resource).distinct().size == operations.size) {
            "Authoring previews must contain at most one operation per resource."
        }
        return try {
            database.inPreviewTransaction { transaction ->
                val catalog = pageCatalog()?.takeIf { it.hasAuthoringRules() }
                val documentsBefore = catalog?.let { pageDocuments.loadAll(transaction) }.orEmpty()
                val mutation = AuthoringMutation(transaction, typeGraphs(), valueMutator)
                operations.forEach(mutation::apply)
                catalog?.let { transaction.validatePageRules(it, documentsBefore) }
                AuthoringPreviewResult.Valid(
                    mutation.changes.mapTo(linkedSetOf()) { it.resource } + mutation.indirectResources(),
                )
            }
        } catch (rejected: AuthoringRejected) {
            when (val result = rejected.result) {
                is AuthoringBatchResult.Conflict -> AuthoringPreviewResult.Conflict(result.conflicts)
                is AuthoringBatchResult.Invalid -> AuthoringPreviewResult.Invalid(result.diagnostics)
                is AuthoringBatchResult.Applied -> error("Applied results cannot reject an authoring preview.")
            }
        }
    }

    private fun Transaction.validatePageRules(
        catalog: PageCatalog,
        documentsBefore: Map<PageId, com.typewritermc.library.PageDocument>,
    ) {
        val documentsAfter = pageDocuments.loadAll(this)
        documentsAfter.forEach { (pageId, after) ->
            val before = documentsBefore[pageId]
            if (before == after) return@forEach
            val context = PageAuthoringRuleContext(before, after, documentsBefore, documentsAfter)
            catalog.authoringRules(after.page.kind).forEach { rule ->
                val violations =
                    runCatching { rule.validate(context) }.getOrElse { failure ->
                        throw AuthoringRejected(
                            AuthoringBatchResult.Invalid(
                                listOf(
                                    AuthoringDiagnostic(
                                        code = "page-rule-failed",
                                        message =
                                            "Page rule ${rule.reference.id.value} failed: " +
                                                (failure.message ?: failure::class.simpleName.orEmpty()),
                                        resource = AuthoringResourceRef.Page(pageId),
                                    ),
                                ),
                            ),
                        )
                    }
                if (violations.isNotEmpty()) {
                    throw AuthoringRejected(
                        AuthoringBatchResult.Invalid(
                            violations.map { violation ->
                                AuthoringDiagnostic(
                                    code = violation.code,
                                    message = violation.message,
                                    resource =
                                        violation.element?.let(AuthoringResourceRef::Element)
                                            ?: AuthoringResourceRef.Page(pageId),
                                )
                            },
                        ),
                    )
                }
            }
        }
    }

    private fun PageCatalog.hasAuthoringRules(): Boolean = entries.any { it.descriptor.authoringRules.isNotEmpty() }

    private fun Transaction.snapshot(scope: AuthoringSnapshotScope): AuthoringSnapshotSlice =
        when (scope) {
            AuthoringSnapshotScope.Library -> {
                AuthoringSnapshotSlice.Library(
                    books =
                        BookRecord
                            .parseList(
                                query(
                                    "SELECT *, (SELECT VALUE target FROM resource_reference " +
                                        "WHERE source = \$parent.id AND string::starts_with(slot, 'tags:')) AS tags " +
                                        "FROM book ORDER BY id;",
                                ).take(0),
                            ).map(BookRecord::toBook),
                    tags =
                        TagRecord
                            .parseList(
                                query(
                                    "SELECT *, (SELECT VALUE target FROM resource_reference " +
                                        "WHERE source = \$parent.id AND string::starts_with(slot, 'parents:')) " +
                                        "AS parent_tags FROM tag ORDER BY id;",
                                ).take(0),
                            ).map(TagRecord::toTag),
                )
            }

            is AuthoringSnapshotScope.Book -> {
                val book = loadBook(scope.id)
                val pages =
                    PageRecord
                        .parseList(
                            query(
                                "SELECT * FROM page WHERE book = \$book ORDER BY chapter, priority, id;",
                                mapOf("book" to scope.id.surrealId()),
                            ).take(0),
                        ).map(PageRecord::toPage)
                AuthoringSnapshotSlice.Book(scope.id, book, pages)
            }

            is AuthoringSnapshotScope.Page -> {
                AuthoringSnapshotSlice.Page(scope.id, pageDocuments.load(this, scope.id))
            }
        }
}

private fun Transaction.currentCollaborationSequence(): Long =
    query("SELECT VALUE revision FROM ONLY collaboration_head:current;").take(0).getLong()

private fun Transaction.loadBook(id: BookId) =
    BookRecord
        .parseList(
            query(
                "SELECT *, (SELECT VALUE target FROM resource_reference " +
                    "WHERE source = \$parent.id AND string::starts_with(slot, 'tags:')) AS tags " +
                    "FROM book WHERE id = \$id;",
                mapOf("id" to id.surrealId()),
            ).take(0),
        ).singleOrNull()
        ?.toBook()

private fun Transaction.replay(
    batchId: BatchId,
    requestHash: String,
): AuthoringBatchResult? {
    val value =
        query(
            "SELECT operation, request_hash, result FROM ONLY \$batch;",
            mapOf("batch" to RecordId("authoring_batch", batchId.value)),
        ).take(0)
    if (value.isNone || value.isNull) return null
    val stored = value.getObject()
    val hasDifferentOperation = stored.get("operation").getString() != AUTHORING_OPERATION
    val hasDifferentRequest = stored.get("request_hash").getString() != requestHash
    if (hasDifferentOperation || hasDifferentRequest) {
        return AuthoringBatchResult.Invalid(
            listOf(AuthoringDiagnostic("batch-id-reused", "Batch id was already used for another request.")),
        )
    }
    return canonicalJson.decodeFromString(AuthoringBatchResult.serializer(), stored.get("result").getString())
}

private fun Transaction.store(
    batchId: BatchId,
    requestHash: String,
    result: AuthoringBatchResult.Applied,
) {
    query(
        "CREATE ONLY \$batch CONTENT { operation: \$operation, request_hash: \$request_hash, result: \$result };",
        mapOf(
            "batch" to RecordId("authoring_batch", batchId.value),
            "operation" to AUTHORING_OPERATION,
            "request_hash" to requestHash,
            "result" to canonicalJson.encodeToString(AuthoringBatchResult.serializer(), result),
        ),
    ).take(0)
}

/**
 * Unwinds a transaction with a typed authoring rejection.
 *
 * The repository catches it outside the transaction so rejected batches cannot commit partial edits.
 */
internal class AuthoringRejected(
    val result: AuthoringBatchResult,
) : RuntimeException(null, null, false, false)

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") {
        "%02x".format(it.toInt() and 0xff)
    }

private const val AUTHORING_OPERATION = "apply_authoring_batch"

private val canonicalJson =
    Json {
        allowStructuredMapKeys = true
        encodeDefaults = true
        explicitNulls = true
        classDiscriminator = "_kind"
    }
