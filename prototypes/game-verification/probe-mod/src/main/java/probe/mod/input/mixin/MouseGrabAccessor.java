package probe.mod.input.mixin;

import net.minecraft.client.MouseHandler;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(MouseHandler.class)
public interface MouseGrabAccessor {
    @Accessor("mouseGrabbed") void probe$setGrabbed(boolean grabbed);
}
