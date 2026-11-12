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
        if (!Demo.on) {
            if (probe.mod.n.N.stepping()) {
                // Gated stepping: the partial tick is pinned to 0, so a gated frame shows the tick's start in every rig
                // instead of the arbitrary phase stepping happened to begin at. Exactly one tick per 50 ms grant.
                deltaTicks = (float) (currentMs - lastMs) / 50f;
                lastMs = currentMs;
                int ticks = Math.round(deltaTicks);
                deltaTickResidual = 0f;
                cir.setReturnValue(ticks);
            }
            return;
        }
        lastMs = currentMs;
        deltaTicks = Demo.frameNow ? Demo.deltaTicks : 0f;
        if (Demo.frameNow) deltaTickResidual = Demo.partial;
        cir.setReturnValue(Demo.ticksNow);
    }
}
