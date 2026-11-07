package probe.mod.golden.mixin;

import net.minecraft.client.renderer.LightmapRenderStateExtractor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.golden.Golden;

/** Block light flicker is a random walk per client tick; pinned, every lit pixel keeps its value. */
@Mixin(LightmapRenderStateExtractor.class)
public class FlickerMixin {
    @Shadow
    private float blockLightFlicker;

    @Inject(method = "tick", at = @At("TAIL"))
    private void probe$still(CallbackInfo ci) {
        if (Golden.flicker) blockLightFlicker = 0f;
    }
}
