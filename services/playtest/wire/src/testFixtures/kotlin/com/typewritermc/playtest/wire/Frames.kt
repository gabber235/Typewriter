package com.typewritermc.playtest.wire

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

/** A frame by hand: the length, the type byte and the body, for frames [Wire.write] never writes. */
fun handFrame(
    type: Int,
    body: ByteArray,
    length: Int = body.size + 1,
): ByteArray {
    val bytes = ByteArrayOutputStream()
    DataOutputStream(bytes).apply {
        writeInt(length)
        writeByte(type)
        write(body)
    }
    return bytes.toByteArray()
}
