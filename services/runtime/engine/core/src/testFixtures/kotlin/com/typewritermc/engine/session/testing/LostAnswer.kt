package com.typewritermc.engine.session.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitCancellation
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration

/**
 * An engine's buckets that, once [armed][arm], let the next update reach the broker and then never answer it, as a write
 * cancelled while its answer was on its way: the broker keeps the write, the engine never learns its revision.
 */
class LostAnswer(
    private val inner: KeyValueBuckets,
) : KeyValueBuckets {
    /** Completes once the armed update reached the broker. */
    val landed = CompletableDeferred<Unit>()
    private val armed = AtomicBoolean(false)

    /** Loses the answer of the next update. */
    fun arm() {
        armed.set(true)
    }

    override suspend fun open(name: String): KeyValueOpen =
        when (val opened = inner.open(name)) {
            is KeyValueOpen.Opened -> KeyValueOpen.Opened(Lost(opened.bucket))
            else -> opened
        }

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen = inner.ensure(bucket)

    private inner class Lost(
        private val bucket: KeyValueBucket,
    ) : KeyValueBucket by bucket {
        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ): KeyValueWrite {
            val written = bucket.update(key, value, ttl, revision)
            if (!armed.getAndSet(false)) return written
            landed.complete(Unit)
            awaitCancellation()
        }
    }
}
