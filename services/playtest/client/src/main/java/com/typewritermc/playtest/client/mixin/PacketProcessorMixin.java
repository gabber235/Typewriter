package com.typewritermc.playtest.client.mixin;

import com.typewritermc.playtest.client.Hooks;
import net.minecraft.network.PacketListener;
import net.minecraft.network.PacketProcessor;
import net.minecraft.network.protocol.Packet;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** A packet queued for the render thread wakes it, so a parked client handles a step at once. */
@Mixin(PacketProcessor.class)
abstract class PacketProcessorMixin {
    @Inject(method = "scheduleIfPossible", at = @At("TAIL"))
    private <T extends PacketListener> void playtest$wake(T listener, Packet<T> packet, CallbackInfo ci) {
        Hooks.wake();
    }
}
