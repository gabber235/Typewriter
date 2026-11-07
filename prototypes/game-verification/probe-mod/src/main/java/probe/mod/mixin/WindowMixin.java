package probe.mod.mixin;

import com.mojang.blaze3d.platform.Window;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.ModifyArg;

/** Extra SDL window flags from -Dprobe.windowFlags and flags to drop from -Dprobe.windowFlagsClear (0x2000 is high pixel density). */
@Mixin(Window.class)
public class WindowMixin {
    @ModifyArg(
        method = "createWindow",
        at = @At(value = "INVOKE", target = "Lcom/mojang/renderpearl/api/device/GpuBackend;createWindow(Ljava/lang/String;IIJ)J"),
        index = 3)
    private long probe$flags(long flags) {
        long extra = Long.decode(System.getProperty("probe.windowFlags", "0"));
        long clear = Long.decode(System.getProperty("probe.windowFlagsClear", "0"));
        return (flags | extra) & ~clear;
    }
}
