package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.DeltaTracker;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/**
 * The share of a tick a frame draws past the last tick. A stepped client draws every frame, drawn or
 * only perceived, at the end of its last tick, as vanilla does while the game is frozen: whatever eases
 * between two ticks shows the tick that ran, not the one before it. A clip's frames between two ticks
 * draw at their own share of the way from the tick before to the last tick.
 */
@Mixin(DeltaTracker.Timer.class)
abstract class TimerMixin {
    @Inject(method = "getGameTimeDeltaPartialTick", at = @At("HEAD"), cancellable = true)
    private void playtest$endOfTick(boolean runsNormally, CallbackInfoReturnable<Float> cir) {
        if (Hooks.stepsPartialTick()) cir.setReturnValue(Hooks.partialTick());
    }
}
