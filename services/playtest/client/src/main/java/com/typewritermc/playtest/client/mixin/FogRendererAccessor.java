package com.typewritermc.playtest.client.mixin;

import java.util.List;
import net.minecraft.client.renderer.fog.FogRenderer;
import net.minecraft.client.renderer.fog.environment.FogEnvironment;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The fog environments every frame's fog is set up from, one instance each for the whole client. */
@Mixin(FogRenderer.class)
public interface FogRendererAccessor {
    @Accessor("FOG_ENVIRONMENTS")
    static List<FogEnvironment> playtest$environments() {
        throw new AssertionError("mixin");
    }
}
