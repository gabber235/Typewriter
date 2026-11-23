package com.typewritermc.engine.session.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import kotlinx.coroutines.CompletableDeferred
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration

/**
 * An engine's buckets whose first write waits until [release], as a write that reaches the broker late: the engine
 * reads the key, [reached] completes, and the write goes out only once the test let other engines act. The broker
 * still decides whether it wins.
 */
class LateFirstWrite(
    private val inner: KeyValueBuckets,
) : KeyValueBuckets {
    /** Completes once the first write is about to go out. */
    val reached = CompletableDeferred<Unit>()
    private val released = CompletableDeferred<Unit>()
    private val first = AtomicBoolean(true)

    /** Lets the first write go out. */
    fun release() {
        released.complete(Unit)
    }

    override suspend fun open(name: String): KeyValueOpen =
        when (val opened = inner.open(name)) {
            is KeyValueOpen.Opened -> KeyValueOpen.Opened(Late(opened.bucket))
            else -> opened
        }

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen = inner.ensure(bucket)

    private inner class Late(
        private val bucket: KeyValueBucket,
    ) : KeyValueBucket by bucket {
        override suspend fun create(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ): KeyValueWrite {
            late()
            return bucket.create(key, value, ttl)
        }

        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ): KeyValueWrite {
            late()
            return bucket.update(key, value, ttl, revision)
        }
    }

    private suspend fun late() {
        if (!first.getAndSet(false)) return
        reached.complete(Unit)
        released.await()
    }
}
