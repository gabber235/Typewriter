package probe.mod.streammix;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.toasts.ToastManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Tag;

@Mixin(ToastManager.class)
public class ToastTagMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void probe$push(GuiGraphicsExtractor g, CallbackInfo ci) {
        Tag.push("toast");
    }

    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void probe$pop(GuiGraphicsExtractor g, CallbackInfo ci) {
        Tag.pop();
    }
}
