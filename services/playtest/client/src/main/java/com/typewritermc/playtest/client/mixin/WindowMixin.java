package com.typewritermc.playtest.client.mixin;

import com.mojang.blaze3d.platform.Window;
import com.typewritermc.playtest.client.Hooks;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/** A window without real focus is focused as it would be in front of a person. */
@Mixin(Window.class)
abstract class WindowMixin {
    @Inject(method = "isFocused", at = @At("HEAD"), cancellable = true)
    private void playtest$focused(CallbackInfoReturnable<Boolean> cir) {
        if (Hooks.pretendsFocus()) cir.setReturnValue(true);
    }
}
