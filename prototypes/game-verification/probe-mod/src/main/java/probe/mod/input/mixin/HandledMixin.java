package probe.mod.input.mixin;

import net.minecraft.client.KeyboardHandler;
import net.minecraft.client.MouseHandler;
import net.minecraft.client.input.KeyEvent;
import net.minecraft.client.input.MouseButtonInfo;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.input.Input;

/** In process prototype: when an injected event reaches the client's input handlers, relative to its tick. */
public final class HandledMixin {
    private HandledMixin() {}

    @Mixin(KeyboardHandler.class)
    public static class Keys {
        @Inject(method = "keyPress", at = @At("HEAD"))
        private void probe$key(long w, int action, KeyEvent e, CallbackInfo ci) {
            Input.handled("key");
        }

        @Inject(method = "textInput", at = @At("HEAD"))
        private void probe$text(long w, String s, CallbackInfo ci) {
            Input.handled("text");
        }
    }

    @Mixin(MouseHandler.class)
    public static class Mouse {
        @Inject(method = "onButton", at = @At("HEAD"))
        private void probe$button(long w, MouseButtonInfo b, int action, CallbackInfo ci) {
            Input.handled("button");
        }

        @Inject(method = "onScroll", at = @At("HEAD"))
        private void probe$scroll(long w, double x, double y, CallbackInfo ci) {
            Input.handled("scroll");
        }

        @Inject(method = "onMove", at = @At("HEAD"))
        private void probe$move(long w, double x, double y, double dx, double dy, CallbackInfo ci) {
            Input.handled("move");
        }
    }
}
