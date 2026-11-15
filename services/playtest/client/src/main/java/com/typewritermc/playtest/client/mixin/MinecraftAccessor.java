package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The ticks an attack that hit nothing, and a use, keep the next one from starting. */
@Mixin(Minecraft.class)
public interface MinecraftAccessor {
    @Accessor("missTime")
    void playtest$setMissTime(int ticks);

    @Accessor("rightClickDelay")
    void playtest$setRightClickDelay(int ticks);
}
