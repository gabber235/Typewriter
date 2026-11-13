package com.typewritermc.playtest.client.mixin;

import com.mojang.blaze3d.platform.InputConstants;
import com.mojang.blaze3d.platform.Window;
import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;

/**
 * The client may run on the developer's machine, where it never grabs the real mouse: the game still
 * takes and gives back the mouse as a grabbed mouse, but the operating system cursor stays free.
 */
@Mixin(MouseHandler.class)
abstract class MouseHandlerMixin {
    @Redirect(method = "grabMouse", at = @At(value = "INVOKE", target = "Lcom/mojang/blaze3d/platform/InputConstants;grabMouse(Lcom/mojang/blaze3d/platform/Window;DD)V"))
    private void playtest$grab(Window window, double x, double y) {
        if (!Hooks.pretendsFocus()) InputConstants.grabMouse(window, x, y);
    }

    @Redirect(method = "releaseMouse", at = @At(value = "INVOKE", target = "Lcom/mojang/blaze3d/platform/InputConstants;releaseMouse(Lcom/mojang/blaze3d/platform/Window;DD)V"))
    private void playtest$release(Window window, double x, double y) {
        if (!Hooks.pretendsFocus()) InputConstants.releaseMouse(window, x, y);
    }
}
