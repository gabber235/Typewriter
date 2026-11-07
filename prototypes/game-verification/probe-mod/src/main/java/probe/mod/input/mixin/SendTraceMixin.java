package probe.mod.input.mixin;

import net.minecraft.client.multiplayer.ClientCommonPacketListenerImpl;
import net.minecraft.network.protocol.Packet;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.input.Input;

/** Spike N: records the player action packets a break sends, with their sequence numbers. */
@Mixin(ClientCommonPacketListenerImpl.class)
public class SendTraceMixin {
    @Inject(method = "send", at = @At("HEAD"))
    private void probe$send(Packet<?> packet, CallbackInfo ci) {
        Input.traceSent(packet);
    }
}
