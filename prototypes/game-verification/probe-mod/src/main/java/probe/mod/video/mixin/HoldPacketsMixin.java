package probe.mod.video.mixin;

import net.minecraft.client.Minecraft;
import net.minecraft.network.PacketProcessor;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Redirect;
import probe.mod.video.Demo;

/** Demo: the loop's own packet pass runs only in the loop that takes the next tick (see N.demoLoop). */
@Mixin(Minecraft.class)
public class HoldPacketsMixin {
    @Redirect(method = "runTick", at = @At(value = "INVOKE", target = "Lnet/minecraft/network/PacketProcessor;processQueuedPackets()V"))
    private void probe$hold(PacketProcessor processor) {
        if (!Demo.on || Demo.packetsOpen) processor.processQueuedPackets();
    }
}
