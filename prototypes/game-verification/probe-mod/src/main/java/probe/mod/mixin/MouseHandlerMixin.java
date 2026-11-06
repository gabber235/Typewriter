package probe.mod.mixin;

import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** This client runs on the developer's machine; it never takes the mouse. */
@Mixin(MouseHandler.class)
public class MouseHandlerMixin {
    @Inject(method = "grabMouse", at = @At("HEAD"), cancellable = true)
    private void probe$noGrab(CallbackInfo ci) {
        ci.cancel();
    }
}
