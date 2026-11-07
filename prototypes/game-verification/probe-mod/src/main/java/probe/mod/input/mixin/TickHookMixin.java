package probe.mod.input.mixin;

import net.minecraft.client.Minecraft;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.input.Input;

@Mixin(Minecraft.class)
public class TickHookMixin {
    @Inject(method = "tick", at = @At("HEAD"))
    private void probe$head(CallbackInfo ci) {
        Input.headTick((Minecraft) (Object) this);
    }

    @Inject(method = "tick", at = @At("TAIL"))
    private void probe$tail(CallbackInfo ci) {
        Input.tailTick((Minecraft) (Object) this);
    }
}
