package probe.mod.observe.mixin;

import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.util.FormattedCharSequence;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(GuiTextRenderState.class)
public interface GuiTextAccessor {
    @Accessor("text") FormattedCharSequence probe$text();
    @Accessor("color") int probe$color();
    @Accessor("backgroundColor") int probe$bg();
}
