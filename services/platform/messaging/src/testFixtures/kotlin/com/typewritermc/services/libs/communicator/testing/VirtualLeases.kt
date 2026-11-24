package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import com.typewritermc.services.libs.communicator.kv.LeaseCodec
import com.typewritermc.services.libs.communicator.kv.LeaseEntry
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
 * One key value store in memory on the virtual time of [scope], for the holders a test starts on it. Every holder
 * reaches the store through its own [ScriptedBuckets], so a test decides the fate of each request, and reads time from
 * its own clock, which may run ahead of the others. Nothing waits on wall clock time: [advance] moves every clock,
 * every refresh and every expiry together, and [settle] runs what is due now.
 */
class VirtualKeyValue(
    private val scope: TestScope,
) {
    /** The store every holder reaches. */
    val store: KeyValueBuckets = MemoryKeyValueBuckets { scope.testScheduler.currentTime.milliseconds }

    /** The telemetry every holder reports to. */
    val telemetry = InMemoryTelemetry()

    /** Creates [name], as its owner does; until then every holder finds it missing. */
    suspend fun createBucket(name: String = BUCKET) {
        check(store.ensure(KeyValueBucketDeclaration(name, markerTtl = 1.seconds)) is KeyValueOpen.Opened)
    }

    /** A clock on the store's virtual time, [ahead] of the store's own. */
    fun clock(ahead: Duration = Duration.ZERO): Clock = VirtualClock(ahead)

    /** The raw value under [key] in [bucket], or null when no live entry is there. */
    suspend fun read(
        key: String,
        bucket: String = BUCKET,
    ): ByteArray? {
        val opened = store.open(bucket) as? KeyValueOpen.Opened ?: return null
        return (opened.bucket.get(key) as? KeyValueRead.Found)?.entry?.value
    }

    /** Writes [value] under [key] of [bucket] with [ttl], as a writer outside the holders would. */
    suspend fun write(
        key: String,
        value: ByteArray,
        ttl: Duration,
        bucket: String = BUCKET,
    ) {
        val opened = store.open(bucket) as KeyValueOpen.Opened
        check(opened.bucket.create(key, value, ttl) is KeyValueWrite.Written)
    }

    /** Lets [time] pass for every holder and runs everything due by then. */
    fun advance(time: Duration) {
        scope.testScheduler.advanceTimeBy(time.inWholeMilliseconds)
        scope.runCurrent()
    }

    /** Runs everything due now, without letting time pass. */
    fun settle() = scope.runCurrent()

    private inner class VirtualClock(
        private val ahead: Duration,
    ) : Clock() {
        override fun getZone() = ZoneOffset.UTC

        override fun withZone(zone: java.time.ZoneId?): Clock = this

        override fun instant(): Instant = START.plusMillis(scope.testScheduler.currentTime).plus(ahead.toJavaDuration())
    }

    companion object {
        /** The bucket holders lease their keys in unless a test names another. */
        const val BUCKET: String = "leases"

        /** Where every virtual clock starts. */
        val START: Instant = Instant.parse("2026-01-01T00:00:00Z")
    }
}

/**
 * Holders of leases on one [VirtualKeyValue], with short timings: refresh every 300 ms, live 2 s, a grace of 1 s, a
 * retry after 100 ms, and a claim more than 1 s ahead reported.
 */
class VirtualLeases(
    private val scope: TestScope,
    val timings: LeaseTimings = SHORT,
) {
    val keyValue = VirtualKeyValue(scope)

    /** Starts holder [id] with its own way to the store, its clock [ahead] of the store's. */
    fun holder(
        id: String,
        ahead: Duration = Duration.ZERO,
    ): LeaseHolder {
        val buckets = ScriptedBuckets(keyValue.store)
        val leases =
            Leases(
                holder = id,
                buckets = MutableStateFlow(buckets),
                bucketName = VirtualKeyValue.BUCKET,
                codec = TextLeaseCodec,
                timings = timings,
                parent = scope.backgroundScope,
                clock = keyValue.clock(ahead),
                openTelemetry = keyValue.telemetry.openTelemetry,
            )
        return LeaseHolder(id, leases, buckets)
    }

    /** The live entry of [key], or null when there is none or no holder could read it. */
    suspend fun entry(key: String): LeaseEntry<String>? = keyValue.read(key)?.let(TextLeaseCodec::decode)

    companion object {
        val SHORT: LeaseTimings =
            LeaseTimings(refresh = 300.milliseconds, ttl = 2.seconds, grace = 1.seconds, retry = 100.milliseconds, skew = 1.seconds)
    }
}

/** One holder of a [VirtualLeases]; [buckets] is its way to the store. */
class LeaseHolder(
    val id: String,
    val leases: Leases<String>,
    val buckets: ScriptedBuckets,
) {
    /** Claims [key], keeping the value the key kept before, else [value]. */
    fun claim(
        key: String,
        value: String = "first",
    ) = leases.claim(key) { previous -> previous ?: value }

    fun release(key: String) = leases.release(key)

    /** The holder stops as a crash would: no further write. */
    fun crash() = leases.close()
}

/** A lease entry as text, `holder|claimed|value`; anything else reads as no entry. */
object TextLeaseCodec : LeaseCodec<String> {
    override fun encode(entry: LeaseEntry<String>): ByteArray = "${entry.holder}|${entry.claimed}|${entry.value}".encodeToByteArray()

    override fun decode(bytes: ByteArray): LeaseEntry<String>? {
        val parts = bytes.decodeToString().split('|')
        if (parts.size != 3) return null
        val claimed = runCatching { Instant.parse(parts[1]) }.getOrNull() ?: return null
        return LeaseEntry(parts[0], claimed, parts[2])
    }
}
