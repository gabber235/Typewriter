package com.typewritermc.playtest.client.mixin;

import net.minecraft.client.gui.components.CommandSuggestions;
import net.minecraft.client.gui.components.EditBox;
import net.minecraft.client.gui.screens.ChatScreen;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The chat's text field and its suggestions, which the retype reads. */
@Mixin(ChatScreen.class)
public interface ChatScreenAccessor {
    @Accessor("input")
    EditBox playtest$input();

    @Accessor("commandSuggestions")
    CommandSuggestions playtest$commandSuggestions();
}
