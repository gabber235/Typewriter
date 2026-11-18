package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.client.multiplayer.ClientCommonPacketListenerImpl;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** Vanilla pings are handled in order with every other packet, so they carry steps and barriers. */
@Mixin(ClientCommonPacketListenerImpl.class)
abstract class PingMixin {
    @Inject(method = "handlePing", at = @At("TAIL"))
    private void playtest$ping(ClientboundPingPacket packet, CallbackInfo ci) {
        Hooks.ping(packet.getId());
    }
}
