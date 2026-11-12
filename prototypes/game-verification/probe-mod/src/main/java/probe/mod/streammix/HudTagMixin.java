package probe.mod.streammix;

import net.minecraft.client.DeltaTracker;
import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.client.gui.Hud;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Tag;

/** HUD element tag: each Hud extract method names the element while it adds its text. */
@Mixin(Hud.class)
public class HudTagMixin {
    @Inject(method = "extractRenderState", at = @At("HEAD"))
    private void probe$hud(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.reset();
        Tag.push("hud");
    }

    @Inject(method = "extractRenderState", at = @At("RETURN"))
    private void probe$hudEnd(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractChat", at = @At("HEAD"))
    private void probe$push_chat(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("chat");
    }

    @Inject(method = "extractChat", at = @At("RETURN"))
    private void probe$pop_chat(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractOverlayMessage", at = @At("HEAD"))
    private void probe$push_actionbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("actionbar");
    }

    @Inject(method = "extractOverlayMessage", at = @At("RETURN"))
    private void probe$pop_actionbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractTitle", at = @At("HEAD"))
    private void probe$push_title(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("title");
    }

    @Inject(method = "extractTitle", at = @At("RETURN"))
    private void probe$pop_title(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractBossOverlay", at = @At("HEAD"))
    private void probe$push_bossbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("bossbar");
    }

    @Inject(method = "extractBossOverlay", at = @At("RETURN"))
    private void probe$pop_bossbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractScoreboardSidebar", at = @At("HEAD"))
    private void probe$push_sidebar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("sidebar");
    }

    @Inject(method = "extractScoreboardSidebar", at = @At("RETURN"))
    private void probe$pop_sidebar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractTabList", at = @At("HEAD"))
    private void probe$push_tablist(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("tablist");
    }

    @Inject(method = "extractTabList", at = @At("RETURN"))
    private void probe$pop_tablist(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractSelectedItemName", at = @At("HEAD"))
    private void probe$push_itemname(GuiGraphicsExtractor g, CallbackInfo ci) {
        Tag.push("itemname");
    }

    @Inject(method = "extractSelectedItemName", at = @At("RETURN"))
    private void probe$pop_itemname(GuiGraphicsExtractor g, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractHotbarAndDecorations", at = @At("HEAD"))
    private void probe$push_hotbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("hotbar");
    }

    @Inject(method = "extractHotbarAndDecorations", at = @At("RETURN"))
    private void probe$pop_hotbar(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }

    @Inject(method = "extractEffects", at = @At("HEAD"))
    private void probe$push_effects(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.push("effects");
    }

    @Inject(method = "extractEffects", at = @At("RETURN"))
    private void probe$pop_effects(GuiGraphicsExtractor g, DeltaTracker d, CallbackInfo ci) {
        Tag.pop();
    }
}
