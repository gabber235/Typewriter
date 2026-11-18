package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.MultiPlayerGameModeAccessor;
import net.minecraft.client.Minecraft;

/**
 * What the client counts down between the player's inputs and keeps across attempts: the delay after a
 * broken block before the next starts to break, which counts down only while the player keeps breaking.
 * The client's other input delays count down every tick or clear once the button is up, so none outlasts
 * the ticks between two attempts. A new attempt starts the break delay as a client that just joined
 * does. Render thread only.
 */
final class Cooldowns {
    private Cooldowns() {}

    /** A new attempt: no break waits on one before it. */
    static void reset(Minecraft mc) {
        if (mc.gameMode != null) ((MultiPlayerGameModeAccessor) mc.gameMode).playtest$setDestroyDelay(0);
    }
}
