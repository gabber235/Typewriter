package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.wire.Message.Kind;
import java.util.EnumSet;
import java.util.Set;
import org.bukkit.entity.Player;

/**
 * The vanilla and Paper state of a player, which Paper wipes before every attempt so each attempt finds
 * its players as players who never played: every {@link PaperState kind} Paper itself keeps, then the
 * inventory. State a plugin keeps is that plugin's to reset on the {@link PlayerWipeEvent}. Marks and
 * their check serve the framework's own test kit, which proves the wipe clears each kind. Main thread
 * only.
 */
final class Wipe {
    /** The kinds Paper keeps, which this wipe clears. */
    static final Set<Kind> KINDS = kinds();

    /** Clears every kind Paper keeps, then the inventory, as closing a container can return items to it. */
    void wipe(Player player) {
        for (PaperState state : PaperState.values()) state.wipe(player);
        player.getInventory().clear();
        player.setItemOnCursor(null);
    }

    /** Leaves a mark of [kind] on the player, as an earlier attempt could. */
    void mark(Player player, Kind kind) {
        state(kind).mark(player);
    }

    /** Whether the player carries a mark of [kind], whoever left it. */
    boolean marked(Player player, Kind kind) {
        return state(kind).marked(player);
    }

    private static PaperState state(Kind kind) {
        PaperState state = PaperState.of(kind);
        if (state == null) throw new IllegalArgumentException(kind + " is a kind a plugin keeps, not Paper");
        return state;
    }

    private static Set<Kind> kinds() {
        Set<Kind> kinds = EnumSet.noneOf(Kind.class);
        for (Kind kind : Kind.values()) {
            if (PaperState.of(kind) != null) kinds.add(kind);
        }
        return kinds;
    }
}
