package probe.mod.streammix;

import net.minecraft.client.gui.components.ChatComponent;
import net.minecraft.client.multiplayer.chat.GuiMessageSource;
import net.minecraft.client.multiplayer.chat.GuiMessageTag;
import net.minecraft.network.chat.Component;
import net.minecraft.network.chat.MessageSignature;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Stream;

/** Every chat line the client adds, in order, for the "chat since start" section. */
@Mixin(ChatComponent.class)
public class ChatAddMixin {
    @Inject(method = "addMessage", at = @At("HEAD"))
    private void probe$add(Component c, MessageSignature s, GuiMessageSource src, GuiMessageTag tag, CallbackInfo ci) {
        Stream.onChat(c.getString());
    }
}
