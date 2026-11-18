package com.typewritermc.services.libs.communicator.kv

import com.typewritermc.services.libs.communicator.nats.NatsConnection
import io.natskt.jetstream.api.JetStreamApiException
import io.natskt.jetstream.api.KvKeyNotFoundException
import io.natskt.jetstream.api.kv.KeyValueOperation
import kotlinx.coroutines.CancellationException
import kotlin.time.Duration
import io.natskt.jetstream.api.kv.KeyValueBucket as NatsBucket

/**
 * The key value buckets of one NATS connection, through JetStream. A key whose time to live ran out reads as absent
 * although the broker keeps its expiry marker for a while; a create over such a marker succeeds.
 */
class NatsKeyValueBuckets(
    private val connection: NatsConnection,
) : KeyValueBuckets {
    override suspend fun open(name: String): KeyValueOpen =
        attempt {
            val jetStream = connection.jetStream() ?: return@attempt KeyValueOpen.Failed(IllegalStateException("NATS is not connected"))
            try {
                KeyValueOpen.Opened(JetStreamBucket(jetStream.keyValueManager.get(name)))
            } catch (missing: JetStreamApiException) {
                if (missing.error?.errCode == STREAM_NOT_FOUND) KeyValueOpen.Missing else throw missing
            }
        }

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen =
        when (val opened = open(bucket.name)) {
            KeyValueOpen.Missing ->
                attempt {
                    val jetStream = connection.jetStream() ?: return@attempt KeyValueOpen.Failed(IllegalStateException("NATS is not connected"))
                    val created =
                        jetStream.keyValueManager.create {
                            name = bucket.name
                            history = 1
                            limitMarkerTtl = bucket.markerTtl
                        }
                    KeyValueOpen.Opened(JetStreamBucket(created))
                }
            else -> opened
        }

    private inline fun attempt(block: () -> KeyValueOpen): KeyValueOpen =
        try {
            block()
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (failure: Exception) {
            KeyValueOpen.Failed(failure)
        }

    private class JetStreamBucket(
        private val bucket: NatsBucket,
    ) : KeyValueBucket {
        override suspend fun get(key: String): KeyValueRead =
            try {
                val entry = bucket.get(key)
                when {
                    // natskt 0.9.1 returns the broker's not found reply to a get of a missing key as an entry of
                    // revision 0, which no stored entry has. Remove once natskt's key value get fails with not found.
                    entry.revision == 0uL -> KeyValueRead.Absent
                    else -> entry.read()
                }
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (_: KvKeyNotFoundException) {
                KeyValueRead.Absent
            } catch (failure: JetStreamApiException) {
                if (failure.error?.code == NOT_FOUND) KeyValueRead.Absent else KeyValueRead.Failed(failure)
            } catch (failure: Exception) {
                KeyValueRead.Failed(failure)
            }

        /** A delete marker or the marker of an expired key reads as absent. */
        private fun io.natskt.jetstream.api.kv.KeyValueEntry.read(): KeyValueRead =
            when (operation) {
                KeyValueOperation.Delete, KeyValueOperation.Purge -> KeyValueRead.Absent
                else -> KeyValueRead.Found(KeyValueEntry(key, value, revision.toLong()))
            }

        override suspend fun create(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ): KeyValueWrite = write { bucket.create(key, value, ttl) }

        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ): KeyValueWrite = write { bucket.update(key, value, revision.toULong(), ttl) }

        override suspend fun keys(filter: String): KeyValueKeys =
            try {
                KeyValueKeys.Listed(bucket.keys(filter))
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Exception) {
                KeyValueKeys.Failed(failure)
            }

        private inline fun write(block: () -> ULong): KeyValueWrite =
            try {
                KeyValueWrite.Written(block().toLong())
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: JetStreamApiException) {
                if (failure.error?.errCode == WRONG_LAST_SEQUENCE) KeyValueWrite.Conflict else KeyValueWrite.Failed(failure)
            } catch (failure: Exception) {
                KeyValueWrite.Failed(failure)
            }
    }

    private companion object {
        /** JetStream's error code for a write whose expected last revision is not the key's. */
        const val WRONG_LAST_SEQUENCE = 10071

        /** JetStream's error code for a stream, and so a bucket, that does not exist. */
        const val STREAM_NOT_FOUND = 10059

        const val NOT_FOUND = 404
    }
}
