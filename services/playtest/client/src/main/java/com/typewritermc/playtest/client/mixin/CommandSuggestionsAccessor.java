package com.typewritermc.playtest.client.mixin;

import com.mojang.brigadier.suggestion.Suggestions;
import java.util.concurrent.CompletableFuture;
import net.minecraft.client.gui.components.CommandSuggestions;
import org.spongepowered.asm.mixin.Mixin;
import org.spongepowered.asm.mixin.gen.Accessor;

/** The suggestion request in flight: not done while its answer has not come, or never will. */
@Mixin(CommandSuggestions.class)
public interface CommandSuggestionsAccessor {
    @Accessor("pendingSuggestions")
    CompletableFuture<Suggestions> playtest$pendingSuggestions();
}
