package probe.mod.observe.mixin;

import net.minecraft.client.gui.GuiGraphicsExtractor;
import net.minecraft.world.entity.LivingEntity;
import net.minecraft.world.item.ItemStack;
import net.minecraft.world.level.Level;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.injection.At;
import org.spongepowered.asm.mixin.injection.Inject;
import org.spongepowered.asm.mixin.injection.callback.CallbackInfo;
import probe.mod.observe.Drawn;

/** The GUI item render state has no item id, so the name is taken one step earlier. */
@Mixin(GuiGraphicsExtractor.class)
public class GuiGraphicsItemMixin {
    @Inject(method = "item(Lnet/minecraft/world/entity/LivingEntity;Lnet/minecraft/world/level/Level;Lnet/minecraft/world/item/ItemStack;III)V", at = @At("HEAD"), cancellable = true)
    private void probe$item(LivingEntity owner, Level level, ItemStack stack, int x, int y, int seed, CallbackInfo ci) {
        if (Drawn.onGuiItem(stack, x, y)) ci.cancel();
    }
}
