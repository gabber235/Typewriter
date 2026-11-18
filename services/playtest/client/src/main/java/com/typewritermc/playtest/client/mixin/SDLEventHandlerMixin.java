package com.typewritermc.playtest.client.mixin;

import com.mojang.blaze3d.platform.SDLEventHandler;
import com.typewritermc.playtest.client.Hooks;
import org.lwjgl.sdl.SDL_Event;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.Redirect;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;

/** The game polls its window's events through the playtest, which keeps out input the playtest did not send. */
@Mixin(SDLEventHandler.class)
abstract class SDLEventHandlerMixin {
    @Redirect(method = "pollEvents", at = @At(value = "INVOKE", target = "Lorg/lwjgl/sdl/SDLEvents;SDL_PollEvent(Lorg/lwjgl/sdl/SDL_Event;)Z"))
    private boolean playtest$ownInput(SDL_Event event) {
        return Hooks.pollEvent(event);
    }

    @Inject(method = "flushInputEvents", at = @At("TAIL"))
    private void playtest$flushed(CallbackInfo ci) {
        Hooks.inputFlushed();
    }
}
