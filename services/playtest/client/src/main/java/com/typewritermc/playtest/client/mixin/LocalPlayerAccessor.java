package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.player.LocalPlayer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The ticks in which a second press of forward starts sprinting. */
@Mixin(LocalPlayer.class)
public interface LocalPlayerAccessor {
    @Accessor("sprintTriggerTime")
    void playtest$setSprintTriggerTime(int ticks);
}
