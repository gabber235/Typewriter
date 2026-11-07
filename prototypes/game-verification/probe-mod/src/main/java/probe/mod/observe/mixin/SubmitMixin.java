package probe.mod.observe.mixin;

import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.gui.Font;
import net.minecraft.client.renderer.SubmitNodeCollection;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import net.minecraft.network.chat.Component;
import net.minecraft.util.FormattedCharSequence;
import net.minecraft.world.phys.Vec3;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Drawn;

/** A2 seam for world text and for "this entity really submitted geometry". */
@Mixin(SubmitNodeCollection.class)
public class SubmitMixin {
    @Inject(method = "submitText", at = @At("HEAD"), cancellable = true)
    private void probe$text(PoseStack pose, float x, float y, FormattedCharSequence text, boolean shadow, Font.DisplayMode mode, int light, int color, int bg, int outline, CallbackInfo ci) {
        if (Drawn.onWorldText(pose, x, y, text, color, bg, mode)) ci.cancel();
    }

    @Inject(method = "submitTextBackground", at = @At("HEAD"))
    private void probe$bg(PoseStack pose, float x0, float y0, float x1, float y1, int color, Font.DisplayMode mode, int light, CallbackInfo ci) {
        Drawn.onWorldTextBackground(color);
    }

    @Inject(method = "submitNameTag", at = @At("HEAD"), cancellable = true)
    private void probe$tag(PoseStack pose, Vec3 at, int offset, Component name, boolean seeThrough, int light, CameraRenderState camera, CallbackInfo ci) {
        if (Drawn.onNameTag(pose, at, name)) ci.cancel();
    }

    @Inject(method = "submitModel", at = @At("HEAD"))
    private void probe$model(CallbackInfo ci) {
        Drawn.onGeometry();
    }

    @Inject(method = "submitBlockModel", at = @At("HEAD"))
    private void probe$block(CallbackInfo ci) {
        Drawn.onGeometry();
    }

    @Inject(method = "submitItem", at = @At("HEAD"))
    private void probe$item(CallbackInfo ci) {
        Drawn.onGeometry();
    }
}
