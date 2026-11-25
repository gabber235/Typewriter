package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueKeys
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.awaitCancellation
import java.io.IOException
import kotlin.time.Duration

/**
 * One engine's way to [inner]'s buckets, with its requests in the test's hands: the test holds a request on its way and
 * decides when it reaches the broker and what its caller hears back, as a slow, lost or failed broker request would.
 *
 * [holdNext] holds the next request of one kind; [holdEvery] holds every request in [pending] until the test resolves
 * it, so a test can deliver the requests of several engines in any order. While [unreachable], every request fails at
 * once, as while the broker cannot be reached.
 */
class ScriptedBuckets(
    private val inner: KeyValueBuckets,
) : KeyValueBuckets {
    /** Every request fails at once, as while the broker cannot be reached. */
    @Volatile
    var unreachable: Boolean = false

    /** Holds every request in [pending] until the test resolves it. */
    @Volatile
    var holdEvery: Boolean = false

    private val waiting = mutableListOf<HeldRequest>()
    private val armed = mutableListOf<HeldRequest>()

    /** The held requests that reached this point and wait for the test, oldest first. */
    val pending: List<HeldRequest> get() = synchronized(waiting) { waiting.toList() }

    /** Holds the next request of [kind]; its [HeldRequest.reached] completes once that request arrives. */
    fun holdNext(kind: RequestKind): HeldRequest = HeldRequest(kind).also { synchronized(waiting) { armed += it } }

    override suspend fun open(name: String): KeyValueOpen {
        if (unreachable) return KeyValueOpen.Failed(unreachableFailure())
        return when (val opened = inner.open(name)) {
            is KeyValueOpen.Opened -> KeyValueOpen.Opened(Scripted(opened.bucket))
            else -> opened
        }
    }

    override suspend fun ensure(bucket: KeyValueBucketDeclaration): KeyValueOpen = inner.ensure(bucket)

    /** Waits for the test when [kind] is held; null when the request goes through untouched. */
    private suspend fun arrive(
        kind: RequestKind,
        key: String,
    ): Resolution? {
        val held =
            synchronized(waiting) {
                val next = armed.firstOrNull { it.kind == kind }?.also { armed.remove(it) } ?: if (holdEvery) HeldRequest(kind) else null
                next?.also {
                    it.key = key
                    waiting += it
                }
            } ?: return null
        held.reached.complete(Unit)
        try {
            return held.resolution.await()
        } finally {
            synchronized(waiting) { waiting.remove(held) }
        }
    }

    private inner class Scripted(
        private val bucket: KeyValueBucket,
    ) : KeyValueBucket {
        override suspend fun get(key: String): KeyValueRead =
            request(RequestKind.READ, key, { KeyValueRead.Failed(it) }) { bucket.get(key) }

        override suspend fun create(
            key: String,
            value: ByteArray,
            ttl: Duration,
        ): KeyValueWrite = request(RequestKind.WRITE, key, { KeyValueWrite.Failed(it) }) { bucket.create(key, value, ttl) }

        override suspend fun update(
            key: String,
            value: ByteArray,
            ttl: Duration,
            revision: Long,
        ): KeyValueWrite = request(RequestKind.WRITE, key, { KeyValueWrite.Failed(it) }) { bucket.update(key, value, ttl, revision) }

        override suspend fun keys(filter: String): KeyValueKeys =
            request(RequestKind.LIST, filter, { KeyValueKeys.Failed(it) }) { bucket.keys(filter) }

        private suspend fun <T> request(
            kind: RequestKind,
            key: String,
            failed: (Throwable) -> T,
            send: suspend () -> T,
        ): T {
            if (unreachable) return failed(unreachableFailure())
            return when (arrive(kind, key)) {
                null, Resolution.LAND -> {
                    send()
                }

                Resolution.LAND_AND_FAIL -> {
                    send()
                    failed(IOException("The broker's answer to this $kind of $key was lost"))
                }

                Resolution.LAND_AND_HANG -> {
                    send()
                    awaitCancellation()
                }

                Resolution.FAIL -> {
                    failed(IOException("This $kind of $key never reached the broker"))
                }
            }
        }
    }

    private fun unreachableFailure() = IOException("The broker cannot be reached")
}

/** What a scripted request does at the broker. */
enum class RequestKind { READ, WRITE, LIST }

/** One request a [ScriptedBuckets] holds until the test decides its fate. */
class HeldRequest internal constructor(
    val kind: RequestKind,
) {
    /** Completes once the request arrived and waits for the test. */
    val reached = CompletableDeferred<Unit>()

    /** The key the request is about, or the filter of a listing; set once it [reached]. */
    @Volatile
    var key: String? = null
        internal set

    internal val resolution = CompletableDeferred<Resolution>()

    /** The request reaches the broker and its caller hears the answer. */
    fun land() = resolve(Resolution.LAND)

    /** The request reaches the broker, but its answer is lost: the caller hears a failure, as when its request timed out. */
    fun landAndFail() = resolve(Resolution.LAND_AND_FAIL)

    /** The request reaches the broker, and its caller hears nothing until it is cancelled, as a quit cutting off a write. */
    fun landAndHang() = resolve(Resolution.LAND_AND_HANG)

    /** The request never reaches the broker; its caller hears a failure. */
    fun fail() = resolve(Resolution.FAIL)

    private fun resolve(resolution: Resolution) {
        check(this.resolution.complete(resolution)) { "This $kind request was resolved already" }
    }

    override fun toString(): String = "$kind $key"
}

internal enum class Resolution { LAND, LAND_AND_FAIL, LAND_AND_HANG, FAIL }
