package probe.mod.golden.mixin;

import java.util.List;
import net.minecraft.client.renderer.texture.SpriteContents;
import net.minecraft.client.renderer.texture.TextureAtlas;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;
import org.spongepowered.asm.mixin.gen.Invoker;

@Mixin(TextureAtlas.class)
public interface TextureAtlasAccessor {
    @Accessor("animatedTexturesStates")
    List<SpriteContents.AnimationState> probe$states();

    @Invoker("uploadAnimationFrames")
    void probe$upload();
}
