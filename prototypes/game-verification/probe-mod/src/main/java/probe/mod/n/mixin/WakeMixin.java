package probe.mod.n.mixin;

import net.minecraft.network.PacketListener;
import net.minecraft.network.PacketProcessor;
import net.minecraft.network.protocol.Packet;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.n.N;

/** A step ping wakes the parked render thread at once instead of after the gate's park. */
@Mixin(PacketProcessor.class)
public class WakeMixin {
    @Inject(method = "scheduleIfPossible", at = @At("TAIL"))
    private <T extends PacketListener> void probe$wake(T listener, Packet<T> packet, CallbackInfo ci) {
        if (packet instanceof ClientboundPingPacket ping) {
            if (ping.getId() >= N.BASE || N.wakeBarriers) N.wake();
        } else if (!(packet instanceof net.minecraft.network.protocol.common.ClientboundKeepAlivePacket)
                && !(packet instanceof net.minecraft.network.protocol.game.ClientboundSetTimePacket)) {
            N.arrived.incrementAndGet();
            N.kinds.merge(packet.getClass().getSimpleName(), 1L, Long::sum);
        }
    }
}
