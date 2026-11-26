package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.renderer.LightmapRenderStateExtractor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Block light glows steadily. Vanilla walks the block light flicker at random every client tick, from a
 * random source of its own, so a floor a lamp lights would draw another shade from one frame to the
 * next. The flicker stays at 0, the middle of its walk, and each tick still marks its light for the
 * lightmap to take.
 */
@Mixin(LightmapRenderStateExtractor.class)
abstract class LightmapRenderStateExtractorMixin {
    @Shadow
    private float blockLightFlicker;

    @Inject(method = "tick", at = @At("RETURN"))
    private void playtest$steadyBlockLight(CallbackInfo ci) {
        blockLightFlicker = 0.0F;
    }
}
