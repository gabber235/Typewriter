package probe.mod.streammix;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.components.CommandSuggestions;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Tag;

/** Suggestion list and usage lines both come from CommandSuggestions.extractRenderState. */
@Mixin(CommandSuggestions.class)
public class SuggestTagMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void probe$push(GuiGraphicsExtractor g, int x, int y, CallbackInfo ci) {
        Tag.push("suggestions");
    }

    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void probe$pop(GuiGraphicsExtractor g, int x, int y, CallbackInfo ci) {
        Tag.pop();
    }
}
