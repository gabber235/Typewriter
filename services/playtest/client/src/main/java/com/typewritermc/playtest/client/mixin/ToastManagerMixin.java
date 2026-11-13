package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.toasts.ToastManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Names the text toasts draw in the corner of the screen as the {@code toast} element. */
@Mixin(ToastManager.class)
abstract class ToastManagerMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void playtest$toasts(GuiGraphicsExtractor graphics, CallbackInfo ci) {
        Hooks.enter("toast");
    }

    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void playtest$toastsDone(GuiGraphicsExtractor graphics, CallbackInfo ci) {
        Hooks.leave();
    }
}
