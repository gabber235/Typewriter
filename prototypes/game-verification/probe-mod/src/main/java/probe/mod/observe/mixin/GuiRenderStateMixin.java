package probe.mod.observe.mixin;

import net.minecraft.client.renderer.state.gui.GuiElementRenderState;
import net.minecraft.client.renderer.state.gui.GuiItemRenderState;
import net.minecraft.client.renderer.state.gui.GuiRenderState;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Drawn;

/** A2 seam: what is added here is what GuiRenderer turns into vertices. Add order is paint order. */
@Mixin(GuiRenderState.class)
public class GuiRenderStateMixin {
    @Inject(method = "addText", at = @At("HEAD"), cancellable = true)
    private void probe$text(GuiTextRenderState state, CallbackInfo ci) {
        if (Drawn.onGuiText(state)) ci.cancel();
    }

    @Inject(method = "addGuiElement", at = @At("HEAD"))
    private void probe$elem(GuiElementRenderState state, CallbackInfo ci) {
        Drawn.onGuiElement(state);
    }

    @Inject(method = "addItem", at = @At("HEAD"))
    private void probe$item(GuiItemRenderState state, CallbackInfo ci) {
        Drawn.onGuiItemBounds(state);
    }

    @Inject(method = "blurBeforeThisStratum", at = @At("HEAD"))
    private void probe$blur(CallbackInfo ci) {
        Drawn.onBlur();
    }
}
