package probe.mod.speed.mixin;

import com.mojang.renderpearl.api.device.GpuSurface;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;
import probe.mod.speed.Speed;

/**
 * Render gate inside Minecraft.renderFrame. No acquired surface texture makes blit and present skip
 * themselves (both check isAcquired). Gate mode 1 skips render only, mode 2 also skips extract.
 */
@Mixin(Minecraft.class)
public class RenderGateMixin {
    @org.spongepowered.asm.mixin.injection.Inject(method = "runTick", at = @At("HEAD"))
    private void probe$clock(boolean advanceGameTime, org.spongepowered.asm.mixin.injection.callback.CallbackInfo ci) {
        probe.mod.video.Video.beforeRunTick();
    }

    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lcom/mojang/renderpearl/api/device/GpuSurface;acquireNextTexture()V"))
    private void probe$acquire(GpuSurface surface) throws Exception {
        if (!Speed.decideFrame()) surface.acquireNextTexture();
    }

    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/renderer/GameRenderer;extract(Lnet/minecraft/client/DeltaTracker;Z)V"))
    private void probe$extract(GameRenderer renderer, DeltaTracker delta, boolean advance) {
        if (!Speed.skipExtract()) renderer.extract(delta, advance);
    }

    @Redirect(method = "renderFrame", at = @At(value = "INVOKE", target = "Lnet/minecraft/client/renderer/GameRenderer;render()V"))
    private void probe$render(GameRenderer renderer) {
        if (!Speed.skipRender()) {
            renderer.render();
            probe.mod.video.Video.afterRender((Minecraft) (Object) this);
            probe.mod.ready.Ready.afterRender((Minecraft) (Object) this);
        }
    }
}
