package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import net.minecraft.world.inventory.Slot;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Names the items a screen with slots draws: one per slot, by the screen's slot number, and the one on the pointer. */
@Mixin(AbstractContainerScreen.class)
abstract class AbstractContainerScreenMixin {
    @Inject(method = "extractSlot", at = @At("HEAD"))
    private void playtest$slot(GuiGraphicsExtractor graphics, Slot slot, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.itemSlot("screen", slot.index);
    }

    @Inject(method = "extractSlot", at = @At("RETURN"))
    private void playtest$slotDone(GuiGraphicsExtractor graphics, Slot slot, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.itemSlotDone();
    }

    @Inject(method = "extractCarriedItem", at = @At("HEAD"))
    private void playtest$carried(GuiGraphicsExtractor graphics, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.itemSlot("carried", -1);
    }

    @Inject(method = "extractCarriedItem", at = @At("RETURN"))
    private void playtest$carriedDone(GuiGraphicsExtractor graphics, int mouseX, int mouseY, CallbackInfo ci) {
        Hooks.itemSlotDone();
    }
}
