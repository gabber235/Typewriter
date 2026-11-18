package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.gui.screens.inventory.AbstractContainerScreen;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** Where a screen with slots draws its slots from: they are placed relative to its top left corner. */
@Mixin(AbstractContainerScreen.class)
public interface AbstractContainerScreenAccessor {
    @Accessor("leftPos")
    int playtest$leftPos();

    @Accessor("topPos")
    int playtest$topPos();
}
