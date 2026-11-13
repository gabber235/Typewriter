package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** Whether the next mouse motion only sets the pointer's start, as the first one after a grab does. */
@Mixin(MouseHandler.class)
public interface MouseHandlerAccessor {
    @Accessor("ignoreFirstMove")
    boolean playtest$ignoreFirstMove();
}
