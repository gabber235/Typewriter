package probe.mod.observe;

import java.io.BufferedOutputStream;
import java.io.ByteArrayOutputStream;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.InetSocketAddress;
import java.net.Socket;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.LinkedBlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.function.Supplier;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.components.LerpingBossEvent;
import net.minecraft.client.gui.screens.ChatScreen;
import net.minecraft.client.renderer.ViewArea;
import net.minecraft.client.renderer.chunk.SectionRenderDispatcher;
import net.minecraft.client.renderer.state.gui.GuiTextRenderState;
import net.minecraft.core.BlockPos;
import net.minecraft.world.phys.AABB;
import probe.mod.mixin.HudAccessor;
import probe.mod.observe.mixin.BossAccessor;
import probe.mod.observe.mixin.GuiTextAccessor;
import probe.mod.observe.mixin.LevelRendererAccessor;
import probe.mod.streammix.ChatScreenAccessor;

/**
 * Stream prototype: after every drawn frame, build the perceived state as one complete record and send it
 * to the test process when its content differs from the last record sent. Framing on the socket:
 * int length (type byte plus body), type byte, DataOutputStream body.
 *
 *   type 1 record:  header (measurement fields, not part of the content) then content
 *   type 2 barrier: a vanilla ping below 2^30, echoed after the record of the first frame drawn after it
 *   type 3 reset:   a new requirement starts; the next frame is sent whatever it holds
 *
 * Content: legible text runs tagged with the element that drew them, chat lines since the reset,
 * on screen command suggestions, watched entities (drawn, visible pixels by A4), watched blocks, facts.
 *
 * A gated client draws one frame after each client tick and after each barrier. With A4 on, every
 * drawn watched entity costs one more frame drawn without it; step grants wait until the pair is read.
 */
public final class Stream {
    public static final byte RECORD = 1, BARRIER = 2, RESET = 3;
    private static final int IDLE = 0, BASE = 1, A4 = 2;

    static volatile boolean on;
    static volatile boolean a4;
    // Frames spike: every = a frame after every client tick; otherwise only while demand (a check of this
    // client's requirement waits for perception) and for barriers.
    static volatile boolean every = true;
    static volatile boolean demand;
    static volatile int[] watchIds = new int[0];
    static volatile BlockPos[] watchBlocks = new BlockPos[0];

    // Render thread.
    private static int state = IDLE;
    private static boolean want;
    private static final List<Integer> barriers = new ArrayList<>();
    private static final List<Long> barrierAt = new ArrayList<>();
    private static int serverTick = -1;
    private static long clientTick, tickEndNanos, frameStartNanos;
    private static byte[] lastContent;
    private static final List<String> chat = new ArrayList<>();
    private static long seq;

    // A4 pair in flight.
    private static Snap snap;
    private static int[] hideIds;
    private static volatile Frames.Img baseImg;
    private static Frames.Img[] hideImgs;
    private static volatile int grabsDone;
    private static int hideIdx;
    private static boolean hideWanted, hideDrawing;
    private static long a4Start;

    // Input helpers driven at client tick end.
    private static double walkTarget = -1, walkX, walkZ;
    private static final StringBuilder typing = new StringBuilder();

    // Counters.
    static long records, skipped, contentBytes, buildNanosSum, a4NanosSum, framesDrawn, barriersEchoed;

    // Sender.
    private static volatile Socket socket;
    private static final LinkedBlockingQueue<byte[]> queue = new LinkedBlockingQueue<>();
    private static final byte[] STOP = new byte[0];
    private static Thread sender;

    private Stream() {}

    record Run(String tag, String text) {}
    record EntRow(int id, boolean drawn, int pixels) {}
    static final class Snap {
        long frameNo, frameEnd, buildNanos;
        int tick;
        long clientTick, tickEnd, frameStart;
        final List<Run> runs = new ArrayList<>();
        final List<String> suggestions = new ArrayList<>();
        final List<EntRow> ents = new ArrayList<>();
        int[] pixels;
        List<Integer> barriers;
        List<Long> barrierAt;
    }

    // ---- hooks ----

    /** Tail of Minecraft.tick (N.afterTick). tick is the stepped server tick, or -1 when not stepping. */
    public static void onTick(Minecraft mc, int tick) {
        if (walkTarget >= 0 && mc.player != null) {
            double dx = mc.player.getX() - walkX, dz = mc.player.getZ() - walkZ;
            boolean go = Math.sqrt(dx * dx + dz * dz) < walkTarget;
            mc.options.keyUp.setDown(go);
            if (!go) walkTarget = -1;
        }
        if (!typing.isEmpty() && mc.gui.screen() instanceof ChatScreen cs) {
            ((ChatScreenAccessor) cs).probe$input().insertText(String.valueOf(typing.charAt(0)));
            typing.deleteCharAt(0);
        }
        if (!on) return;
        serverTick = tick;
        clientTick++;
        tickEndNanos = System.nanoTime();
        if (every || demand) want = true;
    }

    /** Render thread, handlePing, for a ping below 2^30. */
    public static void onBarrier(int id) {
        if (!on) return;
        barriers.add(id);
        barrierAt.add(System.nanoTime());
        want = true;
    }

    public static void onChat(String line) {
        if (on) chat.add(line);
    }

    /** Step grants wait while an A4 pair is in flight, so both frames see the same tick. */
    public static boolean holding() {
        return on && state == A4;
    }

    /** Speed.decideFrame: does the stream need this frame drawn. */
    public static boolean frameWanted() {
        if (!on) return false;
        if (state == IDLE && want) {
            want = false;
            state = BASE;
            frameStartNanos = System.nanoTime();
            return true;
        }
        if (state == A4 && hideWanted) {
            hideWanted = false;
            hideDrawing = true;
            Drawn.hideEntity = hideIds[hideIdx];
            return true;
        }
        return false;
    }

    /** Speed.afterFrame, after Drawn.endFrame, every loop. */
    public static void afterFrame(Minecraft mc, boolean rendered) {
        if (!on) return;
        if (state == A4) {
            if (rendered && hideDrawing) {
                hideDrawing = false;
                Drawn.hideEntity = Integer.MIN_VALUE;
                int k = hideIdx++;
                Frames.grab(mc, img -> {
                    hideImgs[k] = img;
                    grabsDone++;
                });
                if (hideIdx < hideIds.length) hideWanted = true;
            }
            if (baseImg != null && grabsDone == hideIds.length) {
                int[] px = new int[hideIds.length];
                for (int i = 0; i < px.length; i++) px[i] = Frames.diff(baseImg, hideImgs[i], 8, null).count();
                snap.pixels = px;
                a4NanosSum += System.nanoTime() - a4Start;
                long a4n = System.nanoTime() - a4Start;
                finish(snap, a4n);
                snap = null;
                baseImg = null;
                state = IDLE;
            }
            return;
        }
        if (!rendered || (state != BASE && state != IDLE)) return;
        framesDrawn++;
        long t0 = System.nanoTime();
        Snap s = snapshot(mc);
        s.frameEnd = t0;
        s.barriers = new ArrayList<>(barriers);
        s.barrierAt = new ArrayList<>(barrierAt);
        barriers.clear();
        barrierAt.clear();
        s.buildNanos = System.nanoTime() - t0;
        List<Integer> drawnIds = new ArrayList<>();
        if (a4) for (EntRow e : s.ents) if (e.drawn) drawnIds.add(e.id);
        if (drawnIds.isEmpty()) {
            finish(s, 0);
            state = IDLE;
            return;
        }
        snap = s;
        hideIds = drawnIds.stream().mapToInt(Integer::intValue).toArray();
        hideImgs = new Frames.Img[hideIds.length];
        grabsDone = 0;
        hideIdx = 0;
        a4Start = System.nanoTime();
        baseImg = null;
        Frames.grab(mc, img -> baseImg = img);
        hideWanted = true;
        state = A4;
    }

    // ---- record ----

    private static Snap snapshot(Minecraft mc) {
        Drawn.Frame f = Drawn.last;
        Snap s = new Snap();
        s.frameNo = f.no;
        s.tick = serverTick;
        s.clientTick = clientTick;
        s.tickEnd = tickEndNanos;
        s.frameStart = frameStartNanos;
        String sub = null;
        var subC = ((HudAccessor) (Object) mc.gui.hud).probe$subtitle();
        if (subC != null) sub = subC.getString();
        for (int i = 0; i < f.gui.size(); i++) {
            Drawn.GuiEl e = f.gui.get(i);
            if (e.kind() != 'T' || !(e.ref() instanceof GuiTextRenderState t)) continue;
            String text = J.str(((GuiTextAccessor) (Object) t).probe$text());
            if (text.isBlank()) continue;
            String tag = e.tag() == null ? "other" : e.tag();
            if (tag.equals("title") && sub != null && text.equals(sub)) tag = "subtitle";
            int alpha = (e.color() >>> 24) & 255;
            if (tag.equals("suggestions")) {
                if (alpha >= 8) s.suggestions.add(text);
                continue;
            }
            if (legibleGui(f, i, alpha)) s.runs.add(new Run(tag, text));
        }
        for (Drawn.WorldText w : f.world) {
            if (legibleWorld(f, w)) s.runs.add(new Run(w.mode().equals("NAMETAG") ? "nametag" : "world", w.text()));
        }
        for (int id : watchIds) {
            boolean drawn = false;
            for (Drawn.Ent e : f.ents) if (e.id == id && e.geo > 0) drawn = true;
            s.ents.add(new EntRow(id, drawn, 0));
        }
        return s;
    }

    /** observe.py gui_run and covered: alpha at least 8, more than half on screen, nothing opaque painted over it. */
    static boolean legibleGui(Drawn.Frame f, int idx, int alpha) {
        if (alpha < 8) return false;
        Drawn.GuiEl e = f.gui.get(idx);
        int[] b = e.box();
        int ix = Math.max(0, Math.min(b[2], f.guiW) - Math.max(b[0], 0));
        int iy = Math.max(0, Math.min(b[3], f.guiH) - Math.max(b[1], 0));
        int area = Math.max(1, (b[2] - b[0]) * (b[3] - b[1]));
        if ((double) ix * iy / area <= 0.5) return false;
        if (idx < f.blurAt) return false;
        for (int j = idx + 1; j < f.gui.size(); j++) {
            Drawn.GuiEl o = f.gui.get(j);
            if (o.kind() != 'R' && o.kind() != 'B') continue;
            if (o.kind() == 'R' && ((o.color() >>> 24) & 255) < 240) continue;
            int[] c = o.box();
            int ox = Math.max(0, Math.min(b[2], c[2]) - Math.max(b[0], c[0]));
            int oy = Math.max(0, Math.min(b[3], c[3]) - Math.max(b[1], c[1]));
            if ((double) ox * oy >= 0.9 * area) return false;
        }
        return true;
    }

    /** observe.py a2 "wtext": on screen, facing the camera, alpha at least 26, not the colour of its own background. */
    static boolean legibleWorld(Drawn.Frame f, Drawn.WorldText w) {
        if (w.text().isBlank()) return false;
        float[] p = w.screen();
        if (p == null) return false;
        boolean nametag = w.mode().equals("NAMETAG");
        float minX = Float.MAX_VALUE, maxX = -Float.MAX_VALUE, minY = Float.MAX_VALUE, maxY = -Float.MAX_VALUE;
        for (int i = 0; i < p.length; i += 2) {
            minX = Math.min(minX, p[i]);
            maxX = Math.max(maxX, p[i]);
            minY = Math.min(minY, p[i + 1]);
            maxY = Math.max(maxY, p[i + 1]);
        }
        if (!(maxX > 0 && minX < f.fbW && maxY > 0 && minY < f.fbH)) return false;
        if (nametag) return true;
        int alpha = (w.color() >>> 24) & 255;
        int color = w.style() >= 0 ? w.style() : (w.color() & 0xFFFFFF);
        boolean sameBg = ((w.bg() >>> 24) & 255) > 200 && (w.bg() & 0xFFFFFF) == color;
        return w.area() > 0 && alpha >= 26 && !sameBg;
    }

    private static void finish(Snap s, long a4Nanos) {
        Minecraft mc = Minecraft.getInstance();
        long t0 = System.nanoTime();
        byte[] content;
        try {
            content = content(mc, s);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        long build = s.buildNanos + (System.nanoTime() - t0);
        buildNanosSum += build;
        if (lastContent != null && Arrays.equals(content, lastContent)) {
            skipped++;
        } else {
            lastContent = content;
            records++;
            contentBytes += content.length;
            ByteArrayOutputStream bo = new ByteArrayOutputStream(content.length + 96);
            DataOutputStream o = new DataOutputStream(bo);
            try {
                o.writeLong(++seq);
                o.writeInt(s.tick);
                o.writeLong(s.clientTick);
                o.writeLong(s.frameNo);
                o.writeLong(s.tickEnd);
                o.writeLong(s.frameStart);
                o.writeLong(s.frameEnd);
                o.writeLong(build);
                o.writeLong(a4Nanos);
                o.writeLong(System.nanoTime());
                o.write(content);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            send(RECORD, bo.toByteArray());
        }
        for (int i = 0; i < s.barriers.size(); i++) {
            ByteArrayOutputStream bo = new ByteArrayOutputStream(32);
            DataOutputStream o = new DataOutputStream(bo);
            try {
                o.writeInt(s.barriers.get(i));
                o.writeLong(s.barrierAt.get(i));
                o.writeLong(System.nanoTime());
                o.writeLong(seq);
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
            send(BARRIER, bo.toByteArray());
            barriersEchoed++;
        }
    }

    private static byte[] content(Minecraft mc, Snap s) throws IOException {
        ByteArrayOutputStream bo = new ByteArrayOutputStream(512);
        DataOutputStream o = new DataOutputStream(bo);
        o.writeShort(s.runs.size());
        for (Run r : s.runs) {
            o.writeUTF(r.tag);
            o.writeUTF(r.text);
        }
        o.writeShort(chat.size());
        for (String c : chat) o.writeUTF(c);
        o.writeShort(s.suggestions.size());
        for (String c : s.suggestions) o.writeUTF(c);
        o.writeShort(s.ents.size());
        for (int i = 0; i < s.ents.size(); i++) {
            EntRow e = s.ents.get(i);
            int px = -1;
            if (s.pixels != null && hideIds != null) {
                for (int k = 0; k < hideIds.length; k++) if (hideIds[k] == e.id) px = s.pixels[k];
            }
            if (!e.drawn) px = 0;
            o.writeInt(e.id);
            o.writeBoolean(e.drawn);
            o.writeInt(px);
        }
        BlockPos[] blocks = watchBlocks;
        o.writeShort(blocks.length);
        ViewArea area = ((LevelRendererAccessor) mc.levelRenderer).probe$viewArea();
        for (BlockPos p : blocks) {
            o.writeInt(p.getX());
            o.writeInt(p.getY());
            o.writeInt(p.getZ());
            o.writeUTF(mc.level == null ? "?" : mc.level.getBlockState(p).toString());
            SectionRenderDispatcher.RenderSection sec = area == null ? null : area.getRenderSectionAt(p);
            boolean vis = sec != null && sec.sectionMesh.get() != net.minecraft.client.renderer.chunk.CompiledSectionMesh.UNCOMPILED
                && mc.levelRenderer.visibleSections().contains(sec)
                && mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState.cullFrustum.isVisible(new AABB(p));
            o.writeBoolean(vis);
        }
        var screen = mc.gui.screen();
        o.writeUTF(screen == null ? "" : screen.getClass().getSimpleName());
        o.writeBoolean(mc.gui.hud.isHidden());
        BlockPos at = mc.player == null ? BlockPos.ZERO : mc.player.blockPosition();
        o.writeInt(at.getX());
        o.writeInt(at.getY());
        o.writeInt(at.getZ());
        var events = ((BossAccessor) mc.gui.hud.getBossOverlay()).probe$events();
        o.writeShort(events.size());
        for (LerpingBossEvent b : events.values()) {
            o.writeUTF(b.getName().getString());
            o.writeByte(Math.round(b.getProgress() * 100));
        }
        o.writeFloat(mc.player == null ? 0 : mc.player.getHealth());
        return bo.toByteArray();
    }

    // ---- sender ----

    private static void send(byte type, byte[] body) {
        byte[] f = new byte[5 + body.length];
        int n = 1 + body.length;
        f[0] = (byte) (n >>> 24);
        f[1] = (byte) (n >>> 16);
        f[2] = (byte) (n >>> 8);
        f[3] = (byte) n;
        f[4] = type;
        System.arraycopy(body, 0, f, 5, body.length);
        queue.add(f);
    }

    private static void sendLoop(Socket s) {
        try (OutputStream out = new BufferedOutputStream(s.getOutputStream(), 1 << 16)) {
            while (true) {
                byte[] f = queue.take();
                if (f == STOP) break;
                out.write(f);
                while ((f = queue.poll()) != null) {
                    if (f == STOP) {
                        out.flush();
                        return;
                    }
                    out.write(f);
                }
                out.flush();
            }
            out.flush();
        } catch (IOException | InterruptedException e) {
            e.printStackTrace();
        }
    }

    // ---- live channel ----

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

    private static String stats() {
        return "{\"records\":" + records + ",\"skipped\":" + skipped + ",\"contentBytes\":" + contentBytes + ",\"buildNanos\":" + buildNanosSum
            + ",\"a4Nanos\":" + a4NanosSum + ",\"framesDrawn\":" + framesDrawn + ",\"barriersEchoed\":" + barriersEchoed + ",\"seq\":" + seq
            + ",\"queued\":" + queue.size() + "}";
    }

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        switch (name) {
            case "st.on" -> {
                Socket s = new Socket();
                s.setTcpNoDelay(true);
                s.connect(new InetSocketAddress("127.0.0.1", Integer.parseInt(p.get("port"))), 5000);
                socket = s;
                queue.clear();
                sender = new Thread(() -> sendLoop(s), "probe-stream-send");
                sender.setDaemon(true);
                sender.start();
                a4 = "1".equals(p.get("a4"));
                onClient(mc, () -> {
                    state = IDLE;
                    want = true;
                    lastContent = null;
                    chat.clear();
                    barriers.clear();
                    barrierAt.clear();
                    records = skipped = contentBytes = buildNanosSum = a4NanosSum = framesDrawn = barriersEchoed = 0;
                    on = true;
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.mode" -> {
                every = !"0".equals(p.get("every"));
                return "{\"ok\":true,\"every\":" + every + "}";
            }
            case "st.begin" -> {
                // A requirement starts on this client: clear the chat, reset the stream, draw from now on.
                String label = p.getOrDefault("name", "");
                onClient(mc, () -> {
                    mc.gui.hud.getChat().clearMessages(false);
                    chat.clear();
                    lastContent = null;
                    ByteArrayOutputStream bo = new ByteArrayOutputStream();
                    try {
                        DataOutputStream o = new DataOutputStream(bo);
                        o.writeUTF(label);
                        o.writeLong(System.nanoTime());
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                    send(RESET, bo.toByteArray());
                    demand = true;
                    want = true;
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.end" -> {
                demand = false;
                return "{\"ok\":true}";
            }
            case "st.a4" -> {
                a4 = "1".equals(p.get("on"));
                return "{\"ok\":true}";
            }
            case "st.reset" -> {
                String label = p.getOrDefault("name", "");
                onClient(mc, () -> {
                    chat.clear();
                    lastContent = null;
                    ByteArrayOutputStream bo = new ByteArrayOutputStream();
                    try {
                        DataOutputStream o = new DataOutputStream(bo);
                        o.writeUTF(label);
                        o.writeLong(System.nanoTime());
                    } catch (IOException e) {
                        throw new RuntimeException(e);
                    }
                    send(RESET, bo.toByteArray());
                    want = true;
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.watch" -> {
                String ids = p.getOrDefault("ids", "");
                watchIds = ids.isEmpty() ? new int[0] : Arrays.stream(ids.split(",")).mapToInt(Integer::parseInt).toArray();
                String bl = p.getOrDefault("blocks", "");
                List<BlockPos> bs = new ArrayList<>();
                if (!bl.isEmpty()) {
                    for (String b : bl.split(",")) {
                        String[] v = b.split(":");
                        bs.add(new BlockPos(Integer.parseInt(v[0]), Integer.parseInt(v[1]), Integer.parseInt(v[2])));
                    }
                }
                watchBlocks = bs.toArray(new BlockPos[0]);
                return "{\"ok\":true}";
            }
            case "st.off" -> {
                onClient(mc, () -> {
                    on = false;
                    state = IDLE;
                    Drawn.hideEntity = Integer.MIN_VALUE;
                    return 0;
                });
                queue.add(STOP);
                if (sender != null) sender.join(10000);
                if (socket != null) socket.close();
                socket = null;
                return stats();
            }
            case "st.stats" -> {
                return stats();
            }
            case "st.walk" -> {
                double blocks = Double.parseDouble(p.getOrDefault("blocks", "4"));
                onClient(mc, () -> {
                    walkX = mc.player.getX();
                    walkZ = mc.player.getZ();
                    walkTarget = blocks;
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.walked" -> {
                return onClient(mc, () -> String.format(java.util.Locale.ROOT, "{\"walking\":%b,\"dist\":%.3f,\"x\":%.3f,\"y\":%.3f,\"z\":%.3f}", walkTarget >= 0,
                    Math.hypot(mc.player.getX() - walkX, mc.player.getZ() - walkZ), mc.player.getX(), mc.player.getY(), mc.player.getZ()));
            }
            case "st.chat" -> {
                onClient(mc, () -> {
                    mc.gui.setScreen(new ChatScreen("", false));
                    typing.setLength(0);
                    typing.append(p.getOrDefault("text", ""));
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.close" -> {
                onClient(mc, () -> {
                    mc.gui.setScreen(null);
                    typing.setLength(0);
                    mc.options.keyPlayerList.setDown(false);
                    mc.options.keyUp.setDown(false);
                    walkTarget = -1;
                    return 0;
                });
                return "{\"ok\":true}";
            }
            case "st.tab" -> {
                boolean down = "1".equals(p.get("down"));
                onClient(mc, () -> {
                    mc.options.keyPlayerList.setDown(down);
                    return 0;
                });
                return "{\"ok\":true}";
            }
            default -> {
                return null;
            }
        }
    }
}
