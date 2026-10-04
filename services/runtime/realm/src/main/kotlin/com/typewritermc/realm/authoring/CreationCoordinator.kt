package com.typewritermc.realm.authoring

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.typewritermc.authoring.InitializationRequest
import com.typewritermc.authoring.InitializationRequestId
import com.typewritermc.authoring.InitializationRuntime
import com.typewritermc.authoring.PreparedCreation
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.realm.repository.utils.inTransaction
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.serialization.decodeFromString
import kotlinx.serialization.encodeToString
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.security.MessageDigest
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

data class CreationReceipt(
    val request: InitializationRequestId,
    val intentDigest: String,
    val catalog: CatalogGeneration,
    val result: PreparedCreation,
)

internal interface CreationReceiptStore {
    fun completed(
        id: InitializationRequestId,
        intentDigest: String,
    ): PreparedCreation?

    fun save(receipt: CreationReceipt): PreparedCreation
}

internal fun interface CreationEvaluator {
    suspend fun evaluate(
        request: InitializationRequest,
        catalog: SnapshotCatalogLease,
    ): PreparedCreation
}

internal class CreationCatalogChanged(
    val actual: CatalogGeneration,
) : IllegalStateException("The active catalog changed to ${actual.value}.")

/** Captures dynamic initialization once per durable request result. */
internal class CreationCoordinator(
    private val catalog: () -> SnapshotCatalogLease,
    private val receipts: CreationReceiptStore,
    private val evaluator: CreationEvaluator,
) : InitializationRuntime {
    private val flights = ConcurrentHashMap<InitializationRequestId, Flight>()

    override suspend fun prepare(request: InitializationRequest): PreparedCreation {
        val digest = request.canonicalDigest()
        val flight =
            flights.compute(request.id) { _, current ->
                (current ?: Flight()).also { it.callers.incrementAndGet() }
            } ?: error("Creation flight allocation failed.")
        return try {
            flight.mutex.withLock {
                receipts.completed(request.id, digest)?.let { return@withLock it }
                val active = catalog()
                try {
                    if (request.catalog != active.generation) throw CreationCatalogChanged(active.generation)
                    val prepared = evaluator.evaluate(request, active)
                    receipts.save(CreationReceipt(request.id, digest, request.catalog, prepared))
                } finally {
                    active.close()
                }
            }
        } finally {
            flights.compute(request.id) { _, current ->
                if (current !== flight) current else flight.takeIf { it.callers.decrementAndGet() != 0 }
            }
        }
    }

    private class Flight(
        val mutex: Mutex = Mutex(),
        val callers: AtomicInteger = AtomicInteger(),
    )
}

internal class SurrealCreationReceiptStore(
    private val database: Surreal,
) : CreationReceiptStore {
    override fun completed(
        id: InitializationRequestId,
        intentDigest: String,
    ): PreparedCreation? {
        val value =
            database
                .query(
                    "SELECT intent_digest, result FROM ONLY \$receipt;",
                    mapOf("receipt" to RecordId("creation_receipt", id.value)),
                ).take(0)
        if (value.isNull || value.isNone) return null
        val stored = value.getObject()
        require(stored.get("intent_digest").getString() == intentDigest) {
            "Initialization request id ${id.value} was already used for another intent."
        }
        return authoringStorageJson.decodeFromString(stored.get("result").getString())
    }

    override fun save(receipt: CreationReceipt): PreparedCreation =
        try {
            database.inTransaction { transaction ->
                val existing =
                    transaction
                        .query(
                            "SELECT intent_digest, result FROM ONLY \$receipt;",
                            mapOf("receipt" to RecordId("creation_receipt", receipt.request.value)),
                        ).take(0)
                if (!existing.isNull && !existing.isNone) {
                    val stored = existing.getObject()
                    require(stored.get("intent_digest").getString() == receipt.intentDigest) {
                        "Initialization request id ${receipt.request.value} was already used for another intent."
                    }
                    return@inTransaction authoringStorageJson.decodeFromString(stored.get("result").getString())
                }
                transaction
                    .query(
                        "CREATE ONLY \$receipt CONTENT { intent_digest: \$digest, catalog: \$catalog, result: \$result };",
                        mapOf(
                            "receipt" to RecordId("creation_receipt", receipt.request.value),
                            "digest" to receipt.intentDigest,
                            "catalog" to receipt.catalog.value,
                            "result" to authoringStorageJson.encodeToString(receipt.result),
                        ),
                    ).take(0)
                receipt.result
            }
        } catch (failure: Throwable) {
            completed(receipt.request, receipt.intentDigest) ?: throw failure
        }
}

private fun InitializationRequest.canonicalDigest(): String =
    authoringStorageJson
        .encodeToJsonElement(
            InitializationRequest.serializer(),
            copy(id = InitializationRequestId("canonical")),
        ).canonical()
        .toString()
        .sha256()

private fun JsonElement.canonical(): JsonElement =
    when (this) {
        is JsonObject -> JsonObject(entries.sortedBy { it.key }.associate { it.key to it.value.canonical() })
        is JsonArray -> JsonArray(map(JsonElement::canonical))
        is JsonPrimitive -> this
    }

private fun String.sha256(): String =
    MessageDigest.getInstance("SHA-256").digest(toByteArray()).joinToString("") { byte -> "%02x".format(byte.toInt() and 0xff) }
