package com.typewritermc.playtest.wire;

import java.io.BufferedInputStream;
import java.io.BufferedOutputStream;
import java.io.DataInputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.UncheckedIOException;
import java.net.InetAddress;
import java.net.Socket;
import java.util.function.Consumer;

/**
 * A game part's connection to the pool: Paper and the client each hold one. One daemon thread reads
 * and hands every message on; any thread may send.
 */
public final class Link {
    private final DataOutputStream output;

    private Link(Socket socket) throws IOException {
        this.output = new DataOutputStream(new BufferedOutputStream(socket.getOutputStream()));
    }

    /**
     * Connects to the pool on the loopback {@code port} and sends {@code hello}. The reader thread hands
     * each message to {@code receive} and calls {@code lost} once when the connection ends.
     */
    public static Link open(int port, Message.Hello hello, Consumer<Message> receive, Consumer<IOException> lost) throws IOException {
        var socket = new Socket(InetAddress.getLoopbackAddress(), port);
        socket.setTcpNoDelay(true);
        var link = new Link(socket);
        link.send(hello);
        var reader = new Thread(() -> {
            try {
                var input = new DataInputStream(new BufferedInputStream(socket.getInputStream()));
                while (true) receive.accept(Wire.read(input));
            } catch (IOException closed) {
                lost.accept(closed);
            }
        }, "playtest-pool-link");
        reader.setDaemon(true);
        reader.start();
        return link;
    }

    /** Sends one message; a broken connection throws, since the part cannot work without the pool. */
    public void send(Message message) {
        try {
            synchronized (output) {
                Wire.write(output, message);
            }
        } catch (IOException broken) {
            throw new UncheckedIOException("the game pool connection broke", broken);
        }
    }
}
