package com.typewritermc.realm.repository

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.elements.ElementTypeId
import com.typewritermc.elements.ElementValueMutator
import com.typewritermc.library.BookId
import com.typewritermc.library.PageId
import com.typewritermc.realm.repository.records.BookRecord
import com.typewritermc.realm.repository.records.PageRecord
import com.typewritermc.realm.repository.records.TagRecord
import com.typewritermc.realm.repository.utils.advanceCollaborationRevision
import com.typewritermc.realm.repository.utils.inTransaction
import com.typewritermc.realm.repository.utils.surrealId
import com.typewritermc.types.TypeGraph
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.Json
import java.security.MessageDigest

class SurrealAuthoringRepository(
    private val database: Surreal,
    private val pageDocuments: SurrealPageDocumentRepository,
    private val typeGraphs: () -> Map<ElementTypeId, TypeGraph>,
    private val valueMutator: ElementValueMutator = ElementValueMutator(),
) : AuthoringRepository {
    override suspend fun snapshot(scopes: Set<AuthoringSnapshotScope>): AuthoringSnapshotResult =
        database.inTransaction { transaction ->
            val sequence = transaction.currentCollaborationSequence()
            val slices = scopes.map { transaction.snapshot(it) }
            AuthoringSnapshotResult(sequence, slices)
        }

    override suspend fun apply(batch: AuthoringBatch): AuthoringBatchResult =
        try {
            database.inTransaction { transaction ->
                val requestHash = canonicalJson.encodeToString(batch).sha256()
                transaction.replay(batch.id, requestHash)?.let { return@inTransaction it }
                val mutation = AuthoringMutation(transaction, typeGraphs(), valueMutator)
                batch.operations.forEach(mutation::apply)
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

    private fun Transaction.snapshot(scope: AuthoringSnapshotScope): AuthoringSnapshotSlice =
        when (scope) {
            AuthoringSnapshotScope.Library -> {
                AuthoringSnapshotSlice.Library(
                    books =
                        BookRecord
                            .parseList(query("SELECT * FROM book ORDER BY id;").take(0))
                            .map(BookRecord::toBook),
                    tags = TagRecord.parseList(query("SELECT * FROM tag ORDER BY id;").take(0)).map(TagRecord::toTag),
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
            query("SELECT * FROM book WHERE id = \$id;", mapOf("id" to id.surrealId())).take(0),
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
