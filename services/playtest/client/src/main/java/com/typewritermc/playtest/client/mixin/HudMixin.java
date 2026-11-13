package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.Hud;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Names the HUD element whose extract call is adding text right now. */
@Mixin(Hud.class)
abstract class HudMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void playtest$hud(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        Hooks.beginHud();
    }

    @Inject(method = "extractChat", at = @At("HEAD"))
    private void playtest$chat(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        Hooks.enter("chat");
    }

    @Inject(method = "extractChat", at = @At("RETURN"))
    private void playtest$chatDone(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        Hooks.leave();
    }
}
