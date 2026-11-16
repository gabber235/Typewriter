package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.server.AsyncTabCompleteEvent;
import com.destroystokyo.paper.event.brigadier.AsyncPlayerSendSuggestionsEvent;
import io.netty.channel.ChannelDuplexHandler;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelPromise;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import net.minecraft.network.protocol.game.ClientboundCommandSuggestionsPacket;
import net.minecraft.network.protocol.game.ServerboundCommandSuggestionPacket;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;

/**
 * Counts a command suggestion request as its player's work, from the moment Paper reads it until its
 * answer goes out, so the next tick waits for the answer. Paper works a request out on its own threads
 * and, between stepped ticks, as a main thread task. It sends no answer when the completion event is
 * cancelled or the suggestions are empty, and drops a request a newer one replaced before it ran; so a
 * request also ends where Paper decides to send nothing, and when a newer request of its player ends.
 */
final class SuggestionWork implements Listener {
    private static final String HANDLER = "playtest_suggestion_work";

    private final Map<UUID, Requests> players = new ConcurrentHashMap<>();

    /** Each joining player's connection counts its suggestion requests. */
    @EventHandler(priority = EventPriority.LOWEST)
    public void onJoin(PlayerJoinEvent event) {
        Player player = event.getPlayer();
        var requests = new Requests(player);
        players.put(player.getUniqueId(), requests);
        ((CraftPlayer) player).getHandle().connection.connection.channel.pipeline().addBefore("packet_handler", HANDLER, requests);
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void onQuit(PlayerQuitEvent event) {
        players.remove(event.getPlayer().getUniqueId());
    }

    /** A completion a plugin handled with no suggestions, or cancelled unhandled, gets no answer. */
    @EventHandler(priority = EventPriority.MONITOR)
    public void onComplete(AsyncTabCompleteEvent event) {
        if (!event.isCommand() || !(event.getSender() instanceof Player player)) return;
        boolean unanswered = event.isHandled() ? event.isCancelled() || event.completions().isEmpty() : event.isCancelled();
        if (unanswered) unanswered(player, event.getBuffer());
    }

    /** Suggestions that are cancelled or empty are never sent. */
    @EventHandler(priority = EventPriority.MONITOR)
    public void onSend(AsyncPlayerSendSuggestionsEvent event) {
        if (event.isCancelled() || event.getSuggestions().isEmpty()) unanswered(event.getPlayer(), event.getBuffer());
    }

    private void unanswered(Player player, String command) {
        Requests requests = players.get(player.getUniqueId());
        if (requests != null) requests.unanswered(command);
    }

    /**
     * One connection's open requests in the order Paper read them, each counted until it, or a newer
     * request, ended. The client numbers a request one past the last one still unanswered, so ids
     * repeat once an answer came: an answer names the newest open request with its id.
     */
    private static final class Requests extends ChannelDuplexHandler {
        private record Open(int id, String command, PlayerWork work) {}

        private final Player player;
        private final List<Open> open = new ArrayList<>();

        private Requests(Player player) {
            this.player = player;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (msg instanceof ServerboundCommandSuggestionPacket request) {
                synchronized (open) {
                    open.add(new Open(request.id(), request.command(), PlayerWork.begin(player, "suggestions for " + request.command())));
                }
            }
            ctx.fireChannelRead(msg);
        }

        /** The answer is in the pipeline ahead of anything Paper writes later, such as the next step ping. */
        @Override
        public void write(ChannelHandlerContext ctx, Object msg, ChannelPromise promise) {
            ctx.write(msg, promise);
            if (msg instanceof ClientboundCommandSuggestionsPacket answer) answered(answer.id());
        }

        @Override
        public void channelInactive(ChannelHandlerContext ctx) throws Exception {
            synchronized (open) {
                open.forEach(request -> request.work().end());
                open.clear();
            }
            super.channelInactive(ctx);
        }

        /** Paper answered the newest open request numbered {@code id}. */
        private void answered(int id) {
            synchronized (open) {
                for (int index = open.size() - 1; index >= 0; index--) {
                    if (open.get(index).id() == id) {
                        endThrough(index);
                        return;
                    }
                }
            }
        }

        /** Paper sends nothing for the oldest open request asking about {@code command}. */
        void unanswered(String command) {
            synchronized (open) {
                for (int index = 0; index < open.size(); index++) {
                    if (open.get(index).command().equals(command)) {
                        endThrough(index);
                        return;
                    }
                }
            }
        }

        /** The request at {@code index} ended, and every older one with it: Paper answers none of those any more. */
        private void endThrough(int index) {
            var ended = open.subList(0, index + 1);
            ended.forEach(request -> request.work().end());
            ended.clear();
        }
    }
}
