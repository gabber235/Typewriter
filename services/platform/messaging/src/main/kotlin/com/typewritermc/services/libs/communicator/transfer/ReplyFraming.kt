package com.typewritermc.services.libs.communicator.transfer

import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.utils.sha256Hex
import java.io.ByteArrayOutputStream
import java.util.UUID
import kotlin.time.Duration.Companion.seconds

/**
 * Bounds how a transport splits one reply into frames on the requester's reply address.
 *
 * A reply of at most [chunkBytes] travels as one plain message. A larger reply travels as frames of at most
 * [chunkBytes] each, and a reply above [maxEncodedSize] is never sent: the requester receives [TransferTooLarge].
 * The generated `TRANSPORT_LIMITS` carries the values of the transport route manifest.
 */
data class TransportLimits(
    val chunkBytes: Int,
    val maxChunks: Int,
) {
    init {
        require(chunkBytes > 0) { "Transfer chunk size must be positive." }
        require(maxChunks > 0) { "Transfer chunk count must be positive." }
    }

    /** The largest encoded reply a transport carries: [chunkBytes] times [maxChunks]. */
    val maxEncodedSize: Long get() = chunkBytes.toLong() * maxChunks
}

/**
 * A reply the transport could not deliver complete.
 *
 * Requests report it as the cause of a [TransportError.Failure][com.typewritermc.services.libs.communicator.transport.TransportError.Failure],
 * so communicators classify it as a transport failure rather than a decoded response.
 */
sealed class TransferFailure(
    message: String,
) : RuntimeException(message)

/** The responder's encoded reply of [size] bytes exceeded the [limit] the transport carries. */
class TransferTooLarge(
    val size: Long,
    val limit: Long,
) : TransferFailure("The reply of $size bytes exceeds the $limit byte transfer limit")

/** The responder stopped publishing frames part way, so the reply can never complete. */
class TransferInterrupted : TransferFailure("The responder stopped before every reply frame was published")

/** A frame broke the framing rules: malformed headers, changed metadata or bytes, or a failed size or digest check. */
class TransferRejected(
    reason: String,
) : TransferFailure(reason)

/** Time a requester waits for the remaining frames once the first frame of its reply arrived. */
internal val REPLY_ASSEMBLY_BUDGET = 30.seconds

/** Header names and failure values of the reply framing wire format, shared with the panel and backend transports. */
internal object ReplyHeaders {
    const val REPLY = "Typewriter-Reply"
    const val CHUNK = "Typewriter-Chunk"
    const val SIZE = "Typewriter-Size"
    const val SHA256 = "Typewriter-Sha256"
    const val FAILURE = "Typewriter-Transfer-Failure"
    const val LIMIT = "Typewriter-Limit"
    const val TOO_LARGE = "too-large"
    const val INTERRUPTED = "interrupted"

    val all = listOf(REPLY, CHUNK, SIZE, SHA256, FAILURE, LIMIT)
}

/** One frame of a reply: framing headers and a slice of the encoded reply. */
internal class ReplyFrame(
    val headers: MessageHeaders,
    val payload: Payload,
)

/** How one encoded reply crosses the transport, decided before any frame is allocated. */
internal sealed interface ReplyPlan {
    /** The reply fits one message, which carries no framing headers. */
    data object Single : ReplyPlan

    /** The reply exceeds the limit; the responder sends one failure frame with [headers] instead. */
    class TooLarge(
        val size: Long,
        val limit: Long,
        val headers: MessageHeaders,
    ) : ReplyPlan

    /** The reply travels as [frames] that share [replyId], the complete size and the digest. */
    class Framed(
        val replyId: String,
        val frames: List<ReplyFrame>,
    ) : ReplyPlan
}

/**
 * Plans the reply carrying [payload]. The size check runs before any frame is allocated, and every responder uses
 * a fresh reply id from [nextReplyId], so frames from several responders on one reply address never mix.
 */
internal fun TransportLimits.planReply(
    payload: Payload,
    nextReplyId: () -> String = ::randomReplyId,
): ReplyPlan {
    val size = payload.size.toLong()
    if (size <= chunkBytes) return ReplyPlan.Single
    if (size > maxEncodedSize) {
        val headers =
            MessageHeaders.of(
                ReplyHeaders.REPLY to nextReplyId(),
                ReplyHeaders.FAILURE to ReplyHeaders.TOO_LARGE,
                ReplyHeaders.SIZE to size.toString(),
                ReplyHeaders.LIMIT to maxEncodedSize.toString(),
            )
        return ReplyPlan.TooLarge(size, maxEncodedSize, headers)
    }
    val bytes = payload.toByteArray()
    val replyId = nextReplyId()
    val digest = bytes.sha256Hex()
    val count = (bytes.size + chunkBytes - 1) / chunkBytes
    val frames =
        (0 until count).map { index ->
            val start = index * chunkBytes
            ReplyFrame(
                MessageHeaders.of(
                    ReplyHeaders.REPLY to replyId,
                    ReplyHeaders.CHUNK to "$index/$count",
                    ReplyHeaders.SIZE to size.toString(),
                    ReplyHeaders.SHA256 to digest,
                ),
                Payload.copyOf(bytes.copyOfRange(start, minOf(start + chunkBytes, bytes.size))),
            )
        }
    return ReplyPlan.Framed(replyId, frames)
}

/** Headers of the frame that tells the requester reply [replyId] stopped part way. */
internal fun interruptedReplyHeaders(replyId: String): MessageHeaders =
    MessageHeaders.of(ReplyHeaders.REPLY to replyId, ReplyHeaders.FAILURE to ReplyHeaders.INTERRUPTED)

/** Returns these headers with every [framing] header set, replacing values of the same name. */
internal fun MessageHeaders.withFraming(framing: MessageHeaders): MessageHeaders =
    framing.fold(this) { headers, (name, values) -> values.fold(headers.remove(name)) { result, value -> result.plus(name, value) } }

private fun MessageHeaders.withoutFraming(): MessageHeaders = ReplyHeaders.all.fold(this) { headers, name -> headers.remove(name) }

private fun randomReplyId(): String = UUID.randomUUID().toString().replace("-", "")

/**
 * Assembles the replies arriving on one reply address, grouping frames by reply id.
 *
 * The failure header is checked before anything else, so too large and interrupted replies never decode as empty
 * replies. A message without a reply id is a complete reply and returns unchanged. Frames may arrive in any order;
 * identical duplicates are accepted and changed ones rejected. Bounds, the complete size and the digest are verified
 * before the reply is returned without framing headers, so a caller never decodes partial bytes. Every rejection is a
 * [TransferFailure]. The assembler retains parts until their reply completes, requires serialized access, and is
 * discarded with its reply address.
 */
internal class ReplyAssembler(
    private val limits: TransportLimits,
) {
    private val pending = mutableMapOf<String, ReplyParts>()

    /** Accepts one message and returns its complete reply, or null while frames are missing. */
    fun accept(message: InboundMessage): InboundMessage? {
        val headers = message.headers
        val replyId = headers.first(ReplyHeaders.REPLY)
        headers.first(ReplyHeaders.FAILURE)?.let { failure ->
            replyId?.let(pending::remove)
            throw transferFailure(failure, headers)
        }
        if (replyId == null) return message
        try {
            val frame = parseFrame(headers, message.payload)
            val parts = pending.getOrPut(replyId) { ReplyParts(frame.count, frame.size, frame.sha256) }
            val bytes = parts.accept(frame) ?: return null
            pending.remove(replyId)
            return message.copy(payload = Payload.copyOf(bytes), headers = headers.withoutFraming())
        } catch (rejected: TransferRejected) {
            pending.remove(replyId)
            throw rejected
        }
    }

    private fun transferFailure(
        failure: String,
        headers: MessageHeaders,
    ): TransferFailure =
        when (failure) {
            ReplyHeaders.TOO_LARGE -> {
                tooLarge(headers) ?: TransferRejected("Too large reply frame lacks its size and limit")
            }

            ReplyHeaders.INTERRUPTED -> {
                TransferInterrupted()
            }

            else -> {
                TransferRejected("Unknown reply transfer failure")
            }
        }

    private fun tooLarge(headers: MessageHeaders): TransferTooLarge? {
        val size = headers.first(ReplyHeaders.SIZE)?.toLongOrNull() ?: return null
        val limit = headers.first(ReplyHeaders.LIMIT)?.toLongOrNull() ?: return null
        return TransferTooLarge(size, limit)
    }

    private fun parseFrame(
        headers: MessageHeaders,
        payload: Payload,
    ): ParsedFrame {
        val chunk = headers.first(ReplyHeaders.CHUNK)?.let(chunkPattern::matchEntire) ?: reject("Reply frame lacks its chunk position")
        val index = chunk.groupValues[1].toInt()
        val count = chunk.groupValues[2].toInt()
        val size = headers.first(ReplyHeaders.SIZE)?.takeIf(sizePattern::matches)?.toLongOrNull() ?: reject("Reply frame lacks its size")
        val sha256 = headers.first(ReplyHeaders.SHA256)?.takeIf(sha256Pattern::matches) ?: reject("Reply frame lacks its digest")
        if (count !in 1..limits.maxChunks || index !in 0 until count) reject("Reply frame position is out of bounds")
        if (size !in 0..minOf(limits.maxEncodedSize, Int.MAX_VALUE.toLong())) reject("Reply size is out of bounds")
        if (payload.size > limits.chunkBytes) reject("Reply frame exceeds the chunk size")
        return ParsedFrame(index, count, size, sha256, payload.toByteArray())
    }
}

private class ParsedFrame(
    val index: Int,
    val count: Int,
    val size: Long,
    val sha256: String,
    val bytes: ByteArray,
)

/** The frames of one reply received so far, sharing the metadata of its first frame. */
private class ReplyParts(
    private val count: Int,
    private val size: Long,
    private val sha256: String,
) {
    private val parts = arrayOfNulls<ByteArray>(count)
    private var received = 0
    private var retained = 0L

    fun accept(frame: ParsedFrame): ByteArray? {
        if (frame.count != count || frame.size != size || frame.sha256 != sha256) reject("Reply frame metadata changed during assembly")
        val prior = parts[frame.index]
        if (prior != null) {
            if (!prior.contentEquals(frame.bytes)) reject("Reply frame changed during assembly")
            return null
        }
        retained += frame.bytes.size
        if (retained > size) reject("Reply frames exceed their declared size")
        parts[frame.index] = frame.bytes
        received++
        if (received < count) return null
        val complete = ByteArrayOutputStream(size.toInt())
        parts.forEach { complete.write(requireNotNull(it)) }
        val bytes = complete.toByteArray()
        if (bytes.size.toLong() != size) reject("Reply size verification failed")
        if (bytes.sha256Hex() != sha256) reject("Reply digest verification failed")
        return bytes
    }
}

private fun reject(reason: String): Nothing = throw TransferRejected(reason)

private val chunkPattern = Regex("""(\d{1,9})/(\d{1,9})""")
private val sizePattern = Regex("""\d{1,19}""")
private val sha256Pattern = Regex("[0-9a-f]{64}")
