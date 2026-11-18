package com.typewritermc.playtest.client.mixin;

import com.mojang.renderpearl.api.pipeline.RenderPipeline;
import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.Hud;
import net.minecraft.resources.Identifier;
import net.minecraft.world.entity.player.Player;
import net.minecraft.world.item.ItemStack;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/**
 * Names what the HUD draws right now: the element adding text, the hotbar slot an item stands in, the
 * hotbar's selection frame, and the spyglass overlay.
 */
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

    /** The hotbar draws slot 0 to 8 with seeds 1 to 9, then the off hand with seed 10. */
    @Inject(method = "extractSlot", at = @At("HEAD"))
    private void playtest$slot(GuiGraphicsExtractor graphics, int x, int y, DeltaTracker delta, Player player, ItemStack stack, int seed, CallbackInfo ci) {
        if (seed <= 9) Hooks.itemSlot("hotbar", seed - 1);
        else Hooks.itemSlot("offhand", -1);
    }

    @Inject(method = "extractSlot", at = @At("RETURN"))
    private void playtest$slotDone(GuiGraphicsExtractor graphics, int x, int y, DeltaTracker delta, Player player, ItemStack stack, int seed, CallbackInfo ci) {
        Hooks.itemSlotDone();
    }

    @Redirect(
            method = "extractItemHotbar",
            at = @At(value = "INVOKE", target = "Lnet/minecraft/client/gui/GuiGraphicsExtractor;blitSprite(Lcom/mojang/renderpearl/api/pipeline/RenderPipeline;Lnet/minecraft/resources/Identifier;IIII)V"))
    private void playtest$hotbarSprite(GuiGraphicsExtractor graphics, RenderPipeline pipeline, Identifier sprite, int x, int y, int width, int height) {
        boolean selection = sprite.getNamespace().equals("minecraft") && sprite.getPath().equals("hud/hotbar_selection");
        if (selection) Hooks.selectionFrame(true);
        graphics.blitSprite(pipeline, sprite, x, y, width, height);
        if (selection) Hooks.selectionFrame(false);
    }

    @Inject(method = "extractSpyglassOverlay", at = @At("HEAD"))
    private void playtest$spyglass(GuiGraphicsExtractor graphics, float scale, CallbackInfo ci) {
        Hooks.scoped();
    }
}
