package com.typewritermc.playtest.wire

import skirout.harness.v1.wire.Message
import java.io.ByteArrayInputStream
import java.io.ByteArrayOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.EOFException

/** The bytes [Wire.write] puts on a connection for these messages, in order. */
fun framed(vararg messages: Message): ByteArray {
    val bytes = ByteArrayOutputStream()
    val out = DataOutputStream(bytes)
    messages.forEach { Wire.write(out, it) }
    return bytes.toByteArray()
}

/** Every message [Wire.read] finds in these bytes, until they end between two frames. */
fun ByteArray.readFrames(): List<Message> {
    val input = DataInputStream(ByteArrayInputStream(this))
    return buildList {
        while (true) {
            try {
                add(Wire.read(input))
            } catch (_: EOFException) {
                return@buildList
            }
        }
    }
}

/** A frame by hand: the length and the bytes, for frames [Wire.write] never writes. */
fun handFrame(
    bytes: ByteArray,
    length: Int = bytes.size,
): ByteArray {
    val frame = ByteArrayOutputStream()
    DataOutputStream(frame).apply {
        writeInt(length)
        write(bytes)
    }
    return frame.toByteArray()
}
