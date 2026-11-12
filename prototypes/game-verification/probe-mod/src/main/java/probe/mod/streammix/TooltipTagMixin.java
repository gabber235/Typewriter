package probe.mod.streammix;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Tag;

/** Tooltips are deferred: setTooltipForNextFrame stores a Runnable that extractDeferredElements runs. */
@Mixin(GuiGraphicsExtractor.class)
public class TooltipTagMixin {
    @Inject(method = "extractDeferredElements", at = @At("HEAD"))
    private void probe$push(int x, int y, float a, CallbackInfo ci) {
        Tag.push("tooltip");
    }

    @Inject(method = "extractDeferredElements", at = @At("RETURN"))
    private void probe$pop(int x, int y, float a, CallbackInfo ci) {
        Tag.pop();
    }
}
