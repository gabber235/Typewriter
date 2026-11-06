package probe.mod.speed.mixin;

import net.minecraft.client.multiplayer.ClientCommonPacketListenerImpl;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.speed.Speed;

/** Vanilla ping packet as an ordered echo barrier: everything sent before it is already handled. */
@Mixin(ClientCommonPacketListenerImpl.class)
public class PingMixin {
    @Inject(method = "handlePing", at = @At("TAIL"))
    private void probe$ping(ClientboundPingPacket packet, CallbackInfo ci) {
        // Highest, not last: a window barrier still scheduled after a fast pass arrives after later barriers (spike D).
        Speed.lastPing = Math.max(Speed.lastPing, packet.getId());
        probe.mod.ready.Ready.onPing(packet.getId());
    }
}
