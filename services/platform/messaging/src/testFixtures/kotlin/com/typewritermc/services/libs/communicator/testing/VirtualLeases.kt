package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import com.typewritermc.services.libs.communicator.kv.LeaseCodec
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
import com.typewritermc.services.libs.communicator.kv.LeaseState
import com.typewritermc.services.libs.communicator.kv.LeaseTimings
import com.typewritermc.services.libs.communicator.kv.Leases
import com.typewritermc.services.libs.telemetry.testing.InMemoryTelemetry
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.runCurrent
import java.time.Clock
import java.time.Instant
import java.time.ZoneOffset
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.toJavaDuration

/**
 * Holders of leases on one memory [store] on the virtual time of [scope], with short timings: refresh every 300 ms,
 * live 2 s, a vacancy of 1 s, a retry after 100 ms, and a claim more than 1 s ahead reported. Every holder reaches the
 * store through its own [ScriptedBuckets], so a test decides the fate of each request, and reads time from its own
 * clock, which may run ahead of the others.
 */
class VirtualLeases(
    scope: TestScope,
    val timings: LeaseTimings = SHORT,
) {
    val store = KeyValueStore.Memory(scope)

    /** The telemetry every holder reports to. */
    val telemetry = InMemoryTelemetry()

    /** Creates the bucket holders lease their keys in, as its owner does; until then every holder finds it missing. */
    suspend fun createBucket() = store.createBucket(KeyValueBucketDeclaration(BUCKET, markerTtl = 1.seconds))

    /** Starts holder [id] with its own way to the store, its clock [ahead] of the store's. */
    suspend fun holder(
        id: String,
        ahead: Duration = Duration.ZERO,
    ): LeaseHolder {
        val buckets = store.connect()
        val clock = store.clock(ahead)
        val leases =
            Leases(
                holder = id,
                buckets = MutableStateFlow(buckets),
                bucketName = BUCKET,
                codec = TextLeaseCodec,
                timings = timings,
                parent = store.scope,
                clock = clock,
                openTelemetry = telemetry.openTelemetry,
            )
        return LeaseHolder(id, leases, buckets, clock)
    }

    /** The live entry of [key], or null when there is none or no holder could read it. */
    suspend fun entry(key: String): LeaseEntry<String, String>? = store.read(key, BUCKET)?.let(TextLeaseCodec::decode)

    /** Writes [value] under [key] with [ttl], as a writer outside the holders would. */
    suspend fun write(
        key: String,
        value: ByteArray,
        ttl: Duration,
    ) = store.write(key, value, ttl, BUCKET)

    companion object {
        val SHORT: LeaseTimings =
            LeaseTimings(refresh = 300.milliseconds, ttl = 2.seconds, vacancy = 1.seconds, retry = 100.milliseconds, skew = 1.seconds)

        /** The bucket holders lease their keys in. */
        const val BUCKET: String = "leases"
    }
}

/** One holder of a [VirtualLeases]; [buckets] is its way to the store and [clock] its own clock. */
class LeaseHolder(
    val id: String,
    val leases: Leases<String, String>,
    val buckets: ScriptedBuckets,
    private val clock: Clock,
) {
    /** Claims [key] now on this holder's clock, keeping the value the key kept before, else [value]. */
    fun claim(
        key: String,
        value: String = "first",
    ) = leases.claim(key, clock.instant()) { previous, _ -> previous ?: value }

    fun release(key: String) = leases.release(key)

    /** The holder stops as a crash would: no further write. */
    fun crash() = leases.close()
}

/** A lease entry as text, `held|holder|claimed|value` or `vacant|value`; anything else reads as no entry. */
object TextLeaseCodec : LeaseCodec<String, String> {
    override fun encode(entry: LeaseEntry<String, String>): ByteArray =
        when (val state = entry.state) {
            is LeaseState.Held -> "held|${state.holder}|${state.claimed}|${entry.value}"
            LeaseState.Vacant -> "vacant|${entry.value}"
        }.encodeToByteArray()

    override fun decode(bytes: ByteArray): LeaseEntry<String, String>? {
        val parts = bytes.decodeToString().split('|')
        return when {
            parts.size == 4 && parts[0] == "held" -> {
                val claimed = runCatching { Instant.parse(parts[2]) }.getOrNull() ?: return null
                LeaseEntry(LeaseState.Held(parts[1], claimed), parts[3])
            }

            parts.size == 2 && parts[0] == "vacant" -> {
                LeaseEntry(LeaseState.Vacant, parts[1])
            }

            else -> {
                null
            }
        }
    }
}
