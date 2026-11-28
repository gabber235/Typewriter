package com.typewritermc.playtest.client.mixin;

import com.mojang.renderpearl.api.device.GpuSurface;
import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.Gui;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.network.PacketProcessor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** The step clock around each loop, the way out of a Paper's world, and the frame gate inside {@code renderFrame}. */
@Mixin(Minecraft.class)
abstract class MinecraftMixin {
    @Inject(method = "runTick", at = @At("HEAD"))
    private void playtest$beforeRunTick(boolean advanceGameTime, CallbackInfo ci) {
        Hooks.beforeRunTick((Minecraft) (Object) this);
    }

    /** The loop's own packet handling holds off while a record is due, as {@code Stepper.processPackets} says. */
    @Redirect(method = "runTick", at = @At(value = "INVOKE", target = "Lnet/minecraft/network/PacketProcessor;processQueuedPackets()V"))
    private void playtest$processPackets(PacketProcessor processor) {
        Hooks.processPackets((Minecraft) (Object) this);
    }

    @Inject(method = "tick", at = @At("TAIL"))
    private void playtest$afterTick(CallbackInfo ci) {
        Hooks.afterTick((Minecraft) (Object) this);
    }

    @Inject(method = "disconnect(Lnet/minecraft/client/gui/screens/Screen;ZZ)V", at = @At("HEAD"))
    private void playtest$leavingWorld(Screen screen, boolean keepResourcePacks, boolean stopSound, CallbackInfo ci) {
        Hooks.leavingWorld((Minecraft) (Object) this);
    }

    /** While the client steps, the GUI's update runs once per tick, not once per frame ({@code OncePerTick}). */
    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/gui/Gui;update()V"))
    private void playtest$guiUpdate(Gui gui) {
        if (Hooks.updatesGui()) gui.update();
    }

    /** Without an acquired texture the frame's blit and present skip themselves, so no frame reaches the window. */
    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lcom/mojang/renderpearl/api/device/GpuSurface;acquireNextTexture()V"))
    private void playtest$acquire(GpuSurface surface) throws Exception {
        if (Hooks.beginFrame((Minecraft) (Object) this)) surface.acquireNextTexture();
    }

    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/renderer/GameRenderer;extract(Lnet/minecraft/client/DeltaTracker;Z)V"))
    private void playtest$extract(GameRenderer renderer, DeltaTracker delta, boolean advance) {
        if (Hooks.extracts()) renderer.extract(delta, advance);
    }

    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/renderer/GameRenderer;render()V"))
    private void playtest$render(GameRenderer renderer) {
        Hooks.render((Minecraft) (Object) this, renderer);
    }
}
