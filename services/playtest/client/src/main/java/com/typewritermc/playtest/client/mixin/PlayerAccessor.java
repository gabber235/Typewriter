package com.typewritermc.playtest.client.mixin;

import net.minecraft.world.entity.player.Player;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The ticks in which a second press of jump toggles flying. */
@Mixin(Player.class)
public interface PlayerAccessor {
    @Accessor("jumpTriggerTime")
    void playtest$setJumpTriggerTime(int ticks);
}
