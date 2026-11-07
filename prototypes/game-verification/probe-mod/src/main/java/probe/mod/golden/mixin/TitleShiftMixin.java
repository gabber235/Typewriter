package probe.mod.golden.mixin;

import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.Hud;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.golden.Golden;

/** Deliberate break for spike F: the title a fraction lower than vanilla draws it. */
@Mixin(Hud.class)
public class TitleShiftMixin {
    @Inject(method = "extractTitle", at = @At("HEAD"))
    private void probe$down(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        graphics.pose().pushMatrix();
        graphics.pose().translate(0f, Golden.titleDy);
    }

    @Inject(method = "extractTitle", at = @At("RETURN"))
    private void probe$back(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        graphics.pose().popMatrix();
    }
}
