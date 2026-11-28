package com.typewritermc.playtest.client;

/**
 * Work vanilla runs once per frame that runs once per tick while the client steps, in the first frame
 * after the tick. How many frames run between two ticks depends on wall clock, so work that moves on
 * in every frame, as the GUI's update moves a toast from queued to shown and then starts its slide,
 * would show its change at a wall clock dependent tick.
 */
final class OncePerTick {
    private boolean due;

    /** A tick ran: the next frame runs the work. */
    void ticked() {
        due = true;
    }

    /** Whether this frame runs the work: the first frame after a tick does, every other frame does not. */
    boolean runs() {
        boolean runs = due;
        due = false;
        return runs;
    }

    /** The client left its Paper: no tick of it is left to run the work for. */
    void reset() {
        due = false;
    }
}
