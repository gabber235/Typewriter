package com.typewritermc.realm.outbox

import com.surrealdb.RecordId
import com.surrealdb.Surreal
import com.surrealdb.Transaction
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.EncodedPublication
import com.typewritermc.services.libs.communicator.transport.Payload
import kotlinx.coroutines.channels.Channel
import java.time.Instant

typealias OutboxEvent = EncodedPublication

data class PendingOutboxEvent(
    val id: RecordId,
    val event: OutboxEvent,
    val attempts: Long,
    val availableAt: Instant,
)

interface RealmOutbox {
    fun enqueue(
        transaction: Transaction,
        events: List<OutboxEvent>,
    )

    suspend fun pending(limit: Int): List<PendingOutboxEvent>

    suspend fun markPublished(
        id: RecordId,
        publishedAt: Instant,
    )

    suspend fun markFailed(
        id: RecordId,
        availableAt: Instant,
    )

    fun signalPending()

    suspend fun awaitPending()
}

class SurrealRealmOutbox(
    private val database: Surreal,
) : RealmOutbox {
    private val pendingSignal = Channel<Unit>(Channel.CONFLATED)

    override fun enqueue(
        transaction: Transaction,
        events: List<OutboxEvent>,
    ) {
        if (events.isEmpty()) return
        transaction
            .query(
                $$"""
            FOR $event IN $events {
                CREATE realm_outbox CONTENT {
                    subject: $event.subject,
                    payload: $event.payload,
                    state: "pending",
                    attempts: 0,
                    available_at: time::now(),
                    created_at: time::now(),
                    published_at: NONE,
                };
            };
                """.trimIndent(),
                mapOf(
                    "events" to
                        events.map { event ->
                            mapOf(
                                "subject" to event.address.value,
                                "payload" to event.payload.toByteArray(),
                            )
                        },
                ),
            ).take(0)
    }

    override suspend fun pending(limit: Int): List<PendingOutboxEvent> {
        require(limit > 0) { "Outbox batch limit must be positive" }
        val result =
            database
                .query(
                    $$"""
                    SELECT id, subject, payload, attempts, available_at, created_at
                    FROM realm_outbox
                    WHERE state = "pending"
                    ORDER BY created_at, id
                    LIMIT $limit
                    """.trimIndent(),
                    mapOf("limit" to limit),
                ).take(0)
        return result.array.map { it.get(OutboxRecord::class.java).toPending() }
    }

    override suspend fun markPublished(
        id: RecordId,
        publishedAt: Instant,
    ) {
        database
            .query(
                $$"""
                UPDATE $id SET
                    state = "published",
                    published_at = $published_at
                """.trimIndent(),
                mapOf("id" to id, "published_at" to publishedAt),
            ).take(0)
    }

    override suspend fun markFailed(
        id: RecordId,
        availableAt: Instant,
    ) {
        database
            .query(
                $$"""
                UPDATE $id SET
                    attempts += 1,
                    available_at = $available_at
                """.trimIndent(),
                mapOf("id" to id, "available_at" to availableAt),
            ).take(0)
    }

    override fun signalPending() {
        pendingSignal.trySend(Unit).getOrThrow()
    }

    override suspend fun awaitPending() {
        pendingSignal.receive()
    }
}

internal data class OutboxRecord(
    val id: RecordId = RecordId("realm_outbox", ""),
    val subject: String = "",
    val payload: List<Long> = emptyList(),
    val attempts: Long = 0,
    val available_at: java.time.ZonedDateTime = java.time.ZonedDateTime.parse("1970-01-01T00:00:00Z"),
) {
    fun toPending() =
        PendingOutboxEvent(
            id,
            EncodedPublication(
                MessageAddress.of(subject),
                Payload.copyOf(payload.map(Long::toByte).toByteArray()),
            ),
            attempts,
            available_at.toInstant(),
        )
}
