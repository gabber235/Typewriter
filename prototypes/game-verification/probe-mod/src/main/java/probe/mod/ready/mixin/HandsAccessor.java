package probe.mod.ready.mixin;

import net.minecraft.client.player.FirstPersonHandsAndItems;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

@Mixin(FirstPersonHandsAndItems.class)
public interface HandsAccessor {
    @Accessor("mainHandHeight") float probe$main();
    @Accessor("oMainHandHeight") float probe$oMain();
    @Accessor("offHandHeight") float probe$off();
    @Accessor("oOffHandHeight") float probe$oOff();
}
