package probe.mod.k;

import java.lang.ref.WeakReference;
import java.time.Instant;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import net.minecraft.client.Minecraft;
import net.minecraft.client.User;
import net.minecraft.client.gui.screens.ConnectScreen;
import net.minecraft.client.gui.screens.DisconnectedScreen;
import net.minecraft.client.gui.screens.TitleScreen;
import net.minecraft.client.multiplayer.ClientLevel;
import net.minecraft.client.multiplayer.ServerData;
import net.minecraft.client.multiplayer.chat.GuiMessage;
import net.minecraft.client.multiplayer.resolver.ServerAddress;
import net.minecraft.core.UUIDUtil;
import net.minecraft.world.item.ItemStack;
import probe.mod.k.mixin.UserAccessor;
import probe.mod.mixin.ChatAccessor;
import probe.mod.ready.Ready;

/**
 * Spike K: a warm client that changes identity, reconnects, reconnects by itself while Paper is down, and says
 * when it is ready again (E's start signal), plus what a leak check reads on the client.
 *
 *   k.user?name=          next connection logs in under this offline name (and its offline UUID)
 *   k.connect?addr=       leave the current server (if any) and connect to addr
 *   k.auto?addr=&on=&everyMs=   while on, connect to addr whenever the client sits disconnected
 *   k.mark                remember the current level; k.ready?newLevel=1 then waits for a different one
 *   k.ready?radius=&need=&newLevel=&timeoutMs=   first client loop where the start bits hold
 *   k.chat                chat lines on screen and the sent message history
 *   k.inv?name=           inventory stacks whose name contains name
 */
public final class K {
    private static volatile WeakReference<ClientLevel> marked = new WeakReference<>(null);
    private static volatile long markedAt;
    private static volatile String autoAddr;
    private static volatile int autoAttempts;
    private static Thread autoThread;
    private static volatile int dropped;

    private K() {}

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        return switch (name) {
            case "k.user" -> {
                String n = p.get("name");
                User u = new User(n, UUIDUtil.createOfflinePlayerUUID(n), "", Optional.empty(), Optional.empty());
                onClient(mc, () -> {
                    ((UserAccessor) mc).probe$setUser(u);
                    return 0;
                });
                yield "{\"ok\":true,\"uuid\":\"" + u.getProfileId() + "\"}";
            }
            case "k.connect" -> {
                String addr = p.get("addr");
                long at = onClient(mc, () -> {
                    connect(mc, addr);
                    return micros();
                });
                yield "{\"ok\":true,\"at\":" + at + "}";
            }
            case "k.auto" -> {
                autoAddr = "1".equals(p.getOrDefault("on", "1")) ? p.get("addr") : null;
                long every = Long.parseLong(p.getOrDefault("everyMs", "100"));
                startAuto(mc, every);
                yield "{\"ok\":true,\"attempts\":" + autoAttempts + "}";
            }
            case "k.mark" -> {
                long at = onClient(mc, () -> {
                    marked = new WeakReference<>(mc.level);
                    markedAt = micros();
                    return markedAt;
                });
                yield "{\"ok\":true,\"at\":" + at + "}";
            }
            case "k.gone" -> {
                // First client loop that has left the server by itself (the connection dropped).
                long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(Long.parseLong(p.getOrDefault("timeoutMs", "10000")));
                long at = -1;
                while (System.nanoTime() < deadline) {
                    // Read from this thread on purpose: the disconnect drops every queued client task (dropAllTasks).
                    long[] r = new long[] {micros(), mc.level == null && mc.getConnection() == null ? 1 : 0};
                    if (r[1] == 1) {
                        at = r[0];
                        break;
                    }
                    Thread.sleep(1);
                }
                yield "{\"ok\":" + (at > 0) + ",\"at\":" + at + "}";
            }
            case "k.ready" -> ready(mc, Integer.parseInt(p.getOrDefault("radius", "2")), Integer.parseInt(p.getOrDefault("need", "4208")),
                    "1".equals(p.getOrDefault("newLevel", "0")), Long.parseLong(p.getOrDefault("timeoutMs", "60000")));
            case "k.chat" -> onClient(mc, () -> {
                StringBuilder b = new StringBuilder("{\"lines\":[");
                boolean first = true;
                for (GuiMessage m : ((ChatAccessor) mc.gui.hud.getChat()).probe$allMessages()) {
                    if (!first) b.append(',');
                    first = false;
                    b.append(q(m.content().getString()));
                }
                b.append("],\"sent\":[");
                first = true;
                for (String s : mc.gui.hud.getChat().getRecentChat()) {
                    if (!first) b.append(',');
                    first = false;
                    b.append(q(s));
                }
                return b.append("]}").toString();
            });
            case "k.inv" -> onClient(mc, () -> {
                String needle = p.getOrDefault("name", "");
                int count = 0, stacks = 0;
                if (mc.player != null) {
                    for (ItemStack s : mc.player.getInventory().getNonEquipmentItems()) {
                        if (s.isEmpty()) continue;
                        stacks++;
                        if (s.getHoverName().getString().contains(needle)) count += s.getCount();
                    }
                }
                return "{\"count\":" + count + ",\"stacks\":" + stacks + ",\"effects\":" + (mc.player == null ? 0 : mc.player.getActiveEffects().size()) + "}";
            });
            default -> null;
        };
    }

    /** Leaves as the pause menu's Disconnect does. disconnectWithProgressScreen alone closes only the packet
     *  listener; the network connection stays open and Paper keeps the player until its 30 s timeout. */
    private static void connect(Minecraft mc, String addr) {
        if (mc.level != null || mc.getConnection() != null) mc.disconnectFromWorld(ClientLevel.DEFAULT_QUIT_MESSAGE);
        ServerData data = new ServerData("probe", addr, ServerData.Type.OTHER);
        ConnectScreen.startConnecting(new TitleScreen(), mc, ServerAddress.parseString(addr), data, false, null);
    }

    private static synchronized void startAuto(Minecraft mc, long every) {
        if (autoThread != null) return;
        autoThread = new Thread(() -> {
            while (true) {
                try {
                    Thread.sleep(every);
                    String addr = autoAddr;
                    if (addr == null) continue;
                    mc.execute(() -> {
                        if (autoAddr == null || mc.level != null || mc.gui.screen() instanceof ConnectScreen) return;
                        if (mc.gui.screen() instanceof DisconnectedScreen || mc.gui.screen() instanceof TitleScreen || mc.gui.screen() == null) {
                            autoAttempts++;
                            connect(mc, autoAddr);
                        }
                    });
                } catch (InterruptedException e) {
                    return;
                }
            }
        }, "probe-k-auto");
        autoThread.setDaemon(true);
        autoThread.start();
    }

    /** Polls once per client loop (tasks run at the start of each loop) until the bits hold. */
    private static String ready(Minecraft mc, int radius, int need, boolean newLevel, long timeoutMs) throws Exception {
        long deadline = System.nanoTime() + TimeUnit.MILLISECONDS.toNanos(timeoutMs);
        long goneAt = -1, levelAt = -1, chunksAt = -1;
        int polls = 0;
        int attempts0 = autoAttempts;
        while (System.nanoTime() < deadline) {
            long[] r = onClientPoll(mc, () -> {
                ClientLevel old = marked.get();
                boolean present = mc.level != null && mc.player != null && (!newLevel || mc.level != old);
                int bits = present ? Ready.startBits(mc, radius) : 0;
                return new long[] {micros(), mc.level == null ? 1 : 0, present ? 1 : 0, bits};
            });
            polls++;
            if (r[1] == 1 && goneAt < 0) goneAt = r[0];
            if (r[2] == 1 && levelAt < 0) levelAt = r[0];
            if (r[2] == 1 && (r[3] & 64) != 0 && chunksAt < 0) chunksAt = r[0];
            if (r[2] == 1 && (r[3] & need) == need) {
                return "{\"ok\":true,\"at\":" + r[0] + ",\"goneAt\":" + goneAt + ",\"levelAt\":" + levelAt + ",\"chunksAt\":" + chunksAt
                        + ",\"markedAt\":" + markedAt + ",\"polls\":" + polls + ",\"dropped\":" + dropped + ",\"attempts\":" + (autoAttempts - attempts0) + "}";
            }
            Thread.sleep(1);
        }
        return "{\"ok\":false,\"goneAt\":" + goneAt + ",\"levelAt\":" + levelAt + ",\"chunksAt\":" + chunksAt + ",\"polls\":" + polls
                + ",\"screen\":" + q(String.valueOf(mc.gui.screen() == null ? null : mc.gui.screen().getClass().getSimpleName())) + "}";
    }

    /** For side effect free reads: Minecraft.disconnect drops every queued task, so a dropped read is sent again. */
    private static <T> T onClientPoll(Minecraft mc, Supplier<T> s) throws Exception {
        for (int i = 0; ; i++) {
            CompletableFuture<T> f = new CompletableFuture<>();
            mc.execute(() -> {
                try {
                    f.complete(s.get());
                } catch (Throwable t) {
                    f.completeExceptionally(t);
                }
            });
            try {
                return f.get(1, TimeUnit.SECONDS);
            } catch (java.util.concurrent.TimeoutException e) {
                if (i >= 30) throw e;
                dropped++;
            }
        }
    }

    private static <T> T onClient(Minecraft mc, Supplier<T> s) throws Exception {
        CompletableFuture<T> f = new CompletableFuture<>();
        mc.execute(() -> {
            try {
                f.complete(s.get());
            } catch (Throwable t) {
                f.completeExceptionally(t);
            }
        });
        return f.get(30, TimeUnit.SECONDS);
    }

    private static String q(String s) {
        return "\"" + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") + "\"";
    }

    private static long micros() {
        Instant n = Instant.now();
        return n.getEpochSecond() * 1_000_000L + n.getNano() / 1000;
    }
}
