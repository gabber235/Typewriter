package probe.mod.n;

import io.netty.buffer.ByteBuf;
import java.util.Map;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.locks.LockSupport;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.fabricmc.fabric.api.networking.v1.PayloadTypeRegistry;
import net.minecraft.client.Minecraft;
import net.minecraft.client.multiplayer.chat.GuiMessage;
import net.minecraft.network.codec.StreamCodec;
import net.minecraft.network.protocol.common.custom.CustomPacketPayload;
import net.minecraft.resources.Identifier;
import net.minecraft.util.Util;
import probe.mod.mixin.ChatAccessor;

/**
 * Spike N, client in step: the client's clock (Util.timeSource) is frozen and moves exactly one tick
 * (50 ms) per step ping the server sends at the end of each stepped tick. After that client tick the
 * client answers with a probe:step payload naming the server tick, whether the watched chat needle is
 * on screen, and its own tick count. Packets still arrive and are handled every loop, as always.
 *
 *   n.mode?on=1|0      freeze the client clock and tick only on step pings
 *   n.watch?needle=X   report in every ack whether chat holds X (empty clears)
 *   n.stats            client ticks, steps, the clock
 */
public final class N {
    public static final int BASE = 1 << 30;
    private static final long TICK_NANOS = 50_000_000L;

    public record Ack(int tick, int seen, int clientTicks) implements CustomPacketPayload {
        public static final CustomPacketPayload.Type<Ack> TYPE = new CustomPacketPayload.Type<>(Identifier.parse("probe:step"));
        public static final StreamCodec<ByteBuf, Ack> CODEC = StreamCodec.of(
                (buf, a) -> { buf.writeInt(a.tick); buf.writeInt(a.seen); buf.writeInt(a.clientTicks); },
                buf -> new Ack(buf.readInt(), buf.readInt(), buf.readInt()));

        @Override
        public Type<? extends CustomPacketPayload> type() {
            return TYPE;
        }
    }

    /** Frames spike lever: barrier pings (below BASE) wake the parked render thread too. */
    public static volatile boolean wakeBarriers;
    /** Frames spike: game packets scheduled (not pings, keepalives or time), counted on the netty thread. */
    public static final java.util.concurrent.ConcurrentHashMap<String, Long> kinds = new java.util.concurrent.ConcurrentHashMap<>();
    public static final java.util.concurrent.atomic.AtomicLong arrived = new java.util.concurrent.atomic.AtomicLong();
    private static volatile boolean stepping;
    private static volatile long virtNanos;
    private static volatile Thread render;
    private static volatile String needle;
    private static final ConcurrentLinkedQueue<Integer> granted = new ConcurrentLinkedQueue<>();
    private static Integer current;
    private static int clientTicks, steps, extraTicks;
    private static volatile long wakeAt;
    private static long wakeToGrant, grantToAck, grantAt, loops;
    private static int acksSent, lastAckTick, lastSeen;

    private N() {}

    public static void init() {
        PayloadTypeRegistry.serverboundPlay().register(Ack.TYPE, Ack.CODEC);
    }

    /** Render thread, inside handlePing. */
    public static void onStepPing(int id) {
        granted.add(id - BASE);
    }

    /** Netty thread, right after a step ping was queued for the render thread. */
    public static void wake() {
        wakeAt = System.nanoTime();
        Thread t = render;
        if (stepping && t != null) LockSupport.unpark(t);
    }

    /** Head of Minecraft.runTick, before the delta tracker reads the clock. */
    public static void beforeRunTick(Minecraft mc) {
        render = Thread.currentThread();
        if (!stepping) return;
        loops++;
        // Handle what already arrived now rather than later in this loop, so a step ping read here ticks this loop.
        long upTo = arrived.get();
        mc.packetProcessor().processQueuedPackets();
        probe.mod.observe.Stream.processed = upTo; // every packet counted before the call is handled now
        if (current != null) return; // the granted tick has not run (no level yet); keep the clock where it is
        if (probe.mod.observe.Stream.holding()) return; // an A4 pair is in flight: both frames must see the same tick
        Integer t = granted.poll();
        if (t != null) {
            current = t;
            virtNanos += TICK_NANOS;
            grantAt = System.nanoTime();
            if (wakeAt != 0) wakeToGrant += grantAt - wakeAt;
        }
    }

    /** Tail of Minecraft.tick. */
    public static void afterTick(Minecraft mc) {
        clientTicks++;
        probe.mod.observe.Stream.onTick(mc, stepping && current != null ? current : -1);
        if (!stepping) return;
        if (current == null) {
            extraTicks++;
            return;
        }
        int t = current;
        current = null;
        steps++;
        int seen = 0;
        String n = needle;
        if (n != null && !n.isEmpty()) {
            for (GuiMessage m : ((ChatAccessor) mc.gui.hud.getChat()).probe$allMessages()) {
                if (m.content().getString().contains(n)) {
                    seen = 1;
                    break;
                }
            }
        }
        if (mc.getConnection() != null) {
            ClientPlayNetworking.send(new Ack(t, seen, clientTicks));
            acksSent++;
            lastAckTick = t;
            lastSeen = seen;
        }
        grantToAck += System.nanoTime() - grantAt;
    }

    public static String handle(String name, Map<String, String> p, Minecraft mc) {
        switch (name) {
            case "n.mode" -> {
                boolean on = "1".equals(p.get("on"));
                // On the render thread, between frames: switched from another thread, a frame in flight could read the
                // real clock after the virtual one was fixed, leave the delta tracker ahead of it, and make the first
                // step yield less than one tick, which never runs (topology spike, CI run 42342290365).
                java.util.concurrent.CompletableFuture<Void> done = new java.util.concurrent.CompletableFuture<>();
                mc.execute(() -> {
                    if (on && !stepping) {
                        virtNanos = Util.getNanos();
                        granted.clear();
                        current = null;
                        Util.setTimeSource(() -> virtNanos);
                        stepping = true;
                    } else if (!on && stepping) {
                        stepping = false;
                        long offset = virtNanos - System.nanoTime();
                        Util.setTimeSource(() -> System.nanoTime() + offset);
                    }
                    done.complete(null);
                });
                try {
                    done.get(10, java.util.concurrent.TimeUnit.SECONDS);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
                return "{\"ok\":true,\"stepping\":" + stepping + "}";
            }
            case "n.wake" -> {
                wakeBarriers = "1".equals(p.get("barriers"));
                return "{\"ok\":true,\"barriers\":" + wakeBarriers + "}";
            }
            case "n.packets" -> {
                StringBuilder b = new StringBuilder("{");
                for (var e : kinds.entrySet()) b.append(b.length() > 1 ? "," : "").append('"').append(e.getKey()).append("\":").append(e.getValue());
                if ("1".equals(p.get("clear"))) kinds.clear();
                return b.append('}').toString();
            }
            case "n.watch" -> {
                needle = p.getOrDefault("needle", "");
                return "{\"ok\":true}";
            }
            case "n.resend" -> {
                mc.execute(() -> ClientPlayNetworking.send(new Ack(lastAckTick, lastSeen, clientTicks)));
                return "{\"ok\":true,\"tick\":" + lastAckTick + "}";
            }
            case "n.stats" -> {
                return "{\"clientTicks\":" + clientTicks + ",\"steps\":" + steps + ",\"extraTicks\":" + extraTicks + ",\"queued\":" + granted.size()
                        + ",\"acksSent\":" + acksSent + ",\"lastAckTick\":" + lastAckTick + ",\"loops\":" + loops + ",\"wakeToGrantUs\":" + wakeToGrant / 1000 + ",\"grantToAckUs\":" + grantToAck / 1000 + ",\"stepping\":" + stepping + ",\"virtMs\":" + virtNanos / 1_000_000 + "}";
            }
            default -> {
                return null;
            }
        }
    }
}
