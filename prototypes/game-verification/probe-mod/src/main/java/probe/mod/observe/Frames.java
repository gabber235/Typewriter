package probe.mod.observe;

import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.renderpearl.api.buffers.GpuBuffer;
import com.mojang.renderpearl.api.buffers.GpuBufferSlice;
import com.mojang.renderpearl.api.textures.GpuTexture;
import com.mojang.blaze3d.pipeline.RenderTarget;
import com.mojang.blaze3d.platform.NativeImage;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.function.Consumer;
import net.minecraft.client.Minecraft;

/** A3: raw frames from mainRenderTarget into memory, then difference masks. No PNG in the path. */
public final class Frames {
    public record Img(int w, int h, int[] px, long tick) {
        int at(int x, int yTop) {
            return px[x + (h - 1 - yTop) * w];
        }
    }

    public record Diff(int count, int x0, int y0, int x1, int y1, int r, int g, int b, int maxDelta, long sad) {
        public String json(String extra) {
            return "{\"count\":" + count + ",\"bbox\":[" + x0 + "," + y0 + "," + x1 + "," + y1 + "],\"rgb\":[" + r + "," + g + "," + b + "],\"maxDelta\":" + maxDelta + ",\"sad\":" + sad + extra + "}";
        }
    }

    private static final Map<String, Img> slots = new ConcurrentHashMap<>();

    private Frames() {}

    public static void put(String slot, Img i) {
        slots.put(slot, i);
    }

    public static Img get(String slot) {
        return slots.get(slot);
    }

    /** Client thread, after a frame was rendered. The copy completes on a later frame's pending tasks. */
    public static void grab(Minecraft mc, Consumer<Img> done) {
        RenderTarget target = mc.gameRenderer.mainRenderTarget();
        GpuTexture tex = target.getColorTexture();
        int w = target.width, h = target.height, size = tex.getFormat().blockSize();
        long tick = Drawn.ticks;
        GpuBuffer buffer = RenderSystem.getDevice().createBuffer(() -> "probe frame", 9, (long) w * h * size);
        RenderSystem.getDevice().createCommandEncoder().copyTextureToBuffer(tex, buffer, 0L, () -> {
            int[] px = new int[w * h];
            try (GpuBufferSlice.MappedView read = buffer.map(true, false)) {
                ByteBuffer data = read.data().duplicate().order(ByteOrder.nativeOrder());
                data.asIntBuffer().get(px);
            }
            buffer.close();
            done.accept(new Img(w, h, px, tick));
        }, 0);
    }

    public static CompletableFuture<Img> grabAfter(Minecraft mc, int frames) {
        CompletableFuture<Img> f = new CompletableFuture<>();
        probe.mod.speed.Speed.drawThen(frames, () -> grab(mc, f::complete));
        return f;
    }

    /** Mask: any channel differs by more than thr. Mean colour is taken from a over the mask. */
    public static Diff diff(Img a, Img b, int thr, int[] rect) {
        if (a.w != b.w || a.h != b.h) return new Diff(-1, 0, 0, 0, 0, 0, 0, 0, 0, 0);
        int x0 = rect == null ? 0 : Math.max(0, rect[0]), y0 = rect == null ? 0 : Math.max(0, rect[1]);
        int x1 = rect == null ? a.w : Math.min(a.w, rect[2]), y1 = rect == null ? a.h : Math.min(a.h, rect[3]);
        int count = 0, mx0 = Integer.MAX_VALUE, my0 = Integer.MAX_VALUE, mx1 = -1, my1 = -1, maxDelta = 0;
        long sr = 0, sg = 0, sb = 0, sad = 0;
        int[] pa = a.px, pb = b.px;
        for (int y = y0; y < y1; y++) {
            int row = (a.h - 1 - y) * a.w;
            for (int x = x0; x < x1; x++) {
                int ca = pa[row + x], cb = pb[row + x];
                if (ca == cb) continue;
                int dr = Math.abs((ca & 255) - (cb & 255)), dg = Math.abs(((ca >> 8) & 255) - ((cb >> 8) & 255)), db = Math.abs(((ca >> 16) & 255) - ((cb >> 16) & 255));
                int d = Math.max(dr, Math.max(dg, db));
                sad += dr + dg + db;
                if (d > maxDelta) maxDelta = d;
                if (d <= thr) continue;
                count++;
                sr += ca & 255;
                sg += (ca >> 8) & 255;
                sb += (ca >> 16) & 255;
                if (x < mx0) mx0 = x;
                if (y < my0) my0 = y;
                if (x > mx1) mx1 = x;
                if (y > my1) my1 = y;
            }
        }
        if (count == 0) return new Diff(0, 0, 0, 0, 0, 0, 0, 0, maxDelta, sad);
        return new Diff(count, mx0, my0, mx1, my1, (int) (sr / count), (int) (sg / count), (int) (sb / count), maxDelta, sad);
    }

    private static int delta(int ca, int cb) {
        return Math.max(Math.abs((ca & 255) - (cb & 255)), Math.max(Math.abs(((ca >> 8) & 255) - ((cb >> 8) & 255)), Math.abs(((ca >> 16) & 255) - ((cb >> 16) & 255))));
    }

    /** Pixels that differ between a and b, but not between a and c: what b's change explains alone. */
    public static int diffExcept(Img a, Img b, Img c, int thr, int[] rect) {
        if (a.w != b.w || a.w != c.w || a.h != b.h || a.h != c.h) return -1;
        int x0 = rect == null ? 0 : Math.max(0, rect[0]), y0 = rect == null ? 0 : Math.max(0, rect[1]);
        int x1 = rect == null ? a.w : Math.min(a.w, rect[2]), y1 = rect == null ? a.h : Math.min(a.h, rect[3]);
        int n = 0;
        for (int y = y0; y < y1; y++) {
            int row = (a.h - 1 - y) * a.w;
            for (int x = x0; x < x1; x++) {
                int i = row + x;
                if (a.px[i] != b.px[i] && delta(a.px[i], b.px[i]) > thr && delta(a.px[i], c.px[i]) <= thr) n++;
            }
        }
        return n;
    }

    /** Mask pixels whose colour in a is close to rgb. */
    public static int maskColor(Img a, Img b, int thr, int r, int g, int bl, int tol) {
        int n = 0;
        for (int i = 0; i < a.px.length; i++) {
            int c = a.px[i];
            if (c == b.px[i] || delta(c, b.px[i]) <= thr) continue;
            if (Math.abs((c & 255) - r) <= tol && Math.abs(((c >> 8) & 255) - g) <= tol && Math.abs(((c >> 16) & 255) - bl) <= tol) n++;
        }
        return n;
    }

    /** Pixels in rect close to rgb, for simple "this colour is present here" checks. */
    public static int colorCount(Img a, int r, int g, int b, int tol, int[] rect) {
        int x0 = rect == null ? 0 : Math.max(0, rect[0]), y0 = rect == null ? 0 : Math.max(0, rect[1]);
        int x1 = rect == null ? a.w : Math.min(a.w, rect[2]), y1 = rect == null ? a.h : Math.min(a.h, rect[3]);
        int n = 0;
        for (int y = y0; y < y1; y++) {
            int row = (a.h - 1 - y) * a.w;
            for (int x = x0; x < x1; x++) {
                int c = a.px[row + x];
                if (Math.abs((c & 255) - r) <= tol && Math.abs(((c >> 8) & 255) - g) <= tol && Math.abs(((c >> 16) & 255) - b) <= tol) n++;
            }
        }
        return n;
    }

    public static void png(Img a, Path path) throws Exception {
        Files.createDirectories(path.toAbsolutePath().getParent());
        try (NativeImage img = new NativeImage(a.w, a.h, false)) {
            for (int y = 0; y < a.h; y++) {
                for (int x = 0; x < a.w; x++) img.setPixelABGR(x, y, a.at(x, y) | 0xFF000000);
            }
            img.writeToFile(path);
        }
    }

    /** Mask as a PNG: red where a and b differ. */
    public static void maskPng(Img a, Img b, int thr, Path path) throws Exception {
        Files.createDirectories(path.toAbsolutePath().getParent());
        try (NativeImage img = new NativeImage(a.w, a.h, false)) {
            for (int y = 0; y < a.h; y++) {
                for (int x = 0; x < a.w; x++) {
                    int ca = a.at(x, y), cb = b.at(x, y);
                    int d = Math.max(Math.abs((ca & 255) - (cb & 255)), Math.max(Math.abs(((ca >> 8) & 255) - ((cb >> 8) & 255)), Math.abs(((ca >> 16) & 255) - ((cb >> 16) & 255))));
                    img.setPixelABGR(x, y, d > thr ? 0xFF0000FF : 0xFF000000);
                }
            }
            img.writeToFile(path);
        }
    }
}
