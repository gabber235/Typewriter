package com.typewritermc.playtest.client;

import java.io.IOException;
import java.io.OutputStream;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.function.IntSupplier;

/**
 * Hands a clip's frames to its encoder on a thread of its own, in the order they were drawn, so the
 * render thread waits on the encoder only when it falls 8 frames behind, and when the clip finishes.
 */
final class ClipWriter {
    private static final byte[] END = new byte[0];

    private final BlockingQueue<byte[]> queue = new ArrayBlockingQueue<>(8);
    private final IntSupplier exit;
    private final Thread thread;
    private volatile IOException failed;
    private volatile int written;

    /** Writes into {@code encoder}; {@code exit} waits for the encoder once its input closed and returns its exit code. */
    ClipWriter(OutputStream encoder, IntSupplier exit) {
        this.exit = exit;
        this.thread = Thread.ofPlatform().daemon().name("playtest clip").start(() -> drain(encoder));
    }

    /** Queues one frame's pixels. */
    void add(byte[] frame) {
        try {
            queue.put(frame);
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
        }
    }

    /** Waits until every frame reached the encoder and the encoder finished; returns the frames the clip holds. */
    int finish() throws IOException {
        add(END);
        try {
            thread.join();
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
            throw new IOException("interrupted while the clip finished", interrupted);
        }
        int code = exit.getAsInt();
        if (failed != null) throw new IOException("the encoder stopped taking frames: " + failed.getMessage(), failed);
        if (code != 0) throw new IOException("the encoder exited with code " + code);
        return written;
    }

    /** Writes each queued frame until the end; after a failed write it only drains, so the render thread never blocks. */
    private void drain(OutputStream encoder) {
        try (encoder) {
            for (byte[] frame = queue.take(); frame != END; frame = queue.take()) {
                if (failed != null) continue;
                try {
                    encoder.write(frame);
                    written++;
                } catch (IOException broken) {
                    failed = broken;
                }
            }
        } catch (IOException closing) {
            if (failed == null) failed = closing;
        } catch (InterruptedException interrupted) {
            Thread.currentThread().interrupt();
        }
    }
}
