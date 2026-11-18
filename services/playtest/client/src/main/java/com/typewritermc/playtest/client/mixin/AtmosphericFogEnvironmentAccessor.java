package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.renderer.fog.environment.AtmosphericFogEnvironment;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** How far rain has thickened the open air fog, which eases toward the rain each tick. */
@Mixin(AtmosphericFogEnvironment.class)
public interface AtmosphericFogEnvironmentAccessor {
    @Accessor("rainFogMultiplier")
    void playtest$setRainFogMultiplier(float multiplier);
}
