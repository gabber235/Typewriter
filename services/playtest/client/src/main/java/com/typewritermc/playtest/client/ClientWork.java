package com.typewritermc.playtest.client;

/**
 * The client's own work a tick's ack waits for, as Paper's ticks wait for a player's counted work: the
 * events an input queued right after the tick, until the game took each of them ({@link OwnInput}), whose
 * packets must reach Paper before the ack does. The tick's record does not wait: it shows the tick as it
 * ended, before those events. Render thread only.
 */
final class ClientWork {
    private ClientWork() {}

    /** Whether the recorded tick may be acked. */
    static boolean done() {
        return !Inputs.pending();
    }
}
