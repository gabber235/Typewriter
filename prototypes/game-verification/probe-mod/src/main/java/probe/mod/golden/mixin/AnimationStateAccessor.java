package probe.mod.golden.mixin;

import net.minecraft.client.renderer.texture.SpriteContents;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(SpriteContents.AnimationState.class)
public interface AnimationStateAccessor {
    @Accessor("frame")
    void probe$setFrame(int v);

    @Accessor("subFrame")
    void probe$setSubFrame(int v);

    @Accessor("isDirty")
    void probe$setDirty(boolean v);
}
