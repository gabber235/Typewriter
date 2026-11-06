package probe.mod.speed;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Path;
import java.time.Instant;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.minecraft.client.Minecraft;
import net.minecraft.client.Screenshot;
import net.minecraft.client.gui.screens.ConnectScreen;
import net.minecraft.client.gui.screens.TitleScreen;
import net.minecraft.client.multiplayer.ServerData;
import net.minecraft.client.multiplayer.resolver.ServerAddress;
import net.minecraft.core.BlockPos;

/**
 * Spike C: live channel, render gate, clock uncap. One JSON reply line per request line
 * "name?k=v&k=v". Port comes from -Dprobe.live.port.
 */
public final class Speed {
    public static volatile int lastPing = -1;
    public static volatile boolean uncapped;
    public static volatile int gateMode;
    public static volatile long parkNanos = 2_000_000;
    private static volatile int framesToRender;
    private static boolean thisFrameSkipped;
    private static volatile Runnable afterRendered;

    record Snap(long seq, long at, long frame, long tick, int ping, String perceived) {}

    private static final Object LOCK = new Object();
    private static volatile Snap latest = new Snap(0, 0, 0, 0, -1, "");
    private static long seq;
    private static int waiters;

    public static void init() {
        int port = Integer.getInteger("probe.live.port", 0);
        if (port == 0) return;
        Thread t = new Thread(() -> {
            try (ServerSocket server = new ServerSocket(port, 8, InetAddress.getLoopbackAddress())) {
                while (true) {
                    Socket s = server.accept();
                    s.setTcpNoDelay(true);
                    Thread c = new Thread(() -> serve(s), "probe-live-conn");
                    c.setDaemon(true);
                    c.start();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }, "probe-live");
        t.setDaemon(true);
        t.start();
    }

    /** Decides once per frame, at the acquire call, whether this frame draws. */
    public static boolean decideFrame() {
        boolean render = gateMode == 0 || framesToRender > 0;
        if (framesToRender > 0) framesToRender--;
        thisFrameSkipped = !render;
        return thisFrameSkipped;
    }

    public static boolean skipExtract() {
        return gateMode == 2 && thisFrameSkipped;
    }

    public static boolean skipRender() {
        return thisFrameSkipped;
    }

    /** End of renderFrame. Publishes state, finishes on demand captures, paces a gated loop. */
    public static void afterFrame(Minecraft mc, long frame, long tick, String perceived) {
        publish(frame, tick, perceived);
        probe.mod.observe.Drawn.endFrame(mc, !thisFrameSkipped);
        probe.mod.observe.Ride.onFrame(mc, !thisFrameSkipped);
        probe.mod.ready.Ready.afterFrame(mc, frame, tick, perceived, !thisFrameSkipped);
        Runnable r = afterRendered;
        if (r != null && !thisFrameSkipped && framesToRender == 0) {
            afterRendered = null;
            r.run();
        }
        if (thisFrameSkipped && parkNanos > 0) LockSupport.parkNanos(parkNanos);
        if (!thisFrameSkipped) probe.mod.video.Video.afterFrame();
    }

    /** Draws n whole frames from now, in any gate mode, then runs r on the client thread. */
    public static void drawThen(int frames, Runnable r) {
        framesToRender = frames;
        afterRendered = r;
    }

    public static void publish(long frame, long tick, String perceived) {
        Snap s = new Snap(++seq, micros(), frame, tick, lastPing, perceived);
        latest = s;
        if (waiters > 0) {
            synchronized (LOCK) {
                LOCK.notifyAll();
            }
        }
    }

    private static void serve(Socket s) {
        try (s; BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
             OutputStream out = s.getOutputStream()) {
            String line;
            while ((line = in.readLine()) != null) {
                String reply;
                try {
                    reply = handle(line);
                } catch (Exception e) {
                    reply = "{\"error\":" + q(String.valueOf(e)) + "}";
                }
                out.write((reply + "\n").getBytes(StandardCharsets.UTF_8));
                out.flush();
            }
        } catch (IOException ignored) {
        }
    }

    private static String handle(String line) throws Exception {
        int qm = line.indexOf('?');
        String name = qm < 0 ? line : line.substring(0, qm);
        Map<String, String> p = query(qm < 0 ? "" : line.substring(qm + 1));
        Minecraft mc = Minecraft.getInstance();
        return switch (name) {
            case "observe" -> observe(p);
            case "state" -> {
                Snap s = awaitSnap(null, Integer.parseInt(p.getOrDefault("ping", "-1")), Integer.parseInt(p.getOrDefault("timeoutMs", "5000")));
                yield s == null ? "{\"ok\":false}" : snapJson(true, "state", s);
            }
            case "clearChat" -> {
                onClient(mc, () -> mc.gui.hud.getChat().clearMessages(false));
                yield "{\"ok\":true}";
            }
            case "clearTitleLocal" -> {
                onClient(mc, () -> {
                    mc.gui.hud.clearTitles();
                    mc.gui.hud.resetTitleTimes();
                });
                yield "{\"ok\":true}";
            }
            case "gate" -> {
                gateMode = Integer.parseInt(p.get("mode"));
                if (p.containsKey("parkMicros")) parkNanos = Long.parseLong(p.get("parkMicros")) * 1000;
                yield "{\"ok\":true,\"at\":" + micros() + "}";
            }
            case "fps" -> {
                int v = Integer.parseInt(p.get("limit"));
                onClient(mc, () -> mc.options.framerateLimit().set(v));
                yield "{\"ok\":true}";
            }
            case "uncap" -> {
                uncapped = "1".equals(p.get("on"));
                yield "{\"ok\":true}";
            }
            case "oneshot" -> oneshot(mc, p);
            case "shot" -> shot(mc, p.get("path"));
            case "reconnect" -> {
                String addr = p.get("addr");
                onClient(mc, () -> {
                    mc.disconnectWithProgressScreen(false);
                    ServerData data = new ServerData("probe", addr, ServerData.Type.OTHER);
                    ConnectScreen.startConnecting(new TitleScreen(), mc, ServerAddress.parseString(addr), data, false, null);
                });
                yield "{\"ok\":true}";
            }
            case "stats" -> "{\"fps\":" + mc.getFps() + ",\"frame\":" + latest.frame() + ",\"tick\":" + latest.tick() + ",\"at\":" + micros() + "}";
            default -> {
                String r = probe.mod.video.Video.handle(name, p, mc);
                if (r == null) r = probe.mod.golden.Golden.handle(name, p, mc);
                if (r == null) r = probe.mod.observe.Observe.handle(name, p, mc);
                if (r == null) r = probe.mod.ready.Ready.handle(name, p, mc);
                if (r == null) r = probe.mod.input.Input.handle(name, p, mc);
                yield r != null ? r : "{\"error\":\"unknown " + name + "\"}";
            }
        };
    }

    private static void onClient(Minecraft mc, Runnable r) throws Exception {
        CompletableFuture<Void> f = new CompletableFuture<>();
        mc.execute(() -> {
            try {
                r.run();
                f.complete(null);
            } catch (Throwable t) {
                f.completeExceptionally(t);
            }
        });
        f.get(20, TimeUnit.SECONDS);
    }

    /** Pass on needle; fail as soon as the ping barrier has passed without it; else fail on timeout. */
    private static String observe(Map<String, String> p) throws InterruptedException {
        String needle = p.get("needle");
        int ping = Integer.parseInt(p.getOrDefault("ping", "-1"));
        int timeout = Integer.parseInt(p.getOrDefault("timeoutMs", "2000"));
        long start = micros();
        long startSeq = latest.seq();
        long deadline = System.nanoTime() + timeout * 1_000_000L;
        try {
            synchronized (LOCK) {
                waiters++;
            }
            while (true) {
                Snap s = latest;
                if (s.seq() > startSeq) {
                    if (s.perceived().contains(needle)) return snapJsonShort(true, "seen", s, start);
                    if (ping >= 0 && s.ping() >= ping) return snapJsonShort(false, "barrier", s, start);
                }
                long left = deadline - System.nanoTime();
                if (left <= 0) return snapJsonShort(false, "timeout", s, start);
                synchronized (LOCK) {
                    if (latest == s) LOCK.wait(Math.max(1, left / 1_000_000L));
                }
            }
        } finally {
            synchronized (LOCK) {
                waiters--;
            }
        }
    }

    private static Snap awaitSnap(String needle, int ping, int timeout) throws InterruptedException {
        long startSeq = latest.seq();
        long deadline = System.nanoTime() + timeout * 1_000_000L;
        try {
            synchronized (LOCK) {
                waiters++;
            }
            while (true) {
                Snap s = latest;
                if (s.seq() > startSeq && s.ping() >= ping) return s;
                long left = deadline - System.nanoTime();
                if (left <= 0) return null;
                synchronized (LOCK) {
                    if (latest == s) LOCK.wait(Math.max(1, left / 1_000_000L));
                }
            }
        } finally {
            synchronized (LOCK) {
                waiters--;
            }
        }
    }

    /** While gated: draws exactly `frames` frames, then writes mainRenderTarget to a PNG. */
    private static String oneshot(Minecraft mc, Map<String, String> p) throws Exception {
        int frames = Integer.parseInt(p.getOrDefault("frames", "1"));
        String path = p.get("path");
        long start = micros();
        CompletableFuture<String> reply = new CompletableFuture<>();
        afterRendered = () -> {
            long drawn = micros();
            Screenshot.takeScreenshot(mc.gameRenderer.mainRenderTarget(), image -> {
                try (image) {
                    image.writeToFile(Path.of(path));
                    reply.complete("{\"ok\":true,\"start\":" + start + ",\"drawn\":" + drawn + ",\"written\":" + micros() + "}");
                } catch (IOException e) {
                    reply.complete("{\"error\":" + q(e.toString()) + "}");
                }
            });
        };
        framesToRender = frames;
        return reply.get(20, TimeUnit.SECONDS);
    }

    private static String shot(Minecraft mc, String path) throws Exception {
        long start = micros();
        CompletableFuture<String> reply = new CompletableFuture<>();
        mc.execute(() -> Screenshot.takeScreenshot(mc.gameRenderer.mainRenderTarget(), image -> {
            try (image) {
                image.writeToFile(Path.of(path));
                reply.complete("{\"ok\":true,\"start\":" + start + ",\"written\":" + micros() + "}");
            } catch (IOException e) {
                reply.complete("{\"error\":" + q(e.toString()) + "}");
            }
        }));
        return reply.get(20, TimeUnit.SECONDS);
    }

    /** Readiness facts: player chunk radius all present on the client, and feet section meshed. */
    public static void ready(Minecraft mc, StringBuilder b) {
        if (mc.level == null || mc.player == null) return;
        BlockPos feet = mc.player.blockPosition();
        int cx = feet.getX() >> 4, cz = feet.getZ() >> 4;
        int radius = mc.options.renderDistance().get();
        boolean all = true;
        var chunks = mc.level.getChunkSource();
        for (int x = -radius; x <= radius && all; x++) {
            for (int z = -radius; z <= radius; z++) {
                if (!chunks.hasChunk(cx + x, cz + z)) {
                    all = false;
                    break;
                }
            }
        }
        boolean screenFree = mc.gui.screen() == null;
        String at = mc.level.dimension().identifier() + "|" + cx + "," + cz;
        if (all && screenFree) b.append(",\"readyAt\":").append(q(at));
        if (all && screenFree && mc.levelRenderer.isSectionCompiledAndVisible(feet.below(), 0)) {
            b.append(",\"compiledAt\":").append(q(at));
            boolean every = mc.levelRenderer.hasRenderedAllSections();
            for (int x = -1; x <= 1 && every; x++) {
                for (int z = -1; z <= 1; z++) {
                    if (!mc.levelRenderer.isSectionCompiledAndVisible(feet.below().offset(x * 16, 0, z * 16), 0)) {
                        every = false;
                        break;
                    }
                }
            }
            if (every) b.append(",\"settledAt\":").append(q(at));
        }
    }

    private static String snapJsonShort(boolean ok, String why, Snap s, long start) {
        return "{\"ok\":" + ok + ",\"why\":\"" + why + "\",\"at\":" + s.at() + ",\"start\":" + start + ",\"frame\":" + s.frame() + ",\"tick\":" + s.tick() + "}";
    }

    private static String snapJson(boolean ok, String why, Snap s) {
        return "{\"ok\":" + ok + ",\"why\":\"" + why + "\",\"at\":" + s.at() + ",\"frame\":" + s.frame() + ",\"tick\":" + s.tick() + ",\"p\":{" + s.perceived() + "}}";
    }

    private static Map<String, String> query(String raw) {
        Map<String, String> out = new HashMap<>();
        for (String pair : raw.split("&")) {
            int eq = pair.indexOf('=');
            if (eq > 0) out.put(pair.substring(0, eq), URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8));
        }
        return out;
    }

    private static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    private static String q(String s) {
        return '"' + s.replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", " ") + '"';
    }
}
