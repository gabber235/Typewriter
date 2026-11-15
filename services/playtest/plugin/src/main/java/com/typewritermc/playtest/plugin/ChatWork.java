package com.typewritermc.playtest.plugin;

import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import java.lang.reflect.Field;
import java.util.HashSet;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import net.minecraft.network.protocol.game.ServerboundChatPacket;
import net.minecraft.server.network.ServerGamePacketListenerImpl;
import net.minecraft.util.FutureChain;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;

/**
 * Counts a chat line as its player's work, from the moment Paper reads the line until its chat thread
 * sent it to every viewer, so the next tick waits for the line. Paper handles a chat line on the
 * connection's thread, which appends its decoration and broadcast to the player's chat chain; the
 * work ends in the link appended right after, which the chain runs once the broadcast returned.
 * Commands run on the main thread and need no counting.
 */
final class ChatWork implements Listener {
    private static final String HANDLER = "playtest_chat_work";
    private static final Field CHAIN = chainField();

    /** Each joining player's connection counts its chat lines. */
    @EventHandler(priority = EventPriority.LOWEST)
    public void onJoin(PlayerJoinEvent event) {
        Player player = event.getPlayer();
        ServerGamePacketListenerImpl listener = ((CraftPlayer) player).getHandle().connection;
        listener.connection.channel.pipeline().addBefore("packet_handler", HANDLER, new Lines(player, chain(listener)));
    }

    /** One connection's chat lines, each counted until its broadcast returned or the player left. */
    private static final class Lines extends ChannelInboundHandlerAdapter {
        private final Player player;
        private final FutureChain chain;
        // A link of a closed chain never runs, so the lines it holds end when the connection does.
        private final Set<PlayerWork> open = new HashSet<>();

        private Lines(Player player, FutureChain chain) {
            this.player = player;
            this.chain = chain;
        }

        @Override
        public void channelRead(ChannelHandlerContext ctx, Object msg) {
            if (!(msg instanceof ServerboundChatPacket)) {
                ctx.fireChannelRead(msg);
                return;
            }
            PlayerWork line = PlayerWork.begin(player, "chat");
            synchronized (open) {
                open.add(line);
            }
            try {
                ctx.fireChannelRead(msg);
            } finally {
                chain.append(CompletableFuture.completedFuture(null), ignored -> end(line));
            }
        }

        @Override
        public void channelInactive(ChannelHandlerContext ctx) throws Exception {
            synchronized (open) {
                open.forEach(PlayerWork::end);
                open.clear();
            }
            super.channelInactive(ctx);
        }

        private void end(PlayerWork line) {
            line.end();
            synchronized (open) {
                open.remove(line);
            }
        }
    }

    private static FutureChain chain(ServerGamePacketListenerImpl listener) {
        try {
            return (FutureChain) CHAIN.get(listener);
        } catch (IllegalAccessException unreachable) {
            throw new IllegalStateException(unreachable);
        }
    }

    // The chain is private to the listener; this Paper is pinned, so the field is always there.
    private static Field chainField() {
        try {
            Field field = ServerGamePacketListenerImpl.class.getDeclaredField("chatMessageChain");
            field.setAccessible(true);
            return field;
        } catch (NoSuchFieldException missing) {
            throw new IllegalStateException("this Paper keeps no chat chain to count chat lines on", missing);
        }
    }
}
