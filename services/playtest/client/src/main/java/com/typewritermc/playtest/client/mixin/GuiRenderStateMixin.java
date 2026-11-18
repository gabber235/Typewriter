package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** What the GUI hands the renderer is what gets drawn; the order it arrives in is paint order. */
@Mixin(GuiRenderState.class)
abstract class GuiRenderStateMixin {
    @Inject(method = "addText", at = @At("HEAD"))
    private void playtest$text(GuiTextRenderState state, CallbackInfo ci) {
        Hooks.guiText(state);
    }

    @Inject(method = "addGuiElement", at = @At("HEAD"))
    private void playtest$element(GuiElementRenderState state, CallbackInfo ci) {
        Hooks.guiElement(state);
    }

    @Inject(method = "addItem", at = @At("HEAD"))
    private void playtest$item(GuiItemRenderState state, CallbackInfo ci) {
        Hooks.guiItem(state);
    }

    @Inject(method = "blurBeforeThisStratum", at = @At("HEAD"))
    private void playtest$blur(CallbackInfo ci) {
        Hooks.guiBlur();
    }
}
