package probe.mod.video;

import com.mojang.blaze3d.pipeline.RenderTarget;
import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.renderpearl.api.buffers.GpuBuffer;
import com.mojang.renderpearl.api.buffers.GpuBufferSlice;
import com.mojang.renderpearl.api.textures.GpuTexture;
import java.io.BufferedWriter;
import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ArrayBlockingQueue;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.minecraft.client.Minecraft;
import net.minecraft.util.Util;
import probe.mod.Probe;
import probe.mod.speed.Speed;

/**
 * Spike B. B1: the engine's own async readback (copyTextureToBuffer with a completion callback, the
 * pattern TracyFrameCapture uses) of mainRenderTarget after GameRenderer.render, into a ring of
 * persistent GPU buffers, then a writer thread pipes raw RGBA into ffmpeg. Every video frame gets a
 * sidecar line with the fact frame and client tick, so a clip lines up with facts.
 *
 * B4: in step mode the client clock (Util.timeSource) advances exactly 1/fps per frame and the client
 * ticks 20 times per virtual second, so the video is smooth game time however slow the renderer is.
 * Real time pacing is speed = server rate / 20; the server must be slowed so the renderer keeps up.
 */
public final class Video {
    record Pending(long slot, long frame, long tick, long at, int ping, long virtMs) {}

    record Out(byte[] data, Pending meta, int dups) {}

    private static final int RING = 4;

    private static volatile boolean recording;
    private static volatile boolean step;
    private static volatile long virtNanos;
    private static long stepNanos;
    private static double speed = 1.0;
    private static long paceStartReal;
    private static long paceFrames;
    private static long maxLagNanos;
    private static long lagFrames;

    private static int fps;
    private static boolean block;
    private static boolean everyFrame;
    private static long t0Micros;
    private static long nextSlot;
    private static long lastWrittenSlot = -1;
    private static int w, h;
    private static final GpuBuffer[] ring = new GpuBuffer[RING];
    private static final boolean[] busy = new boolean[RING];
    private static BlockingQueue<Out> queue;
    private static BlockingQueue<byte[]> pool;
    private static Thread writer;
    private static Process ffmpeg;
    private static OutputStream sink;
    private static BufferedWriter sidecar;
    private static volatile Throwable writerError;

    // stats
    private static long captured, skippedSlots, droppedBusy, droppedPool, issueNanos, callbackNanos, blockNanos, writeNanos, bytes, framesSeen;
    private static long dupsWritten;

    private Video() {}

    // ---------- B4 clock ----------

    /** Head of Minecraft.runTick: the virtual clock moves one frame per loop. */
    public static void beforeRunTick() {
        if (step) virtNanos += stepNanos;
    }

    public static boolean stepping() {
        return step;
    }

    private static void startStep(int outFps, double realSpeed) {
        virtNanos = Util.getNanos();
        stepNanos = 1_000_000_000L / outFps;
        speed = realSpeed;
        paceStartReal = System.nanoTime();
        paceFrames = 0;
        maxLagNanos = 0;
        lagFrames = 0;
        Util.setTimeSource(() -> virtNanos);
        step = true;
    }

    private static void stopStep() {
        if (!step) return;
        step = false;
        long offset = virtNanos - System.nanoTime();
        Util.setTimeSource(() -> System.nanoTime() + offset);
    }

    /** End of a frame in step mode: wait until real time catches up with game time at `speed`. */
    private static void pace() {
        if (!step) return;
        paceFrames++;
        long due = paceStartReal + (long) (paceFrames * stepNanos / speed);
        long now = System.nanoTime();
        if (due > now) {
            LockSupport.parkNanos(due - now);
        } else {
            long lag = now - due;
            if (lag > stepNanos) lagFrames++;
            if (lag > maxLagNanos) maxLagNanos = lag;
        }
    }

    // ---------- B1 capture ----------

    /** Right after GameRenderer.render() in a frame that draws. Render thread. */
    public static void afterRender(Minecraft mc) {
        if (!recording) return;
        framesSeen++;
        long start = System.nanoTime();
        try {
            long at = micros();
            long slot = step || everyFrame ? nextSlot : Math.round((at - t0Micros) * fps / 1e6);
            if (slot < nextSlot) {
                skippedSlots++;
                return;
            }
            RenderTarget target = mc.gameRenderer.mainRenderTarget();
            GpuTexture tex = target.getColorTexture();
            if (tex == null) return;
            if (target.width != w || target.height != h) {
                if (w != 0) throw new IllegalStateException("frame size changed during recording: " + w + "x" + h + " to " + target.width + "x" + target.height);
            }
            int idx = -1;
            for (int i = 0; i < RING; i++) {
                if (!busy[i]) {
                    idx = i;
                    break;
                }
            }
            if (idx < 0) {
                if (!block) {
                    droppedBusy++;
                    return;
                }
                // Step mode never loses a frame: let the pending copies finish.
                long b0 = System.nanoTime();
                while (idx < 0) {
                    RenderSystem.executePendingTasks();
                    for (int i = 0; i < RING; i++) if (!busy[i]) idx = i;
                    if (idx < 0) LockSupport.parkNanos(100_000);
                }
                blockNanos += System.nanoTime() - b0;
            }
            int slotIdx = idx;
            busy[slotIdx] = true;
            nextSlot = slot + 1;
            Pending meta = new Pending(slot, Probe.frames() + 1, Probe.ticks(), at, Speed.lastPing, Util.getMillis());
            GpuBuffer buf = ring[slotIdx];
            RenderSystem.getDevice().createCommandEncoder().copyTextureToBuffer(tex, buf, 0L, () -> onCopied(slotIdx, buf, meta), 0);
            captured++;
        } finally {
            issueNanos += System.nanoTime() - start;
        }
    }

    /** Runs in RenderSystem.executePendingTasks on a later frame, once the GPU copy is done. */
    private static void onCopied(int slotIdx, GpuBuffer buf, Pending meta) {
        long start = System.nanoTime();
        try {
            byte[] data = pool.poll();
            if (data == null) {
                if (block) {
                    long b0 = System.nanoTime();
                    try {
                        data = pool.take();
                    } catch (InterruptedException e) {
                        Thread.currentThread().interrupt();
                        return;
                    }
                    blockNanos += System.nanoTime() - b0;
                } else {
                    droppedPool++;
                    return;
                }
            }
            try (GpuBufferSlice.MappedView read = buf.map(true, false)) {
                ByteBuffer src = read.data().duplicate();
                src.get(0, data, 0, data.length);
            }
            long dups = Math.max(0, meta.slot() - lastWrittenSlot - 1);
            lastWrittenSlot = meta.slot();
            queue.add(new Out(data, meta, (int) dups));
        } finally {
            busy[slotIdx] = false;
            callbackNanos += System.nanoTime() - start;
        }
    }

    private static void writeLoop() {
        try {
            long n = 0;
            while (true) {
                Out o = queue.take();
                if (o.data() == null) break;
                long w0 = System.nanoTime();
                // A slot the renderer missed repeats the frame before it, so the file keeps real time.
                for (int i = 0; i <= o.dups(); i++) {
                    if (sink != null) sink.write(o.data());
                    bytes += o.data().length;
                }
                writeNanos += System.nanoTime() - w0;
                dupsWritten += o.dups();
                Pending m = o.meta();
                for (int i = o.dups(); i >= 0; i--) {
                    sidecar.write("{\"v\":" + (n++) + ",\"slot\":" + (m.slot() - i) + ",\"f\":" + m.frame() + ",\"t\":" + m.tick() + ",\"at\":" + m.at() + ",\"ping\":" + m.ping()
                        + ",\"virtMs\":" + m.virtMs() + (i > 0 ? ",\"dup\":true" : "") + "}\n");
                }
                pool.add(o.data());
            }
        } catch (Throwable t) {
            writerError = t;
        }
    }

    // ---------- control from the live channel ----------

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        return switch (name) {
            case "rec" -> start(p, mc);
            case "recStop" -> stop(mc);
            case "mark" -> "{\"ok\":true,\"slot\":" + (step || everyFrame || !recording ? nextSlot : Math.max(nextSlot, Math.round((micros() - t0Micros) * fps / 1e6))) + ",\"frame\":" + Probe.frames() + ",\"tick\":" + Probe.ticks() + ",\"at\":" + micros() + ",\"captured\":" + captured + "}";
            default -> null;
        };
    }

    private static String start(Map<String, String> p, Minecraft mc) throws Exception {
        if (recording) throw new IllegalStateException("already recording");
        fps = Integer.parseInt(p.getOrDefault("fps", "30"));
        String mode = p.getOrDefault("mode", "rt");
        String enc = p.getOrDefault("enc", "x264");
        block = "step".equals(mode) || "1".equals(p.get("block"));
        everyFrame = "all".equals(mode);
        Path out = Path.of(p.get("path"));
        Files.createDirectories(out.toAbsolutePath().getParent());
        captured = skippedSlots = droppedBusy = droppedPool = issueNanos = callbackNanos = blockNanos = writeNanos = bytes = framesSeen = dupsWritten = 0;
        nextSlot = 0;
        lastWrittenSlot = -1;
        writerError = null;
        java.util.concurrent.CompletableFuture<String> ready = new java.util.concurrent.CompletableFuture<>();
        mc.execute(() -> {
            try {
                RenderTarget target = mc.gameRenderer.mainRenderTarget();
                w = target.width;
                h = target.height;
                long size = (long) w * h * target.getColorTexture().getFormat().blockSize();
                for (int i = 0; i < RING; i++) {
                    if (ring[i] != null) ring[i].close();
                    ring[i] = RenderSystem.getDevice().createBuffer(() -> "probe video", GpuBuffer.USAGE_MAP_READ | GpuBuffer.USAGE_COPY_DST, size);
                    busy[i] = false;
                }
                queue = new ArrayBlockingQueue<>(64);
                pool = new ArrayBlockingQueue<>(12);
                for (int i = 0; i < 12; i++) pool.add(new byte[(int) size]);
                sidecar = Files.newBufferedWriter(Path.of(out + ".frames.jsonl"), StandardCharsets.UTF_8);
                ffmpeg = null;
                sink = null;
                if (!"null".equals(enc)) {
                    List<String> cmd = ffmpegCmd(enc, p, out);
                    ProcessBuilder pb = new ProcessBuilder(cmd).redirectErrorStream(true).redirectOutput(Path.of(out + ".ffmpeg.log").toFile());
                    ffmpeg = pb.start();
                    sink = new java.io.BufferedOutputStream(ffmpeg.getOutputStream(), 1 << 20);
                }
                writer = new Thread(Video::writeLoop, "probe-video-writer");
                writer.setDaemon(true);
                writer.start();
                if ("step".equals(mode)) startStep(fps, Double.parseDouble(p.getOrDefault("speed", "1.0")));
                t0Micros = micros();
                recording = true;
                ready.complete("{\"ok\":true,\"w\":" + w + ",\"h\":" + h + ",\"ffmpegPid\":" + (ffmpeg == null ? -1 : ffmpeg.pid()) + ",\"frame\":" + Probe.frames() + ",\"tick\":" + Probe.ticks() + ",\"at\":" + t0Micros + "}");
            } catch (Throwable t) {
                ready.completeExceptionally(t);
            }
        });
        return ready.get(20, TimeUnit.SECONDS);
    }

    private static List<String> ffmpegCmd(String enc, Map<String, String> p, Path out) {
        List<String> c = new ArrayList<>(List.of(System.getProperty("probe.ffmpeg", "ffmpeg"), "-hide_banner", "-loglevel", "info", "-y",
            "-f", "rawvideo", "-pix_fmt", "rgba", "-s", w + "x" + h, "-framerate", String.valueOf(fps), "-i", "pipe:0"));
        String vf = "vflip" + (p.containsKey("scale") ? ",scale=" + p.get("scale") + ":-2:flags=bilinear" : "");
        c.addAll(List.of("-vf", vf));
        switch (enc) {
            case "x264" -> c.addAll(List.of("-c:v", "libx264", "-preset", p.getOrDefault("preset", "veryfast"), "-crf", p.getOrDefault("crf", "23"), "-pix_fmt", "yuv420p"));
            case "vt" -> c.addAll(List.of("-c:v", "h264_videotoolbox", "-b:v", p.getOrDefault("bitrate", "2M"), "-pix_fmt", "yuv420p"));
            case "raw" -> {
                c.clear();
                c.addAll(List.of("sh", "-c", "cat > \"$0\"", out.toString()));
                return c;
            }
            default -> throw new IllegalArgumentException("enc " + enc);
        }
        if (p.containsKey("threads")) c.addAll(List.of("-threads", p.get("threads")));
        c.add(out.toString());
        return c;
    }

    private static String stop(Minecraft mc) throws Exception {
        if (!recording) throw new IllegalStateException("not recording");
        java.util.concurrent.CompletableFuture<Void> f = new java.util.concurrent.CompletableFuture<>();
        long stoppedAt = micros();
        mc.execute(() -> {
            recording = false;
            // drain copies still in flight
            long deadline = System.nanoTime() + 2_000_000_000L;
            while (System.nanoTime() < deadline) {
                boolean any = false;
                for (boolean b : busy) any |= b;
                if (!any) break;
                RenderSystem.executePendingTasks();
                LockSupport.parkNanos(200_000);
            }
            stopStep();
            f.complete(null);
        });
        f.get(20, TimeUnit.SECONDS);
        queue.put(new Out(null, null, 0));
        writer.join(60_000);
        sidecar.close();
        long encodeWaitMs = 0;
        String cpu = "null";
        int exit = 0;
        if (sink != null) {
            long e0 = System.nanoTime();
            sink.close();
            ffmpeg.waitFor(120, TimeUnit.SECONDS);
            encodeWaitMs = (System.nanoTime() - e0) / 1_000_000;
            exit = ffmpeg.exitValue();
            cpu = ffmpeg.info().totalCpuDuration().map(Duration::toMillis).map(String::valueOf).orElse("null");
        }
        String r = "{\"ok\":true,\"framesSeen\":" + framesSeen + ",\"captured\":" + captured + ",\"skippedSlots\":" + skippedSlots + ",\"droppedBusy\":" + droppedBusy + ",\"droppedPool\":" + droppedPool
            + ",\"dups\":" + dupsWritten + ",\"slots\":" + nextSlot + ",\"issueUsPerCapture\":" + (captured == 0 ? 0 : issueNanos / captured / 1000.0) + ",\"callbackUsPerCapture\":" + (captured == 0 ? 0 : callbackNanos / captured / 1000.0)
            + ",\"blockMs\":" + blockNanos / 1_000_000 + ",\"writeMs\":" + writeNanos / 1_000_000 + ",\"bytes\":" + bytes + ",\"encodeTailMs\":" + encodeWaitMs + ",\"ffmpegCpuMs\":" + cpu + ",\"exit\":" + exit
            + ",\"stepLagFrames\":" + lagFrames + ",\"stepMaxLagMs\":" + maxLagNanos / 1_000_000 + ",\"t0\":" + t0Micros + ",\"t1\":" + stoppedAt
            + ",\"writerError\":" + (writerError == null ? "null" : "\"" + writerError.toString().replace("\"", "'") + "\"") + "}";
        w = 0;
        h = 0;
        return r;
    }

    /** End of renderFrame. */
    public static void afterFrame() {
        if (recording || step) pace();
    }

    private static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }
}
