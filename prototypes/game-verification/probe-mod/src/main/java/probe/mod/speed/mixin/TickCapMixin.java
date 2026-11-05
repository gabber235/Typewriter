package probe.mod.speed.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import net.minecraft.client.multiplayer.ClientLevel;
import probe.mod.speed.Speed;

/** Removes the Math.max(50, mspt) cap, so the client follows server tick rates above 20. */
@Mixin(Minecraft.class)
public class TickCapMixin {
    @Shadow public ClientLevel level;

    @Inject(method = "getTickTargetMillis", at = @At("HEAD"), cancellable = true)
    private void probe$uncap(float fallback, CallbackInfoReturnable<Float> cir) {
        if (Speed.uncapped && this.level != null && this.level.tickRateManager().runsNormally()) {
            cir.setReturnValue(this.level.tickRateManager().millisecondsPerTick());
        }
    }
}
