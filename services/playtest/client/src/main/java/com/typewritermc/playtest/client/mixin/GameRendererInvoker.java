package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.renderer.GameRenderer;
import net.minecraft.client.renderer.Lightmap;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

@Mixin(GameRenderer.class)
public interface GameRendererInvoker {
    @Invoker("shouldRenderBlockOutline")
    boolean playtest$shouldRenderBlockOutline();

    @Accessor("lightmap")
    Lightmap playtest$lightmap();
}
