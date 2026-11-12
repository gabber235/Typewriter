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

    public static boolean stepping() {
        return stepping;
    }

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
        if (probe.mod.video.Demo.on) {
            demoLoop(mc);
            return;
        }
        // Handle what already arrived now rather than later in this loop, so a step ping read here ticks this loop.
        mc.packetProcessor().processQueuedPackets();
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

    private static Ack pendingAck;
    public static long demoWaitLoops;

    /**
     * Demo loop: draw the next frame of the schedule if its ticks are done; otherwise hand the held ack of the
     * last tick to the server (all its frames are drawn now) and take the next grant if it is there.
     */
    private static void demoLoop(Minecraft mc) {
        probe.mod.video.Demo.ticksNow = 0;
        probe.mod.video.Demo.frameNow = false;
        probe.mod.video.Demo.packetsOpen = false;
        if (current != null) return;
        long f = probe.mod.video.Demo.frame;
        if (probe.mod.video.Demo.ticksDone < probe.mod.video.Demo.ticksFor(f)) {
            // Packets are applied only here, between the frames of one tick and the next tick: the server answers
            // input between ticks (a typed command), and that answer must not reach a frame of the tick before.
            probe.mod.video.Demo.packetsOpen = true;
            mc.packetProcessor().processQueuedPackets();
            if (pendingAck != null) {
                ClientPlayNetworking.send(pendingAck);
                acksSent++;
                lastAckTick = pendingAck.tick;
                lastSeen = pendingAck.seen;
                pendingAck = null;
            }
            Integer t = granted.poll();
            if (t == null) {
                demoWaitLoops++;
                return;
            }
            current = t;
            grantAt = System.nanoTime();
            if (wakeAt != 0) wakeToGrant += grantAt - wakeAt;
            probe.mod.video.Demo.ticksNow = 1;
            probe.mod.video.Demo.ticksDone++;
            if (probe.mod.video.Demo.ticksDone < probe.mod.video.Demo.ticksFor(f)) {
                // fps below 20 would skip a frame here; the prototype only runs 20 fps and up.
                throw new IllegalStateException("demo needs at least one frame per tick");
            }
        }
        probe.mod.video.Demo.frameNow = true;
        probe.mod.video.Demo.partial = probe.mod.video.Demo.partialFor(f);
        virtNanos = probe.mod.video.Demo.nanosFor(f);
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
        if (mc.getConnection() != null && probe.mod.video.Demo.on) {
            pendingAck = new Ack(t, seen, clientTicks); // sent once the last frame of this tick is drawn
        } else if (mc.getConnection() != null) {
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
                return "{\"ok\":true,\"stepping\":" + stepping + "}";
            }
            case "n.demo" -> {
                boolean on = "1".equals(p.get("on"));
                java.util.concurrent.CompletableFuture<String> r = new java.util.concurrent.CompletableFuture<>();
                // On the render thread between loops, so the switch never lands inside a frame or a tick.
                mc.execute(() -> {
                    if (on && stepping && !probe.mod.video.Demo.on) {
                        probe.mod.video.Demo.start(Integer.parseInt(p.getOrDefault("fps", "30")), virtNanos);
                        virtNanos = probe.mod.video.Demo.nanosFor(0);
                        demoWaitLoops = 0;
                    } else if (!on && probe.mod.video.Demo.on) {
                        probe.mod.video.Demo.on = false;
                        if (pendingAck != null) {
                            ClientPlayNetworking.send(pendingAck);
                            acksSent++;
                            lastAckTick = pendingAck.tick;
                            pendingAck = null;
                        }
                        // Back on the tick grid: the next grant adds 50 ms from here.
                    }
                    r.complete("{\"ok\":true,\"demo\":" + probe.mod.video.Demo.on + ",\"frame\":" + probe.mod.video.Demo.frame + ",\"ticksDone\":" + probe.mod.video.Demo.ticksDone
                        + ",\"waitLoops\":" + demoWaitLoops + ",\"virtMs\":" + virtNanos / 1_000_000 + "}");
                });
                try {
                    return r.get(20, java.util.concurrent.TimeUnit.SECONDS);
                } catch (Exception e) {
                    throw new RuntimeException(e);
                }
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
