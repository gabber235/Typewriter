package probe.mod.mixin;

import com.mojang.blaze3d.platform.InputConstants;
import com.mojang.blaze3d.platform.Window;
import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.input.Input;

/**
 * This client may run on the developer's machine; it never takes or moves the real mouse.
 * probe.grab: cancel (old default, never grabbed), fake (grabbed state as for a person, no SDL call),
 * real (vanilla SDL grab and warp; only on a virtual X server).
 */
@Mixin(MouseHandler.class)
public class MouseHandlerMixin {
    @Inject(method = "grabMouse", at = @At("HEAD"), cancellable = true)
    private void probe$noGrab(CallbackInfo ci) {
        if ("cancel".equals(Input.grab)) ci.cancel();
    }

    @Redirect(method = "grabMouse", at = @At(value = "INVOKE", target = "Lcom/mojang/blaze3d/platform/InputConstants;grabMouse(Lcom/mojang/blaze3d/platform/Window;DD)V"))
    private void probe$sdlGrab(Window window, double x, double y) {
        if ("real".equals(Input.grab)) InputConstants.grabMouse(window, x, y);
    }

    @Redirect(method = "releaseMouse", at = @At(value = "INVOKE", target = "Lcom/mojang/blaze3d/platform/InputConstants;releaseMouse(Lcom/mojang/blaze3d/platform/Window;DD)V"))
    private void probe$sdlRelease(Window window, double x, double y) {
        if ("real".equals(Input.grab)) InputConstants.releaseMouse(window, x, y);
    }
}
