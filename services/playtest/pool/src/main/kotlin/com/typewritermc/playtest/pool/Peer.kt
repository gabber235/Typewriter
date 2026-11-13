package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Wire
import java.io.BufferedOutputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.Socket

/** One connection to the pool, named by the [Hello] it opened with. Only the pool's loop sends. */
internal class Peer(
    private val socket: Socket,
    val hello: Hello,
) {
    private val output = DataOutputStream(BufferedOutputStream(socket.getOutputStream()))

    val role: Role get() = hello.role()

    /** Sends [message]; a peer that is gone is closed, and its reader reports it as left. */
    fun send(message: Message) {
        try {
            Wire.write(output, message)
        } catch (gone: IOException) {
            System.err.println("Could not send ${message.javaClass.simpleName} to $this: ${gone.message}")
            socket.close()
        }
    }

    fun close() = socket.close()

    override fun toString() = "${hello.role()} ${hello.name()}"
}
