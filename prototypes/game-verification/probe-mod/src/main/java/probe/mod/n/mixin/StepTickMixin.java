package probe.mod.n.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.n.N;

@Mixin(Minecraft.class)
public class StepTickMixin {
    @Inject(method = "runTick", at = @At("HEAD"))
    private void probe$loop(boolean advanceGameTime, CallbackInfo ci) {
        N.beforeRunTick((Minecraft) (Object) this);
    }

    @Inject(method = "tick", at = @At("TAIL"))
    private void probe$tail(CallbackInfo ci) {
        N.afterTick((Minecraft) (Object) this);
    }
}
