package com.typewritermc.playtest.plugin;

import io.papermc.paper.event.player.AsyncChatEvent;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.plugin.Plugin;

/**
 * Which attempt each player belongs to, so that the attempts sharing this Paper never perceive one
 * another: a player sees and hears only the players of its own attempt. Claims and releases run on the
 * main thread; chat asks from its own thread.
 */
final class Attempts implements Listener {
    private final Plugin plugin;
    private final Map<UUID, Long> attemptOf = new ConcurrentHashMap<>();
    private final Map<Long, List<UUID>> players = new ConcurrentHashMap<>();

    Attempts(Plugin plugin) {
        this.plugin = plugin;
    }

    /** [claimed] belong to [attempt] from now on; they see one another and nobody else sees them. */
    void claim(long attempt, List<UUID> claimed) {
        players.put(attempt, List.copyOf(claimed));
        for (UUID id : claimed) attemptOf.put(id, attempt);
        for (UUID id : claimed) {
            Player player = Bukkit.getPlayer(id);
            if (player == null) continue;
            for (Player other : Bukkit.getOnlinePlayers()) {
                if (other.equals(player)) continue;
                if (together(player, other)) {
                    player.showPlayer(plugin, other);
                    other.showPlayer(plugin, player);
                } else {
                    player.hidePlayer(plugin, other);
                    other.hidePlayer(plugin, player);
                }
            }
        }
    }

    /** The players of [attempt], none once it ended. */
    List<UUID> players(long attempt) {
        return players.getOrDefault(attempt, List.of());
    }

    /** The attempt ended; returns its players, who stay hidden from every later attempt's players. */
    List<UUID> release(long attempt) {
        List<UUID> released = Objects.requireNonNullElse(players.remove(attempt), List.of());
        for (UUID id : released) attemptOf.remove(id, attempt);
        return released;
    }

    private boolean together(Player a, Player b) {
        Long attempt = attemptOf.get(a.getUniqueId());
        return attempt != null && attempt.equals(attemptOf.get(b.getUniqueId()));
    }

    /** A player who joins belongs to no attempt yet, so nobody sees it and it sees nobody. */
    @EventHandler
    public void onJoin(PlayerJoinEvent event) {
        event.joinMessage(null);
        Player joined = event.getPlayer();
        for (Player other : Bukkit.getOnlinePlayers()) {
            if (other.equals(joined)) continue;
            joined.hidePlayer(plugin, other);
            other.hidePlayer(plugin, joined);
        }
    }

    @EventHandler
    public void onQuit(PlayerQuitEvent event) {
        event.quitMessage(null);
    }

    /** A player's chat line reaches only the players of its attempt. */
    @EventHandler(priority = EventPriority.LOWEST)
    public void onChat(AsyncChatEvent event) {
        Player sender = event.getPlayer();
        event.viewers().removeIf(viewer -> viewer instanceof Player other && !other.equals(sender) && !together(sender, other));
    }
}
