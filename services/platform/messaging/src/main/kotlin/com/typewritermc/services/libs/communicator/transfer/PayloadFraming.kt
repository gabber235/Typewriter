package com.typewritermc.services.libs.communicator.transfer

import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.utils.sha256Hex
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.io.ByteArrayOutputStream
import java.util.UUID
import kotlin.time.ComparableTimeMark
import kotlin.time.Duration
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Bounds how a transport splits one payload, a request or a reply, into frames.
 *
 * A payload of at most [chunkBytes] travels as one plain message. A larger one travels as frames of at most
 * [chunkBytes]. A framed request flows in windows of [windowFrames]: the receiver grants each next window, so a
 * sender never runs more than one window ahead of a slow receiver. A framed reply does too when [replyCredit]
 * holds, and otherwise streams every frame without waiting; the generator enables reply credit only on routes no
 * panel role calls, because granting a credit is a NATS response and panel connections hold no response
 * permission. A payload above its direction's ceiling is never sent. Requests are single messages unless a route
 * raises [requestMaxBytes]; replies may be framed up to [replyMaxBytes]. A sender waits [frameInactivity] for a
 * credit and a receiver as long for the next frame. A responder may send its reply for [replyTtl] after it
 * received the request; a framed reply still sending then stops as interrupted. The generated `TRANSPORT_LIMITS`
 * carries the manifest defaults, and a route whose limits differ carries its own.
 */
data class TransportLimits(
    val chunkBytes: Int,
    val windowFrames: Int,
    val requestMaxBytes: Long,
    val replyMaxBytes: Long,
    val frameInactivity: Duration,
    val replyTtl: Duration,
    val replyCredit: Boolean,
) {
    init {
        require(chunkBytes > 0) { "Transfer chunk size must be positive." }
        require(windowFrames > 0) { "A credit window holds at least one frame." }
        require(requestMaxBytes >= chunkBytes && replyMaxBytes >= chunkBytes) { "A direction carries at least one chunk." }
        require(frameInactivity.isPositive() && replyTtl.isPositive()) { "Frame inactivity and reply time to live must be positive." }
    }

    /** Whether a request of this route may arrive in frames, so its server must assemble. */
    val framesRequests: Boolean get() = requestMaxBytes > chunkBytes
}

/**
 * A payload the transport could not deliver complete.
 *
 * Requests report it as the cause of a [TransportError.Failure], so communicators classify it as a transport
 * failure rather than a decoded response.
 */
sealed class TransferFailure(
    message: String,
) : RuntimeException(message)

/** The encoded payload of [size] bytes exceeded the [limit] its direction carries; no frame was sent. */
class TransferTooLarge(
    val size: Long,
    val limit: Long,
) : TransferFailure("The payload of $size bytes exceeds the $limit byte transfer limit")

/** The sender stopped part way, so the payload can never complete. */
class TransferInterrupted(
    reason: String = "The sender stopped before every frame was sent",
) : TransferFailure(reason)

/** The receiver already holds its bound of assembling bytes and refused another payload. */
class TransferBusy : TransferFailure("The receiver is assembling as many bytes as it holds")

/**
 * A frame or answer broke the framing rules: malformed headers, changed metadata or bytes, a failed size or digest
 * check, a missing frame, or an answer without the credit the sender waits for.
 */
class TransferRejected(
    reason: String,
) : TransferFailure(reason)

/** Header names and failure values of the payload framing wire format, shared with the panel and backend transports. */
internal object PayloadHeaders {
    const val PAYLOAD = "Typewriter-Payload"
    const val CHUNK = "Typewriter-Chunk"
    const val SIZE = "Typewriter-Size"
    const val SHA256 = "Typewriter-Sha256"
    const val FAILURE = "Typewriter-Transfer-Failure"
    const val LIMIT = "Typewriter-Limit"

    /** On the answer to a window's last frame: frames below this index may be sent. */
    const val CREDIT = "Typewriter-Credit"

    const val TOO_LARGE = "too-large"
    const val INTERRUPTED = "interrupted"

    /** Answer to a window end whose earlier frames never arrived; NATS core may drop a message. */
    const val INCOMPLETE = "incomplete"

    /** Answer to a payload that would exceed the receiver's bound of assembling bytes. */
    const val BUSY = "busy"

    /** Answer to a window end whose payload broke the framing rules, so the receiver dropped it. */
    const val REJECTED = "rejected"

    val all = listOf(PAYLOAD, CHUNK, SIZE, SHA256, FAILURE, LIMIT, CREDIT)
}

/** One frame of a payload: its position, framing headers and the range of the encoded payload it carries. */
internal class PayloadFrame(
    val index: Int,
    val headers: MessageHeaders,
    private val bytes: ByteArray,
    private val from: Int,
    private val to: Int,
) {
    /** The frame's bytes, copied only when the frame is sent. */
    val payload: Payload get() = Payload.slice(bytes, from, to)
}

/** How one encoded payload crosses the transport, decided before any frame is sent. */
internal sealed interface PayloadPlan {
    /** The payload fits one message, which carries no framing headers. */
    data object Single : PayloadPlan

    /** The payload exceeds its ceiling; a responder sends one failure message with [headers] instead. */
    class TooLarge(
        val size: Long,
        val limit: Long,
        val headers: MessageHeaders,
    ) : PayloadPlan

    /** The payload travels as [frames] that share [payloadId], the complete size and the digest. */
    class Framed(
        val payloadId: String,
        val frames: List<PayloadFrame>,
    ) : PayloadPlan
}

/**
 * Plans the payload of one request or reply against [maxBytes] of its direction. Frames are ranges of one array:
 * planning copies the payload once and computes its digest once. Every payload gets a fresh id from [nextPayloadId],
 * so frames of several senders on one address never mix.
 */
internal fun TransportLimits.planPayload(
    payload: Payload,
    maxBytes: Long,
    nextPayloadId: () -> String = ::randomPayloadId,
): PayloadPlan {
    val size = payload.size.toLong()
    if (size <= chunkBytes) return PayloadPlan.Single
    if (size > maxBytes) {
        val headers =
            MessageHeaders.of(
                PayloadHeaders.PAYLOAD to nextPayloadId(),
                PayloadHeaders.FAILURE to PayloadHeaders.TOO_LARGE,
                PayloadHeaders.SIZE to size.toString(),
                PayloadHeaders.LIMIT to maxBytes.toString(),
            )
        return PayloadPlan.TooLarge(size, maxBytes, headers)
    }
    val bytes = payload.toByteArray()
    val payloadId = nextPayloadId()
    val digest = bytes.sha256Hex()
    val count = ((size + chunkBytes - 1) / chunkBytes).toInt()
    val frames =
        (0 until count).map { index ->
            val start = index * chunkBytes
            PayloadFrame(
                index = index,
                headers =
                    MessageHeaders.of(
                        PayloadHeaders.PAYLOAD to payloadId,
                        PayloadHeaders.CHUNK to "$index/$count",
                        PayloadHeaders.SIZE to size.toString(),
                        PayloadHeaders.SHA256 to digest,
                    ),
                bytes = bytes,
                from = start,
                to = minOf(start + chunkBytes, bytes.size),
            )
        }
    return PayloadPlan.Framed(payloadId, frames)
}

/** Where the frames of one payload go: a requester's frames on the route address, or a responder's on a reply inbox. */
internal interface FrameChannel {
    suspend fun publish(frame: PayloadFrame): TransportResult<Unit>

    /** Sends [frame] with a private reply address and waits for the single answer, assembling a framed one. */
    suspend fun request(
        frame: PayloadFrame,
        timeout: Duration,
    ): TransportResult<InboundMessage>

    /** Tells the receiver that payload [payloadId] stops here, so it frees the assembly at once. */
    suspend fun interrupt(payloadId: String)
}

/**
 * How a sender paces the frames of one payload: in credit windows of [windowFrames], or streamed without waiting
 * when [windowFrames] is null. A sender with a [deadline] stops as interrupted once it passes, and never waits for
 * a credit beyond it.
 */
internal class FramePacing(
    val windowFrames: Int?,
    val inactivity: Duration,
    val deadline: TimeMark? = null,
)

/**
 * Sends this plan as [pacing] says. Frames inside a window are published; the last frame of each window is sent as a
 * request, and its answer carries [PayloadHeaders.CREDIT], the index below which the next frames may go. A streamed
 * payload has a single window holding every frame.
 *
 * When [finalAnswered], the final frame is also sent as a request: its answer is the route's response, awaited for
 * [responseTimeout] and returned. Otherwise the final frame is only published and the result is null. A failure
 * header on an answer fails the transfer, and a credit on the answer to a final request frame is a protocol error,
 * never a response. On any failure, including a passed deadline, the receiver is told with an interrupted frame.
 */
internal suspend fun PayloadPlan.Framed.sendInWindows(
    channel: FrameChannel,
    pacing: FramePacing,
    finalAnswered: Boolean,
    responseTimeout: Duration,
): TransportResult<InboundMessage?> {
    var granted = pacing.windowFrames ?: frames.size
    var index = 0
    while (true) {
        val windowEnd = minOf(granted, frames.size)
        while (index < windowEnd - 1) {
            pacing.expired()?.let { return interrupted(channel, it) }
            channel.publish(frames[index]).onFailure { failure -> return interrupted(channel, failure) }
            index++
        }
        pacing.expired()?.let { return interrupted(channel, it) }
        val final = index == frames.size - 1
        if (final && !finalAnswered) {
            return when (val published = channel.publish(frames[index])) {
                is TransportResult.Failure -> interrupted(channel, published.error)
                is TransportResult.Success -> TransportResult.Success(null)
            }
        }
        val creditWait = pacing.deadline?.let { minOf(pacing.inactivity, -it.elapsedNow()) } ?: pacing.inactivity
        val answer =
            when (val asked = channel.request(frames[index], if (final) responseTimeout else creditWait)) {
                is TransportResult.Failure -> return interrupted(channel, asked.error)
                is TransportResult.Success -> asked.value
            }
        answer.headers.first(PayloadHeaders.FAILURE)?.let { failure ->
            return interrupted(channel, TransportError.Failure(transferFailure(failure, answer.headers)))
        }
        val credit = answer.headers.first(PayloadHeaders.CREDIT)?.toIntOrNull()
        if (final) {
            if (credit != null) return protocolError(channel, "The receiver granted credit for the final frame")
            return TransportResult.Success(answer)
        }
        index++
        granted = credit?.takeIf { it > index } ?: return protocolError(channel, "The receiver granted no credit")
    }
}

/** The failure of a sender whose deadline passed, or null while it may still send. */
private fun FramePacing.expired(): TransportError? =
    deadline?.takeIf { it.hasPassedNow() }?.let {
        TransportError.Failure(TransferInterrupted("The reply outlived its time to live before every frame was sent"))
    }

private inline fun TransportResult<Unit>.onFailure(block: (TransportError) -> Nothing) {
    if (this is TransportResult.Failure) block(error)
}

private suspend fun PayloadPlan.Framed.interrupted(
    channel: FrameChannel,
    error: TransportError,
): TransportResult<Nothing> {
    channel.interrupt(payloadId)
    return TransportResult.Failure(error)
}

private suspend fun PayloadPlan.Framed.protocolError(
    channel: FrameChannel,
    reason: String,
): TransportResult<Nothing> = interrupted(channel, TransportError.Failure(TransferRejected(reason)))

/** Headers of the frame that tells the receiver payload [payloadId] stopped part way. */
internal fun interruptedHeaders(payloadId: String): MessageHeaders = failureHeaders(payloadId, PayloadHeaders.INTERRUPTED)

/** Headers of a message that ends payload [payloadId] with [failure]. */
internal fun failureHeaders(
    payloadId: String,
    failure: String,
): MessageHeaders = MessageHeaders.of(PayloadHeaders.PAYLOAD to payloadId, PayloadHeaders.FAILURE to failure)

/** Returns these headers with every [framing] header set, replacing values of the same name. */
internal fun MessageHeaders.withFraming(framing: MessageHeaders): MessageHeaders =
    framing.fold(this) { headers, (name, values) -> values.fold(headers.remove(name)) { result, value -> result.plus(name, value) } }

private fun MessageHeaders.withoutFraming(): MessageHeaders = PayloadHeaders.all.fold(this) { headers, name -> headers.remove(name) }

private fun randomPayloadId(): String = UUID.randomUUID().toString().replace("-", "")

/** The failure a [PayloadHeaders.FAILURE] value names; unknown values are rejections. */
internal fun transferFailure(
    failure: String,
    headers: MessageHeaders,
): TransferFailure =
    when (failure) {
        PayloadHeaders.TOO_LARGE -> {
            val size = headers.first(PayloadHeaders.SIZE)?.toLongOrNull()
            val limit = headers.first(PayloadHeaders.LIMIT)?.toLongOrNull()
            if (size != null &&
                limit != null
            ) {
                TransferTooLarge(size, limit)
            } else {
                TransferRejected("Too large frame lacks its size and limit")
            }
        }

        PayloadHeaders.INTERRUPTED -> {
            TransferInterrupted()
        }

        PayloadHeaders.INCOMPLETE -> {
            TransferRejected("The receiver missed a frame of the payload")
        }

        PayloadHeaders.BUSY -> {
            TransferBusy()
        }

        PayloadHeaders.REJECTED -> {
            TransferRejected("The receiver rejected a frame of the payload")
        }

        else -> {
            TransferRejected("Unknown transfer failure")
        }
    }

/** What one accepted message means for its receiver. */
internal sealed interface Assembly {
    /** A whole payload: a plain message, or the last frame of a framed one with the framing headers removed. */
    data class Complete(
        val message: InboundMessage,
    ) : Assembly

    /** Answer the window end on its reply address with these headers and an empty payload. */
    data class Answer(
        val headers: MessageHeaders,
    ) : Assembly

    /** More frames are needed. */
    data object Waiting : Assembly

    /** The sender reported [failure]; its assembly is gone and there is nothing to answer. */
    data class Failed(
        val failure: TransferFailure,
    ) : Assembly
}

/**
 * Assembles the framed payloads arriving at one receiver and decides each window's answer.
 *
 * Frames are grouped by payload id, may arrive in any order, and identical duplicates are accepted while changed
 * ones are rejected. Bounds, the complete size and the digest are verified before a payload is returned without
 * framing headers, so a caller never decodes partial bytes. A frame that carries a reply address ends a window: the
 * answer is the next grant when every earlier frame has arrived, and an incomplete failure otherwise. The receiver
 * holds at most [maxPendingBytes] across all assemblies; a payload that would exceed it is refused and its window
 * end is answered busy. [sweep] drops assemblies idle for the limits' frame inactivity; owners that receive frames
 * from senders that may vanish call it on a timer. Access is serialized because route workers run in parallel. A rejected frame throws
 * [TransferRejected] and drops its assembly.
 */
internal class PayloadAssembler(
    private val limits: TransportLimits,
    private val maxBytes: Long,
    private val maxPendingBytes: Long = maxBytes,
    private val clock: TimeSource.WithComparableMarks = TimeSource.Monotonic,
) {
    private val inactivity = limits.frameInactivity

    private val mutex = Mutex()
    private val pending = mutableMapOf<String, PendingPayload>()
    private val refused = mutableMapOf<String, ComparableTimeMark>()

    /** How many payloads are being assembled. */
    suspend fun pendingCount(): Int = mutex.withLock { pending.size }

    suspend fun accept(message: InboundMessage): Assembly =
        mutex.withLock {
            val headers = message.headers
            val payloadId = headers.first(PayloadHeaders.PAYLOAD) ?: return Assembly.Complete(message)
            headers.first(PayloadHeaders.FAILURE)?.let { failure ->
                pending.remove(payloadId)
                refused.remove(payloadId)
                return Assembly.Failed(transferFailure(failure, headers))
            }
            if (payloadId in refused) {
                if (message.replyTo == null) return Assembly.Waiting
                refused.remove(payloadId)
                return failureAnswer(payloadId, PayloadHeaders.BUSY)
            }
            try {
                val frame = parseFrame(headers, message.payload)
                val entry =
                    pending[payloadId] ?: run {
                        if (pending.values.sumOf { it.parts.size } + frame.size > maxPendingBytes) {
                            if (message.replyTo != null) return failureAnswer(payloadId, PayloadHeaders.BUSY)
                            refused[payloadId] = clock.markNow()
                            return Assembly.Waiting
                        }
                        PendingPayload(
                            PayloadParts(frame.count, frame.size, frame.sha256),
                            clock.markNow(),
                        ).also { pending[payloadId] = it }
                    }
                entry.lastFrame = clock.markNow()
                val bytes = entry.parts.accept(frame)
                if (bytes != null) {
                    pending.remove(payloadId)
                    return Assembly.Complete(message.copy(payload = Payload.copyOf(bytes), headers = headers.withoutFraming()))
                }
                if (message.replyTo == null) return Assembly.Waiting
                if (frame.index == frame.count - 1 || !entry.parts.receivedThrough(frame.index)) {
                    pending.remove(payloadId)
                    return failureAnswer(payloadId, PayloadHeaders.INCOMPLETE)
                }
                Assembly.Answer(
                    MessageHeaders.of(PayloadHeaders.CREDIT to minOf(frame.index + 1 + limits.windowFrames, frame.count).toString()),
                )
            } catch (rejected: TransferRejected) {
                pending.remove(payloadId)
                throw rejected
            }
        }

    /** Drops assemblies and refusals whose last frame is older than the inactivity bound. */
    suspend fun sweep() =
        mutex.withLock {
            pending.entries.removeAll { (_, entry) -> entry.lastFrame.elapsedNow() > inactivity }
            refused.entries.removeAll { (_, since) -> since.elapsedNow() > inactivity }
        }

    private fun failureAnswer(
        payloadId: String,
        failure: String,
    ): Assembly = Assembly.Answer(failureHeaders(payloadId, failure))

    private fun parseFrame(
        headers: MessageHeaders,
        payload: Payload,
    ): ParsedFrame {
        val chunk = headers.first(PayloadHeaders.CHUNK)?.let(chunkPattern::matchEntire) ?: reject("Frame lacks its chunk position")
        val index = chunk.groupValues[1].toInt()
        val count = chunk.groupValues[2].toInt()
        val size = headers.first(PayloadHeaders.SIZE)?.takeIf(sizePattern::matches)?.toLongOrNull() ?: reject("Frame lacks its size")
        val sha256 = headers.first(PayloadHeaders.SHA256)?.takeIf(sha256Pattern::matches) ?: reject("Frame lacks its digest")
        val maximumCount = (maxBytes + limits.chunkBytes - 1) / limits.chunkBytes
        if (count < 1 || count > maximumCount || index !in 0 until count) reject("Frame position is out of bounds")
        if (size !in 0..minOf(maxBytes, Int.MAX_VALUE.toLong())) reject("Payload size is out of bounds")
        if (payload.size > limits.chunkBytes) reject("Frame exceeds the chunk size")
        return ParsedFrame(index, count, size, sha256, payload.toByteArray())
    }
}

private class PendingPayload(
    val parts: PayloadParts,
    var lastFrame: ComparableTimeMark,
)

private class ParsedFrame(
    val index: Int,
    val count: Int,
    val size: Long,
    val sha256: String,
    val bytes: ByteArray,
)

/** The frames of one payload received so far, sharing the metadata of its first frame. */
private class PayloadParts(
    private val count: Int,
    val size: Long,
    private val sha256: String,
) {
    private val parts = arrayOfNulls<ByteArray>(count)
    private var received = 0
    private var retained = 0L

    /** Whether every frame up to and including [index] has arrived. */
    fun receivedThrough(index: Int): Boolean = (0..index).all { parts[it] != null }

    fun accept(frame: ParsedFrame): ByteArray? {
        if (frame.count != count || frame.size != size || frame.sha256 != sha256) reject("Frame metadata changed during assembly")
        val prior = parts[frame.index]
        if (prior != null) {
            if (!prior.contentEquals(frame.bytes)) reject("Frame changed during assembly")
            return null
        }
        retained += frame.bytes.size
        if (retained > size) reject("Frames exceed their declared size")
        parts[frame.index] = frame.bytes
        received++
        if (received < count) return null
        val complete = ByteArrayOutputStream(size.toInt())
        parts.forEach { complete.write(requireNotNull(it)) }
        val bytes = complete.toByteArray()
        if (bytes.size.toLong() != size) reject("Payload size verification failed")
        if (bytes.sha256Hex() != sha256) reject("Payload digest verification failed")
        return bytes
    }
}

private fun reject(reason: String): Nothing = throw TransferRejected(reason)

private val chunkPattern = Regex("""(\d{1,9})/(\d{1,9})""")

// Fifteen digits parse exactly in every transport, including the panel on the web, and cover every admitted size.
private val sizePattern = Regex("""\d{1,15}""")
private val sha256Pattern = Regex("[0-9a-f]{64}")
