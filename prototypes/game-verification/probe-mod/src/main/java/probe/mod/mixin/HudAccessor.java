package probe.mod.mixin;

import net.minecraft.client.gui.Hud;
import net.minecraft.network.chat.Component;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(Hud.class)
public interface HudAccessor {
    @Accessor("title") Component probe$title();
    @Accessor("subtitle") Component probe$subtitle();
    @Accessor("titleTime") int probe$titleTime();
    @Accessor("titleFadeInTime") int probe$fadeIn();
    @Accessor("titleStayTime") int probe$stay();
    @Accessor("titleFadeOutTime") int probe$fadeOut();
    @Accessor("overlayMessageString") Component probe$bar();
    @Accessor("overlayMessageTime") int probe$barTime();
}
