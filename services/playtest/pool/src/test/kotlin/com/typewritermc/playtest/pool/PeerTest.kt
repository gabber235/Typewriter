package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Wire
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import skirout.harness.v1.wire.Hello
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.Role
import java.io.DataInputStream
import java.io.EOFException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

val PeerTest by testSuite {
    test("sending to a peer that never reads leaves the pool's loop free to serve the others") {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            Socket(server.inetAddress, server.localPort).use { _ ->
                val peer = Peer(server.accept(), Hello(role = Role.SESSION, name = "session"))
                // Far more than any socket buffer holds, so a send that waits for the reader would stall.
                val reason = "x".repeat(64 * 1024)

                val loop = thread { repeat(256) { peer.send(Message.createRefused(reason = reason)) } }
                loop.join(2_000)
                val stalled = loop.isAlive
                peer.close()

                stalled shouldBe false
            }
        }
    }

    test("a last message reaches the peer after the ones sent before it, and then the connection closes") {
        ServerSocket(0, 1, InetAddress.getLoopbackAddress()).use { server ->
            Socket(server.inetAddress, server.localPort).use { other ->
                val peer = Peer(server.accept(), Hello(role = Role.SESSION, name = "session"))
                val reader = DataInputStream(other.getInputStream())
                peer.send(Message.ENDED)
                peer.sendLast(Message.createRefused(reason = "the run named another file"))

                Wire.read(reader) shouldBe Message.ENDED
                Wire.read(reader) shouldBe Message.createRefused(reason = "the run named another file")
                shouldThrow<EOFException> { Wire.read(reader) }
            }
        }
    }
}
