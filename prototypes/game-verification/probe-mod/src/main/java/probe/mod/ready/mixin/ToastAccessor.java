package probe.mod.ready.mixin;

import java.util.Deque;
import java.util.List;
import net.minecraft.client.gui.components.toasts.Toast;
import net.minecraft.client.gui.components.toasts.ToastManager;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(ToastManager.class)
public interface ToastAccessor {
    @Accessor("visibleToasts") List<?> probe$visible();
    @Accessor("queued") Deque<Toast> probe$queued();
}
