package com.typewritermc.playtest.client;

/**
 * The client's own work a tick's record and ack wait for, as Paper's ticks wait for a player's counted
 * work: the events an input queued right after the tick, which the client handles in its next poll and
 * whose packets must reach Paper before the ack does. While they wait, the client perceives the tick
 * again in its next loop pass instead of recording and acking it. Render thread only.
 */
final class ClientWork {
    private ClientWork() {}

    /** Whether the frame perceived now may record and ack its tick. */
    static boolean done() {
        return !Inputs.unpolled();
    }
}
