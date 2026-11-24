package com.typewritermc.loader.work

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactCatalog
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkSubjects
import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.kv.KeyValueBucket
import com.typewritermc.services.libs.communicator.kv.KeyValueBucketDeclaration
import com.typewritermc.services.libs.communicator.kv.KeyValueBuckets
import com.typewritermc.services.libs.communicator.kv.KeyValueKeys
import com.typewritermc.services.libs.communicator.kv.KeyValueOpen
import com.typewritermc.services.libs.communicator.kv.KeyValueRead
import com.typewritermc.services.libs.communicator.kv.KeyValueWrite
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.ReplyChannel
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import kotlinx.coroutines.currentCoroutineContext
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration
import kotlin.time.TimeMark

/**
 * This session with every outbound operation of its communicator and its buckets counted in [work], from its start
 * until its result is back in the calling coroutine. Inbound deliveries do not count here; their handling counts at
 * the dispatcher that runs it.
 */
fun HostedMessagingSession.counted(work: InFlightWork): HostedMessagingSession =
    copy(
        communicator = communicator.over { CountedTransport(it, work) },
        buckets = CountedBuckets(buckets, work),
    )

/** This access with every operation counted in [work], from its start until its result is back in the calling coroutine. */
fun SharedArtifactAccess.counted(work: InFlightWork): SharedArtifactAccess = CountedSharedArtifacts(this, work)

/**
 * Counts [operation] as item [name] for the subjects of the calling coroutine. A result [failure] names a cause for, or
 * a thrown exception other than cancellation, fails the item; anything else ends it.
 */
private suspend inline fun <T> InFlightWork.awaiting(
    name: String,
    failure: (T) -> Throwable? = { null },
    operation: () -> T,
): T {
    val item = begin(name, currentCoroutineContext()[WorkSubjects]?.subjects)
    try {
        val result = operation()
        val cause = failure(result)
        if (cause == null) item.end() else item.failed(cause)
        return result
    } catch (cancelled: CancellationException) {
        item.end()
        throw cancelled
    } catch (thrown: Throwable) {
        item.failed(thrown)
        throw thrown
    }
}

private fun TransportResult<*>.failure(): Throwable? = (this as? TransportResult.Failure)?.error?.asCause()

private fun TransportError.asCause(): Throwable = cause ?: IllegalStateException("${this::class.simpleName} during transport operation.")

private class CountedTransport(
    private val transport: MessageTransport,
    private val work: InFlightWork,
) : MessageTransport {
    override val system get() = transport.system

    override suspend fun openReplyChannel(): TransportResult<ReplyChannel> {
        val item = work.begin("reply channel", currentCoroutineContext()[WorkSubjects]?.subjects)
        val opened =
            try {
                transport.openReplyChannel()
            } catch (thrown: Throwable) {
                if (thrown is CancellationException) item.end() else item.failed(thrown)
                throw thrown
            }
        return when (opened) {
            is TransportResult.Failure -> {
                item.failed(opened.error.asCause())
                opened
            }

            is TransportResult.Success -> {
                TransportResult.Success(
                    object : ReplyChannel by opened.value {
                        override suspend fun close() {
                            try {
                                opened.value.close()
                            } finally {
                                item.end()
                            }
                        }
                    },
                )
            }
        }
    }

    override suspend fun publish(message: OutboundMessage) =
        work.awaiting("publish ${message.address}", { it.failure() }) { transport.publish(message) }

    override suspend fun reply(
        message: OutboundMessage,
        limits: TransportLimits?,
        received: TimeMark?,
    ) = work.awaiting("reply ${message.address}", { it.failure() }) { transport.reply(message, limits, received) }

    override suspend fun request(
        message: OutboundMessage,
        timeout: Duration,
        limits: TransportLimits?,
    ): TransportResult<InboundMessage> =
        work.awaiting("request ${message.address}", { it.failure() }) { transport.request(message, timeout, limits) }

    override suspend fun subscribe(
        pattern: AddressPattern,
        options: SubscriptionOptions,
    ): TransportResult<TransportSubscription> =
        work.awaiting("subscribe $pattern", { it.failure() }) { transport.subscribe(pattern, options) }
}

private class CountedBuckets(
    private val buckets: KeyValueBuckets,
    private val work: InFlightWork,
) : KeyValueBuckets {
    override suspend fun open(name: String) = work.awaiting("kv open $name", { it.failure() }) { buckets.open(name) }.counted(name)

    override suspend fun ensure(bucket: KeyValueBucketDeclaration) =
        work.awaiting("kv ensure ${bucket.name}", { it.failure() }) { buckets.ensure(bucket) }.counted(bucket.name)

    private fun KeyValueOpen.failure() = (this as? KeyValueOpen.Failed)?.cause

    private fun KeyValueOpen.counted(name: String) =
        if (this is KeyValueOpen.Opened) KeyValueOpen.Opened(CountedBucket(name, bucket, work)) else this
}

private class CountedBucket(
    private val name: String,
    private val bucket: KeyValueBucket,
    private val work: InFlightWork,
) : KeyValueBucket {
    override suspend fun get(key: String) = work.awaiting("kv get $name $key", { (it as? KeyValueRead.Failed)?.cause }) { bucket.get(key) }

    override suspend fun create(
        key: String,
        value: ByteArray,
        ttl: Duration,
    ) = work.awaiting("kv create $name $key", { it.failure() }) { bucket.create(key, value, ttl) }

    override suspend fun update(
        key: String,
        value: ByteArray,
        ttl: Duration,
        revision: Long,
    ) = work.awaiting("kv update $name $key", { it.failure() }) { bucket.update(key, value, ttl, revision) }

    override suspend fun keys(filter: String) =
        work.awaiting("kv keys $name $filter", { (it as? KeyValueKeys.Failed)?.cause }) { bucket.keys(filter) }

    private fun KeyValueWrite.failure() = (this as? KeyValueWrite.Failed)?.cause
}

private class CountedSharedArtifacts(
    private val access: SharedArtifactAccess,
    private val work: InFlightWork,
) : SharedArtifactAccess {
    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        work.awaiting("blob metadata ${digest.value}") { access.metadata(digest) }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        work.awaiting("blob fetch ${digest.value}") {
            access.fetch(digest)
        }

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult = work.awaiting("blob store ${expected.digest.value}") { access.store(expected, content) }

    override suspend fun publish(command: PublishSharedArtifact): PublishResult =
        work.awaiting("shared artifact publish ${command.id.value}") { access.publish(command) }

    override suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult = work.awaiting("shared artifact delete ${id.value}") { access.delete(id, expectedRevision, provenance) }

    override suspend fun catalog(): SharedArtifactCatalog = work.awaiting("shared artifact catalog") { access.catalog() }
}
