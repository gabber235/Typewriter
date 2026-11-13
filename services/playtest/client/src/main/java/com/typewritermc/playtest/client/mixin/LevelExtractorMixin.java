package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.renderer.entity.state.EntityRenderState;
import net.minecraft.client.renderer.extract.LevelExtractor;
import net.minecraft.core.BlockPos;
import net.minecraft.world.entity.Entity;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;

/** Blocks as they change in the client's world, and every entity a frame draws after culling. */
@Mixin(LevelExtractor.class)
abstract class LevelExtractorMixin {
    @Inject(method = "blockChanged", at = @At("HEAD"))
    private void playtest$blockChanged(BlockPos pos, int flags, CallbackInfo ci) {
        Hooks.blockChanged(pos);
    }

    @Inject(method = "extractEntity", at = @At("RETURN"))
    private void playtest$entity(Entity entity, float partialTick, CallbackInfoReturnable<EntityRenderState> cir) {
        Hooks.entityDrawn(entity, cir.getReturnValue());
    }
}
