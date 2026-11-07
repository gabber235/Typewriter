package probe.mod.observe.mixin;

import net.minecraft.client.resources.sounds.SoundInstance;
import net.minecraft.client.sounds.SoundEngine;
import net.minecraft.sounds.SoundSource;
import org.spongepowered.asm.mixin.Final;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.Shadow;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfoReturnable;
import net.minecraft.client.sounds.SoundManager;
import probe.mod.observe.Drawn;

/**
 * A2 seam for sound, plus a hard guarantee of silence on the developer's machine: the engine's own
 * volume calculation always returns zero, whatever the options say.
 */
@Mixin(SoundEngine.class)
public class SoundEngineMixin {
    @Shadow @Final private SoundManager soundManager;

    @Inject(method = "play", at = @At("HEAD"))
    private void probe$play(SoundInstance instance, CallbackInfoReturnable<SoundEngine.PlayResult> cir) {
        Drawn.onSound(instance, soundManager);
    }

    @Inject(method = "calculateVolume(FLnet/minecraft/sounds/SoundSource;)F", at = @At("HEAD"), cancellable = true)
    private void probe$silent(float volume, SoundSource source, CallbackInfoReturnable<Float> cir) {
        cir.setReturnValue(0.0F);
    }
}
