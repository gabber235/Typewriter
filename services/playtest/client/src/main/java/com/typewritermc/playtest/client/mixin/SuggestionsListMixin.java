package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Names the command suggestion list's text: one run per suggestion it shows, top to bottom. */
@Mixin(targets = "net.minecraft.client.gui.components.CommandSuggestions$SuggestionsList")
abstract class SuggestionsListMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void playtest$list(GuiGraphicsExtractor graphics, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.enter("suggestions");
    }

    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void playtest$listDone(GuiGraphicsExtractor graphics, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.leave();
    }
}
