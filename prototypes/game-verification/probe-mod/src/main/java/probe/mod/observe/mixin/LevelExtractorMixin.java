package probe.mod.observe.mixin;

import net.minecraft.client.Camera;
import net.minecraft.client.DeltaTracker;
import net.minecraft.client.renderer.culling.Frustum;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.extract.LevelExtractor;
import net.minecraft.client.renderer.state.level.LevelRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import probe.mod.observe.Drawn;

/** A2 seam for world things: render states after culling, before submit. */
@Mixin(LevelExtractor.class)
public class LevelExtractorMixin {
    @Inject(method = "extractEntity", at = @At("RETURN"))
    private void probe$entity(Entity entity, float partial, CallbackInfoReturnable<EntityRenderState> cir) {
        Drawn.onEntityExtract(entity, cir.getReturnValue());
    }

    @Inject(method = "extractVisibleEntities", at = @At("TAIL"))
    private void probe$entities(Camera camera, Frustum frustum, DeltaTracker delta, LevelRenderState output, CallbackInfo ci) {
        Drawn.afterEntities(output);
    }

    @Inject(method = "extractVisibleBlockEntities", at = @At("TAIL"))
    private void probe$blockEntities(Camera camera, float partial, LevelRenderState output, CallbackInfo ci) {
        Drawn.afterBlockEntities(output);
    }

    @Inject(method = "setBlockDirty(Lnet/minecraft/core/BlockPos;Z)V", at = @At("HEAD"))
    private void probe$dirty(BlockPos pos, boolean playerChanged, CallbackInfo ci) {
        Drawn.onBlockDirty(pos);
    }
}
