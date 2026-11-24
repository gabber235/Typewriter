package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueEntry
import com.typewritermc.services.libs.communicator.kv.KeyValueKeys
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import kotlin.time.Duration

/**
 * Key value buckets in memory, with the semantics of a JetStream key value store that KeyValueBucketContractTest checks
 * against a real broker: one revision sequence per bucket, a time to live per write, and a key that expires once [now]
 * passes its time to live. A bucket is missing until [ensure] created it. Time is whatever [now] says, so a test on
 * virtual time expires keys exactly when it advances past them.
 */
class MemoryKeyValueBuckets(
    private val now: () -> Duration,
) : KeyValueBuckets {
    private val buckets = HashMap<String, MemoryBucket>()

    override suspend fun open(name: String): KeyValueOpen =
        synchronized(buckets) { buckets[name] }?.let { KeyValueOpen.Opened(it) } ?: KeyValueOpen.Missing

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen =
        KeyValueOpen.Opened(synchronized(buckets) { buckets.getOrPut(bucket.name) { MemoryBucket() } })

    private inner class MemoryBucket : KeyValueBucket {
        private val entries = HashMap<String, Stored>()
        private var sequence = 0L

        override suspend fun get(key: String): KeyValueRead =
            synchronized(this) {
                live(key)?.let { KeyValueRead.Found(KeyValueEntry(key, it.value.copyOf(), it.revision)) } ?: KeyValueRead.Absent
            }

        override suspend fun create(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ): KeyValueWrite = synchronized(this) { if (live(key) != null) KeyValueWrite.Conflict else write(key, value, ttl) }

        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ): KeyValueWrite = synchronized(this) { if (live(key)?.revision != revision) KeyValueWrite.Conflict else write(key, value, ttl) }

        override suspend fun keys(filter: String): KeyValueKeys =
            synchronized(this) { KeyValueKeys.Listed(entries.keys.filter { live(it) != null && matches(filter, it) }.sorted()) }

        private fun live(key: String): Stored? = entries[key]?.takeIf { now() < it.expires }

        private fun write(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ): KeyValueWrite {
            val revision = ++sequence
            entries[key] = Stored(value.copyOf(), revision, now() + ttl)
            return KeyValueWrite.Written(revision)
        }
    }

    private class Stored(
        val value: ByteArray,
        val revision: Long,
        val expires: Duration,
    )

    private companion object {
        /** Whether [key] matches the subject pattern [filter], where `*` stands for one token and `>` for the rest. */
        fun matches(
            filter: String,
            key: String,
        ): Boolean {
            val pattern = filter.split('.')
            val tokens = key.split('.')
            pattern.forEachIndexed { index, part ->
                if (part == ">") return tokens.size > index
                if (index >= tokens.size || (part != "*" && part != tokens[index])) return false
            }
            return pattern.size == tokens.size
        }
    }
}
