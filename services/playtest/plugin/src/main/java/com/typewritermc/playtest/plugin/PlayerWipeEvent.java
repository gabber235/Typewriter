package com.typewritermc.playtest.plugin;

import org.bukkit.entity.Player;
import org.bukkit.event.HandlerList;
import org.bukkit.event.player.PlayerEvent;
import org.jspecify.annotations.NonNull;

/**
 * Paper wipes the player for a new attempt: the vanilla and Paper state is already cleared, and the
 * attempt starts once every listener returned. A plugin resets everything it keeps for the player
 * (stored values, permissions it attached, metadata it set, sessions, mail, holds), so the attempt
 * meets the plugin as a player who never played would. Fired on the main thread.
 */
public final class PlayerWipeEvent extends PlayerEvent {
    private static final HandlerList HANDLERS = new HandlerList();

    PlayerWipeEvent(Player player) {
        super(player);
    }

    @Override
    public @NonNull HandlerList getHandlers() {
        return HANDLERS;
    }

    public static HandlerList getHandlerList() {
        return HANDLERS;
    }
}
