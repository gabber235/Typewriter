package probe.mod.observe.mixin;

import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.Hud;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Drawn;

/** Battery scene 8: another element painted over the title. */
@Mixin(Hud.class)
public class HudMixin {
    @Inject(method = "extractRenderState", at = @At("TAIL"))
    private void probe$over(GuiGraphicsExtractor graphics, DeltaTracker delta, CallbackInfo ci) {
        int[] o = Drawn.overdraw;
        if (o != null) {
            graphics.nextStratum();
            graphics.fill(o[0], o[1], o[2], o[3], o[4]);
        }
    }
}
