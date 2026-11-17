package com.typewritermc.playtest.wire

import build.skir.Serializer
import build.skir.reflection.RecordDescriptorBase
import skirout.harness.v1.wire.Message
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException
import java.io.IOException

/**
 * The framing of every connection: one frame is an int length, then that many bytes, the Skir binary
 * form of one [Message]. Skir writes a value but never says on a stream where it ends, so the length
 * keeps; the message itself, its type included, is all Skir's. Every part ships from one build, so a
 * frame whose message this build does not know is a fault, as is a frame over [MAX_FRAME].
 */
object Wire {
    /** A perception record is a few hundred bytes; a frame this large is a fault, not a message. */
    const val MAX_FRAME = 16 shl 20

    /** Writes one frame and flushes it. */
    @JvmStatic
    @Throws(IOException::class)
    fun write(
        out: DataOutputStream,
        message: Message,
    ) {
        val bytes = Message.serializer.toBytes(message)
        if (bytes.size > MAX_FRAME) throw WireException("a ${message.kind} message of ${bytes.size} bytes is over the frame limit")
        out.writeInt(bytes.size)
        bytes.write(out)
        out.flush()
    }

    /**
     * Reads one frame. Throws [EOFException] when the stream ends between frames and [WireException]
     * when a frame is malformed or ends early.
     */
    @JvmStatic
    @Throws(IOException::class)
    fun read(input: DataInputStream): Message {
        val first = input.read()
        if (first < 0) throw EOFException("the stream ended between frames")
        val length =
            try {
                first shl 24 or (input.readUnsignedByte() shl 16) or (input.readUnsignedByte() shl 8) or input.readUnsignedByte()
            } catch (_: EOFException) {
                throw WireException("the stream ended inside a frame's length")
            }
        if (length !in 1..MAX_FRAME) throw WireException("a frame of $length bytes is outside 1 to $MAX_FRAME bytes")
        val frame = ByteArray(length)
        try {
            input.readFully(frame)
        } catch (_: EOFException) {
            throw WireException("the stream ended inside a frame of $length bytes")
        }
        val message = decode(Message.serializer, frame)
        if (message.kind == Message.Kind.UNKNOWN) throw WireException("a frame of $length bytes holds no message this build knows")
        return message
    }

    /**
     * The value of [serializer]'s type whose Skir binary form is all of [bytes]; bytes that end early,
     * carry more or hold no such value are refused.
     */
    @JvmStatic
    @Throws(WireException::class)
    fun <T> decode(
        serializer: Serializer<T>,
        bytes: ByteArray,
    ): T =
        try {
            serializer.fromBytes(bytes)
        } catch (cut: IOException) {
            throw refused(serializer, bytes, cut)
        } catch (malformed: IllegalArgumentException) {
            // Skir refuses extra bytes, a wire type its field does not take and bytes that are no JSON either.
            throw refused(serializer, bytes, malformed)
        }

    private fun refused(
        serializer: Serializer<*>,
        bytes: ByteArray,
        cause: Exception,
    ): WireException {
        val type = (serializer.typeDescriptor as? RecordDescriptorBase)?.name ?: "value"
        return WireException("${bytes.size} bytes hold no $type: ${cause.message}").apply { initCause(cause) }
    }
}
