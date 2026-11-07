package probe.mod.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.Probe;

@Mixin(Minecraft.class)
public class MinecraftMixin {
    @Inject(method = "tick", at = @At("TAIL"))
    private void probe$tick(CallbackInfo ci) {
        Probe.onTick((Minecraft) (Object) this);
    }

    @Inject(method = "renderFrame", at = @At("TAIL"))
    private void probe$frame(boolean advanceGameTime, CallbackInfo ci) {
        Probe.onFrame((Minecraft) (Object) this);
    }
}
