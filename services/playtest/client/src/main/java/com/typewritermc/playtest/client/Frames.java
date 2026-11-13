package com.typewritermc.playtest.client;

import net.minecraft.client.Minecraft;

/**
 * Which frames run while the client steps. Before the first step the client draws as any client does.
 * While stepping, a frame runs only after a tick ran or when a record is forced, and then it perceives
 * without drawing: extract builds what the player would see and {@link NoDraw} keeps the world state a
 * later drawn frame needs, while nothing reaches the GPU or the window.
 */
final class Frames {
    enum Mode {
        DRAW,
        PERCEIVE,
        SKIP,
    }

    private static Mode mode = Mode.DRAW;

    private Frames() {}

    /** Start of {@code Minecraft.renderFrame}, where it acquires the window's next texture. */
    static Mode begin(Minecraft mc) {
        if (!Stepper.stepping()) mode = Mode.DRAW;
        else mode = Stepper.perceiveFrame() ? Mode.PERCEIVE : Mode.SKIP;
        if (mode != Mode.SKIP) Perceiver.beginFrame(mc);
        return mode;
    }

    static Mode mode() {
        return mode;
    }

    /** After the frame's draw or perceive step. */
    static void end() {
        if (mode == Mode.SKIP) return;
        if (mode == Mode.PERCEIVE || Perceiver.forced()) Perceiver.endFrame(Minecraft.getInstance(), Stepper.lastRan());
        if (mode == Mode.PERCEIVE) Stepper.perceived();
    }
}
