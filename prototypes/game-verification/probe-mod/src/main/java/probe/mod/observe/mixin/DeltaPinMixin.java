package probe.mod.observe.mixin;

import net.minecraft.client.DeltaTracker;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import probe.mod.observe.Drawn;

/** A4: both frames of a differential pass use the same partial tick, so only the hidden thing differs. */
@Mixin(DeltaTracker.Timer.class)
public class DeltaPinMixin {
    @Inject(method = "getGameTimeDeltaPartialTick", at = @At("RETURN"), cancellable = true)
    private void probe$pin(boolean ignoreFrozenGame, CallbackInfoReturnable<Float> cir) {
        if (Drawn.pinning) {
            if (Float.isNaN(Drawn.pinned)) Drawn.pinned = cir.getReturnValue();
            cir.setReturnValue(Drawn.pinned);
        }
    }
}
