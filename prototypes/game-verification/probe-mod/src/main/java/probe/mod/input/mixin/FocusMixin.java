package probe.mod.input.mixin;

import com.mojang.blaze3d.platform.Window;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import probe.mod.input.Input;

/** A person's window has focus; a background test window does not. Spike J fakes it on request. */
@Mixin(Window.class)
public class FocusMixin {
    @Inject(method = "isFocused", at = @At("HEAD"), cancellable = true)
    private void probe$focused(CallbackInfoReturnable<Boolean> cir) {
        if (Input.fakeFocus) cir.setReturnValue(true);
    }
}
