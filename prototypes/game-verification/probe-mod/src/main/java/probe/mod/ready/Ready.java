package probe.mod.ready;

import com.mojang.blaze3d.pipeline.RenderTarget;
import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.renderpearl.api.buffers.GpuBuffer;
import com.mojang.renderpearl.api.buffers.GpuBufferSlice;
import com.mojang.renderpearl.api.textures.GpuTexture;
import java.nio.ByteOrder;
import java.nio.IntBuffer;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.ViewArea;
import net.minecraft.client.renderer.chunk.CompiledSectionMesh;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.AABB;
import net.minecraft.world.phys.Vec3;
import probe.mod.Probe;
import probe.mod.mixin.HudAccessor;
import probe.mod.observe.Drawn;
import probe.mod.observe.mixin.LevelRendererAccessor;

/**
 * Spike E: one trace per repeat. Every client loop (gated or drawn) appends one row with the loop
 * number, time, client tick, whether it drew, and the requirement's facts as bits. Ping acks are kept
 * with the loop that handled them. Drawn loops also read the whole frame back and keep its hash and
 * its difference against a clean reference frame. Signals are judged afterwards from the trace.
 */
public final class Ready {
    // Fact bits, one row per loop.
    static final int HELD = 1, VIEW = 2, TITLE_IN = 4, DRAWN = 8, LEVEL = 16, SCREEN_NONE = 32, CHUNKS = 64, FEET = 128,
        SETTLED = 256, QUEUE_EMPTY = 512, TOASTS_NONE = 1024, MESHED = 2048, HANDS = 4096;

    private record Spec(String[] needles, String ent, String title, BlockPos block, String material, String chat, boolean pix, String refSlot,
                        int radius, boolean freeze, boolean hud) {}
    private record Row(long loop, long at, long tick, boolean drawn, int bits, int state) {}
    private record Pix(long loop, int count, long hash) {}
    public record Ack(int id, long loop, long at) {}

    private static volatile Spec spec;
    private static final List<Row> rows = new ArrayList<>();
    private static final List<Pix> pix = new ArrayList<>();
    private static final List<Ack> acks = new ArrayList<>();
    private static long startAt;
    private static final int RING = 6;
    private static final GpuBuffer[] ring = new GpuBuffer[RING];
    private static final boolean[] busy = new boolean[RING];
    private static int[] ref;
    private static int w, h;
    private static long missed;
    private static long readNanos;
    private static long readCount;

    private Ready() {}

    /** Client thread, inside handlePing. Kept always (bounded) so a watch can ask for acks after it was armed. */
    public static void onPing(int id) {
        synchronized (acks) {
            acks.add(new Ack(id, Probe.frames() + 1, micros()));
            if (acks.size() > 20000) acks.subList(0, 10000).clear();
        }
    }

    /** Client thread, end of every loop. */
    public static void afterFrame(Minecraft mc, long loop, long tick, String perceived, boolean drawn) {
        Spec s = spec;
        if (s == null) return;
        if (s.freeze && mc.level != null && !mc.level.tickRateManager().isFrozen()) {
            // Terrain: water and leaves animate forever, so frames only settle with the client level frozen (spike F).
            mc.level.tickRateManager().setFrozen(true);
            probe.mod.golden.Golden.animationsToStart(mc);
        }
        int bits = facts(mc, s, perceived, drawn);
        if (s.hud && ((bits & TOASTS_NONE) == 0 || !((probe.mod.mixin.ChatAccessor) mc.gui.hud.getChat()).probe$allMessages().isEmpty())) {
            // Framework knob: join toasts and the join chat line are cleared as they appear (spikes C and F).
            mc.gui.toastManager().clear();
            mc.gui.hud.getChat().clearMessages(false);
        }
        synchronized (rows) {
            if (rows.size() < 200000) rows.add(new Row(loop, micros(), tick, drawn, bits, stateHash(perceived)));
        }
    }

    /** Hash of everything the player could perceive, minus the barrier id and the per tick title and bar counters. */
    static int stateHash(String perceived) {
        String s = perceived;
        for (String key : new String[] {"\"ping\":", "\"titleTime\":", "\"barTime\":", "\"compiledAt\":", "\"settledAt\":"}) {
            int i = s.indexOf(key);
            if (i < 0) continue;
            int v = i + key.length();
            int end = s.charAt(v) == '"' ? s.indexOf('"', v + 1) + 1 : s.indexOf(',', v);
            s = s.substring(0, i) + (end <= 0 || end >= s.length() ? "" : s.substring(end));
        }
        return s.hashCode();
    }

    private static int facts(Minecraft mc, Spec s, String perceived, boolean drawn) {
        int bits = 0;
        boolean held = s.needles.length > 0;
        for (String n : s.needles) {
            if (!perceived.contains(n)) {
                held = false;
                break;
            }
        }
        if (mc.level != null && mc.player != null) {
            if (s.block != null) {
                String id = BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(s.block).getBlock()).toString();
                held = id.equals(s.material);
                if (held && meshed(mc, s.block) && drawn) bits |= MESHED;
            }
            if (s.ent != null) {
                Entity e = find(mc, s.ent);
                held = e != null;
                if (e != null && inView(mc, e)) bits |= VIEW;
                if (drawn && drawnEntity(s.ent)) bits |= DRAWN;
            }
        }
        if (s.title != null) {
            HudAccessor hud = (HudAccessor) mc.gui.hud;
            var t = hud.probe$title();
            held = t != null && t.getString().equals(s.title) && hud.probe$titleTime() > 0;
            if (held && hud.probe$titleTime() <= hud.probe$fadeOut() + hud.probe$stay()) bits |= TITLE_IN;
            if (drawn && drawnText(s.title, 255)) bits |= DRAWN;
        }
        if (s.chat != null && drawn && drawnText(s.chat, 0)) bits |= DRAWN;
        if (held) bits |= HELD;
        bits |= start(mc, s);
        return bits;
    }

    /** Start candidates, the same for every watch. */
    private static int start(Minecraft mc, Spec s) {
        int bits = 0;
        if (mc.gui.screen() == null) bits |= SCREEN_NONE;
        var toasts = (probe.mod.ready.mixin.ToastAccessor) mc.gui.toastManager();
        if (toasts.probe$visible().isEmpty() && toasts.probe$queued().isEmpty()) bits |= TOASTS_NONE;
        if (mc.level == null || mc.player == null) return bits;
        bits |= LEVEL;
        // First person hands back up and the attack cooldown bar gone: both restart on a new level and are tick driven.
        var hands = (probe.mod.ready.mixin.HandsAccessor) mc.player.firstPersonHandsAndItems();
        if (hands.probe$main() == hands.probe$oMain() && hands.probe$off() == hands.probe$oOff() && mc.player.getAttackStrengthScale(0f) >= 1f) bits |= HANDS;
        BlockPos feet = mc.player.blockPosition();
        int cx = feet.getX() >> 4, cz = feet.getZ() >> 4, r = s.radius;
        boolean all = true;
        for (int x = -r; x <= r && all; x++) for (int z = -r; z <= r; z++) if (!mc.level.getChunkSource().hasChunk(cx + x, cz + z)) {
            all = false;
            break;
        }
        if (all) bits |= CHUNKS;
        if (mc.levelRenderer.isSectionCompiledAndVisible(feet.below(), 0)) bits |= FEET;
        if (mc.levelRenderer.hasRenderedAllSections()) bits |= QUEUE_EMPTY;
        boolean every = true;
        for (int x = -1; x <= 1 && every; x++) for (int z = -1; z <= 1; z++) if (!mc.levelRenderer.isSectionCompiledAndVisible(feet.below().offset(x * 16, 0, z * 16), 0)) {
            every = false;
            break;
        }
        if (every && (bits & QUEUE_EMPTY) != 0) bits |= SETTLED;
        return bits;
    }

    private static Entity find(Minecraft mc, String name) {
        for (Entity e : mc.level.entitiesForRendering()) {
            var n = e.getCustomName();
            if (n != null && n.getString().equals(name)) return e;
        }
        return null;
    }

    /** Entity centre inside the camera's view cone, from the player's eye and look, not the render state. */
    private static boolean inView(Minecraft mc, Entity e) {
        float partial = mc.getDeltaTracker().getGameTimeDeltaPartialTick(false);
        Vec3 eye = mc.player.getEyePosition(partial);
        Vec3 c = e.getPosition(partial).add(0, e.getBbHeight() / 2, 0);
        Vec3 d = c.subtract(eye);
        Vec3 fwd = mc.player.getViewVector(partial);
        Vec3 up = new Vec3(0, 1, 0);
        Vec3 right = fwd.cross(up).normalize();
        Vec3 upv = right.cross(fwd).normalize();
        double z = d.dot(fwd);
        if (z <= 0.05) return false;
        double vHalf = Math.toRadians(mc.options.fov().get() / 2.0);
        double aspect = (double) mc.getWindow().getWidth() / mc.getWindow().getHeight();
        double hHalf = Math.atan(Math.tan(vHalf) * aspect);
        return Math.abs(d.dot(right) / z) <= Math.tan(hHalf) && Math.abs(d.dot(upv) / z) <= Math.tan(vHalf);
    }

    private static boolean drawnEntity(String name) {
        String json = Drawn.frameJson();
        return json.contains("\"name\":\"" + name + "\"");
    }

    private static boolean drawnText(String text, int minAlpha) {
        String json = Drawn.frameJson();
        int at = json.indexOf("\"t\":\"" + text);
        while (at >= 0) {
            int c = json.lastIndexOf("\"c\":", at);
            if (c >= 0) {
                int end = json.indexOf(',', c);
                long color = Long.parseLong(json.substring(c + 4, end));
                int alpha = (int) ((color >>> 24) & 255);
                if (alpha >= minAlpha) return true;
            }
            at = json.indexOf("\"t\":\"" + text, at + 1);
        }
        return false;
    }

    private static Object heldMesh;
    private static boolean heldSeen;

    /**
     * Section compiled, in the visible list, block in the frustum, and a mesh newer than the one the
     * section had when the client first held the block.
     */
    private static boolean meshed(Minecraft mc, BlockPos pos) {
        ViewArea area = ((LevelRendererAccessor) mc.levelRenderer).probe$viewArea();
        SectionRenderDispatcher.RenderSection s = area == null ? null : area.getRenderSectionAt(pos);
        if (s == null) return false;
        Object mesh = s.sectionMesh.get();
        if (!heldSeen) {
            heldSeen = true;
            heldMesh = mesh;
        }
        if (mesh == CompiledSectionMesh.UNCOMPILED || mesh == heldMesh) return false;
        if (!mc.levelRenderer.visibleSections().contains(s)) return false;
        return mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState.cullFrustum.isVisible(new AABB(pos));
    }

    /** Client thread, right after the frame was drawn into mainRenderTarget. */
    public static void afterRender(Minecraft mc) {
        Spec s = spec;
        if (s == null || !s.pix || ref == null) return;
        long t0 = System.nanoTime();
        RenderTarget target = mc.gameRenderer.mainRenderTarget();
        if (target.width != w || target.height != h) return;
        int idx = -1;
        for (int i = 0; i < RING; i++) if (!busy[i]) {
            idx = i;
            break;
        }
        if (idx < 0) {
            missed++;
            return;
        }
        int slot = idx;
        busy[slot] = true;
        long loop = Probe.frames() + 1;
        GpuTexture tex = target.getColorTexture();
        GpuBuffer buf = ring[slot];
        RenderSystem.getDevice().createCommandEncoder().copyTextureToBuffer(tex, buf, 0L, () -> {
            try (GpuBufferSlice.MappedView read = buf.map(true, false)) {
                IntBuffer px = read.data().duplicate().order(ByteOrder.nativeOrder()).asIntBuffer();
                int count = 0;
                long hash = 1125899906842597L;
                int[] r = ref;
                for (int i = 0; i < r.length; i++) {
                    int c = px.get(i) | 0xFF000000;
                    hash = 31 * hash + c;
                    int d = r[i];
                    if (c != d) {
                        int dr = Math.abs((c & 255) - (d & 255)), dg = Math.abs(((c >> 8) & 255) - ((d >> 8) & 255)), db = Math.abs(((c >> 16) & 255) - ((d >> 16) & 255));
                        if (Math.max(dr, Math.max(dg, db)) > 8) count++;
                    }
                }
                synchronized (pix) {
                    if (pix.size() < 100000) pix.add(new Pix(loop, count, hash));
                }
            } finally {
                busy[slot] = false;
            }
        }, 0);
        readNanos += System.nanoTime() - t0;
        readCount++;
    }

    private static <T> T onClient(Minecraft mc, java.util.function.Supplier<T> s) throws Exception {
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

    /** Reads the frame drawn next into the reference; the pixel trace counts differences against it. */
    private static String setRef(Minecraft mc, int frames) throws Exception {
        CompletableFuture<int[]> f = new CompletableFuture<>();
        probe.mod.speed.Speed.drawThen(frames, () -> {
            RenderTarget target = mc.gameRenderer.mainRenderTarget();
            ensureRing(target);
            GpuBuffer buf = RenderSystem.getDevice().createBuffer(() -> "probe ref", GpuBuffer.USAGE_MAP_READ | GpuBuffer.USAGE_COPY_DST,
                (long) w * h * target.getColorTexture().getFormat().blockSize());
            RenderSystem.getDevice().createCommandEncoder().copyTextureToBuffer(target.getColorTexture(), buf, 0L, () -> {
                int[] out = new int[w * h];
                try (GpuBufferSlice.MappedView read = buf.map(true, false)) {
                    IntBuffer px = read.data().duplicate().order(ByteOrder.nativeOrder()).asIntBuffer();
                    for (int i = 0; i < out.length; i++) out[i] = px.get(i) | 0xFF000000;
                }
                buf.close();
                f.complete(out);
            }, 0);
        });
        int[] r = f.get(30, TimeUnit.SECONDS);
        ref = r;
        long hash = 1125899906842597L;
        for (int c : r) hash = 31 * hash + c;
        return "{\"ok\":true,\"w\":" + w + ",\"h\":" + h + ",\"hash\":" + hash + "}";
    }

    private static void ensureRing(RenderTarget target) {
        if (ring[0] != null && target.width == w && target.height == h) return;
        w = target.width;
        h = target.height;
        long size = (long) w * h * target.getColorTexture().getFormat().blockSize();
        for (int i = 0; i < RING; i++) {
            if (ring[i] != null) ring[i].close();
            ring[i] = RenderSystem.getDevice().createBuffer(() -> "probe ready", GpuBuffer.USAGE_MAP_READ | GpuBuffer.USAGE_COPY_DST, size);
            busy[i] = false;
        }
    }

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        return switch (name) {
            case "r.watch" -> {
                String needles = p.getOrDefault("needles", "");
                BlockPos block = null;
                if (p.containsKey("block")) {
                    String[] c = p.get("block").split(",");
                    block = new BlockPos(Integer.parseInt(c[0]), Integer.parseInt(c[1]), Integer.parseInt(c[2]));
                }
                Spec s = new Spec(needles.isEmpty() ? new String[0] : needles.split("\\|\\|"), p.get("ent"), p.get("title"), block,
                    p.get("material"), p.get("chat"), "1".equals(p.get("pix")), p.get("ref"), Integer.parseInt(p.getOrDefault("radius", "2")),
                    "1".equals(p.get("freeze")), "1".equals(p.get("hud")));
                yield onClient(mc, () -> {
                    synchronized (rows) {
                        rows.clear();
                    }
                    synchronized (pix) {
                        pix.clear();
                    }
                    heldSeen = false;
                    heldMesh = null;
                    missed = 0;
                    readNanos = 0;
                    readCount = 0;
                    startAt = micros();
                    spec = s;
                    return "{\"ok\":true,\"loop\":" + Probe.frames() + ",\"at\":" + startAt + "}";
                });
            }
            case "r.stop" -> {
                long sincePing = Long.parseLong(p.getOrDefault("pingFrom", "0"));
                // Let readbacks still in flight land: two more loops.
                long target = Probe.frames() + 3;
                long deadline = System.nanoTime() + 2_000_000_000L;
                while (Probe.frames() < target && System.nanoTime() < deadline) LockSupport.parkNanos(200_000);
                String out = onClient(mc, () -> {
                    spec = null;
                    return json(sincePing);
                });
                yield out;
            }
            case "r.ref" -> setRef(mc, Integer.parseInt(p.getOrDefault("frames", "3")));
            case "r.lag" -> {
                long ms = Long.parseLong(p.get("ms"));
                // Thread.sleep: execute() unparks the client thread, so a parkNanos there would return at once.
                mc.execute(() -> {
                    try {
                        Thread.sleep(ms);
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                    }
                });
                yield "{\"ok\":true,\"at\":" + micros() + "}";
            }
            case "r.wait" -> {
                // Waits until every listed barrier id was handled; ids can arrive in any order.
                String[] ids = p.get("ids").split(",");
                long deadline = System.nanoTime() + Long.parseLong(p.getOrDefault("timeoutMs", "20000")) * 1_000_000L;
                boolean all = false;
                while (!all && System.nanoTime() < deadline) {
                    all = true;
                    synchronized (acks) {
                        for (String id : ids) {
                            int want = Integer.parseInt(id);
                            boolean seen = false;
                            for (int k = acks.size() - 1; k >= 0 && k >= acks.size() - 200; k--) if (acks.get(k).id() == want) {
                                seen = true;
                                break;
                            }
                            if (!seen) {
                                all = false;
                                break;
                            }
                        }
                    }
                    if (!all) LockSupport.parkNanos(500_000);
                }
                yield "{\"ok\":" + all + "}";
            }
            case "r.opts" -> onClient(mc, () -> {
                // Spike F's knobs that need no level: vignette off, view bob off, glint still, light flicker pinned.
                mc.options.vignette().set(false);
                mc.options.bobView().set(false);
                mc.options.glintSpeed().set(0.0);
                probe.mod.golden.Golden.flicker = true;
                return "{\"ok\":true}";
            });
            case "r.now" -> "{\"loop\":" + Probe.frames() + ",\"at\":" + micros() + "}";
            default -> null;
        };
    }

    private static String json(long sincePing) {
        StringBuilder b = new StringBuilder(64 * rows.size() + 1024);
        b.append("{\"start\":").append(startAt).append(",\"missed\":").append(missed).append(",\"readUs\":")
            .append(readCount == 0 ? 0 : readNanos / readCount / 1000.0).append(",\"rows\":[");
        synchronized (rows) {
            for (int i = 0; i < rows.size(); i++) {
                Row r = rows.get(i);
                if (i > 0) b.append(',');
                b.append('[').append(r.loop).append(',').append(r.at - startAt).append(',').append(r.tick).append(',').append(r.drawn ? 1 : 0).append(',').append(r.bits).append(',').append(r.state).append(']');
            }
        }
        b.append("],\"pix\":[");
        synchronized (pix) {
            for (int i = 0; i < pix.size(); i++) {
                Pix x = pix.get(i);
                if (i > 0) b.append(',');
                b.append('[').append(x.loop).append(',').append(x.count).append(',').append('"').append(Long.toHexString(x.hash)).append("\"]");
            }
        }
        b.append("],\"acks\":[");
        synchronized (acks) {
            boolean first = true;
            for (Ack a : acks) {
                if (a.id < sincePing) continue;
                if (!first) b.append(',');
                first = false;
                b.append('[').append(a.id).append(',').append(a.loop).append(',').append(a.at - startAt).append(']');
            }
        }
        b.append("]}");
        return b.toString();
    }

    private static long micros() {
        java.time.Instant now = java.time.Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    static String fmt(double v) {
        return String.format(Locale.ROOT, "%.3f", v);
    }
}
