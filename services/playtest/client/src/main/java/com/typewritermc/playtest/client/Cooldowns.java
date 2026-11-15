package com.typewritermc.playtest.client;

import com.typewritermc.playtest.client.mixin.LocalPlayerAccessor;
import com.typewritermc.playtest.client.mixin.MinecraftAccessor;
import com.typewritermc.playtest.client.mixin.MultiPlayerGameModeAccessor;
import com.typewritermc.playtest.client.mixin.PlayerAccessor;
import net.minecraft.client.Minecraft;

/**
 * What the client counts down between the player's inputs, so that an input would still wait on what
 * an earlier attempt did: the delay after a broken block before the next starts to break, the delay
 * after an attack that hit nothing or a use, and the windows in which a second press of jump flies or
 * of forward sprints. A new attempt starts them as a client that just joined does. Render thread only.
 */
final class Cooldowns {
    private Cooldowns() {}

    /** A new attempt: no input waits on one before it. */
    static void reset(Minecraft mc) {
        if (mc.gameMode != null) ((MultiPlayerGameModeAccessor) mc.gameMode).playtest$setDestroyDelay(0);
        ((MinecraftAccessor) mc).playtest$setMissTime(0);
        ((MinecraftAccessor) mc).playtest$setRightClickDelay(0);
        if (mc.player != null) {
            ((PlayerAccessor) mc.player).playtest$setJumpTriggerTime(0);
            ((LocalPlayerAccessor) mc.player).playtest$setSprintTriggerTime(0);
        }
    }
}
