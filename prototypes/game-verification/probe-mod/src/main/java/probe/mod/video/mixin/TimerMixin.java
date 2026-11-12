package probe.mod.video.mixin;

import net.minecraft.client.DeltaTracker;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import probe.mod.video.Demo;

/** Demo frames: the tick count and partial tick of this loop come from the demo schedule, not from milliseconds. */
@Mixin(DeltaTracker.Timer.class)
public class TimerMixin {
    @Shadow private float deltaTicks;
    @Shadow private float deltaTickResidual;
    @Shadow private long lastMs;

    @Inject(method = "advanceGameTime", at = @At("HEAD"), cancellable = true)
    private void probe$demo(long currentMs, CallbackInfoReturnable<Integer> cir) {
        if (!Demo.on) return;
        lastMs = currentMs;
        deltaTicks = Demo.frameNow ? Demo.deltaTicks : 0f;
        if (Demo.frameNow) deltaTickResidual = Demo.partial;
        cir.setReturnValue(Demo.ticksNow);
    }
}
