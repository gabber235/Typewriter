package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.Camera;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The field of view's factor, which eases toward what the player does (looking through a spyglass) each tick. */
@Mixin(Camera.class)
public interface CameraAccessor {
    @Accessor("fovModifier")
    void playtest$setFovModifier(float modifier);

    @Accessor("oldFovModifier")
    void playtest$setOldFovModifier(float modifier);
}
