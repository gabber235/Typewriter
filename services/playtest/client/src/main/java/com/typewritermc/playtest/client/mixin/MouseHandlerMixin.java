package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** The client may run on the developer's machine, so it never grabs the real mouse. */
@Mixin(MouseHandler.class)
abstract class MouseHandlerMixin {
    @Inject(method = "grabMouse", at = @At("HEAD"), cancellable = true)
    private void playtest$noGrab(CallbackInfo ci) {
        ci.cancel();
    }
}
