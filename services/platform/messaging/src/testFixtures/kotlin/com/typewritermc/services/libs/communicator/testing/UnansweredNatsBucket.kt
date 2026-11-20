package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.NatsKeyValueBuckets
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.withTimeout
import java.lang.reflect.Proxy
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import io.natskt.jetstream.api.kv.KeyValueBucket as NatsBucket

/**
 * A key value bucket over a natskt bucket whose broker never answers: every request times out the way natskt's own
 * request timeout does, with a [kotlinx.coroutines.TimeoutCancellationException] inside the caller's coroutine.
 */
fun unansweredKeyValueBucket(): KeyValueBucket = NatsKeyValueBuckets.JetStreamBucket(UnansweredNatsBucket)

private val unused: NatsBucket =
    Proxy.newProxyInstance(NatsBucket::class.java.classLoader, arrayOf(NatsBucket::class.java)) { _, method, _ ->
        error("The unanswered bucket does not offer ${method.name}.")
    } as NatsBucket

private object UnansweredNatsBucket : NatsBucket by unused {
    override suspend fun get(
        key: String,
        revision: ULong?,
    ) = unanswered()

    override suspend fun create(
        key: String,
        value: ByteArray,
        ttl: Duration?,
    ): ULong = unanswered()

    override suspend fun update(
        key: String,
        value: ByteArray,
        revision: ULong,
        ttl: Duration?,
    ): ULong = unanswered()

    override suspend fun keys(filter: String?) = unanswered()

    private suspend fun unanswered(): Nothing = withTimeout(1.milliseconds) { awaitCancellation() }
}
