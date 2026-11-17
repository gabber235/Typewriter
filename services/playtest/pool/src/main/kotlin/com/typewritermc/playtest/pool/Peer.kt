package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Wire
import java.io.BufferedOutputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.Socket
import java.util.concurrent.LinkedBlockingQueue
import kotlin.concurrent.thread

/**
 * One connection to the pool, named by the [Hello] it opened with. Only the pool's loop sends, and a
 * send only queues: a thread of the peer's own writes, so a peer that stops reading holds up no other.
 */
internal class Peer(
    private val socket: Socket,
    val hello: Hello,
) {
    private val output = DataOutputStream(BufferedOutputStream(socket.getOutputStream()))
    private val outgoing = LinkedBlockingQueue<Outgoing>()
    private val writer = thread(name = "playtest-pool-send-$this", isDaemon = true) { write() }

    val role: Role get() = hello.role()

    /** Sends [message] after the ones sent before it; a peer that is gone is closed, and its reader reports it as left. */
    fun send(message: Message) {
        if (!socket.isClosed) outgoing.put(Outgoing(message, last = false))
    }

    /** Sends [message] after the ones sent before it, and then closes the connection. */
    fun sendLast(message: Message) {
        if (!socket.isClosed) outgoing.put(Outgoing(message, last = true))
    }

    /** Closes the connection now, dropping what was not sent yet. */
    fun close() {
        socket.close()
        writer.interrupt()
    }

    private fun write() {
        var sending: Message? = null
        try {
            while (true) {
                val next = outgoing.take()
                sending = next.message
                Wire.write(output, next.message)
                if (next.last) return close()
            }
        } catch (gone: IOException) {
            if (!socket.isClosed) System.err.println("Could not send ${sending?.javaClass?.simpleName} to $this: ${gone.message}")
            socket.close()
        } catch (_: InterruptedException) {
            // The pool closed the connection, so nothing is left to send.
            return
        }
    }

    override fun toString() = "${hello.role()} ${hello.name()}"

    private class Outgoing(
        val message: Message,
        val last: Boolean,
    )
}
