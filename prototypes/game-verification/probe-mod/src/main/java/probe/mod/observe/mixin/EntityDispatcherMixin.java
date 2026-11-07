package probe.mod.observe.mixin;

import com.mojang.blaze3d.vertex.PoseStack;
import net.minecraft.client.renderer.SubmitNodeCollector;
import net.minecraft.client.renderer.entity.EntityRenderDispatcher;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.state.level.CameraRenderState;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Drawn;

/** Brackets one entity's submit, so nodes seen in between belong to it. */
@Mixin(EntityRenderDispatcher.class)
public class EntityDispatcherMixin {
    @Inject(method = "submit", at = @At("HEAD"))
    private <S extends EntityRenderState> void probe$begin(S state, CameraRenderState camera, double x, double y, double z, PoseStack pose, SubmitNodeCollector out, CallbackInfo ci) {
        Drawn.beginEntitySubmit(state);
    }

    @Inject(method = "submit", at = @At("TAIL"))
    private <S extends EntityRenderState> void probe$end(S state, CameraRenderState camera, double x, double y, double z, PoseStack pose, SubmitNodeCollector out, CallbackInfo ci) {
        Drawn.endEntitySubmit();
    }
}
