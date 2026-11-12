package probe.mod.streammix;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.screens.Screen;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Tag;

@Mixin(Screen.class)
public class ScreenTagMixin {
    @Inject(method = "extractRenderStateWithTooltipAndSubtitles", at = @At("HEAD"))
    private void probe$push(GuiGraphicsExtractor g, int x, int y, float a, CallbackInfo ci) {
        Tag.push("screen");
    }

    @Inject(method = "extractRenderStateWithTooltipAndSubtitles", at = @At("RETURN"))
    private void probe$pop(GuiGraphicsExtractor g, int x, int y, float a, CallbackInfo ci) {
        Tag.pop();
    }
}
