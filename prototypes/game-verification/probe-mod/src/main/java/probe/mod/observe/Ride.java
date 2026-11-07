package probe.mod.observe;

import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import java.util.concurrent.atomic.AtomicInteger;
import net.minecraft.client.Minecraft;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec3;

/** Scene 16: the camera path, sampled once per client tick and once per rendered frame. */
public final class Ride {
    private static volatile boolean recording;
    private static volatile boolean pixels;
    private static final List<double[]> tick = new ArrayList<>();
    private static final List<double[]> frame = new ArrayList<>();
    private static final List<double[]> flow = new ArrayList<>();
    private static Frames.Img prev;
    private static final AtomicInteger pending = new AtomicInteger();

    private Ride() {}

    public static void start(boolean withPixels) {
        synchronized (tick) {
            tick.clear();
            frame.clear();
            flow.clear();
        }
        prev = null;
        pixels = withPixels;
        recording = true;
    }

    public static void stop() {
        recording = false;
    }

    public static void onTick(Minecraft mc) {
        Drawn.ticks++;
        if (!recording) return;
        Entity cam = mc.getCameraEntity();
        if (cam == null) return;
        synchronized (tick) {
            tick.add(new double[] {System.nanoTime() / 1e6, cam.getX(), cam.getY(), cam.getZ()});
        }
    }

    public static void onFrame(Minecraft mc, boolean rendered) {
        if (!recording || !rendered) return;
        Vec3 a = mc.gameRenderer.mainCamera().position();
        Vec3 d = mc.gameRenderer.gameRenderState().levelRenderState.cameraRenderState.pos;
        double now = System.nanoTime() / 1e6;
        synchronized (tick) {
            frame.add(new double[] {now, a.x, a.y, a.z, d.x, d.y, d.z});
        }
        if (pixels && pending.get() < 3) {
            pending.incrementAndGet();
            Frames.grab(mc, img -> {
                pending.decrementAndGet();
                if (prev != null && recording) {
                    Frames.Diff diff = Frames.diff(prev, img, 8, null);
                    synchronized (tick) {
                        flow.add(new double[] {now, diff.count(), diff.sad()});
                    }
                }
                prev = img;
            });
        }
    }

    private static void arr(StringBuilder b, String name, List<double[]> rows) {
        b.append('"').append(name).append("\":[");
        boolean first = true;
        for (double[] r : rows) {
            if (!first) b.append(',');
            first = false;
            b.append('[');
            for (int i = 0; i < r.length; i++) {
                if (i > 0) b.append(',');
                b.append(String.format(Locale.ROOT, "%.4f", r[i]));
            }
            b.append(']');
        }
        b.append(']');
    }

    public static String json() {
        StringBuilder b = new StringBuilder("{");
        synchronized (tick) {
            arr(b, "tick", tick);
            b.append(',');
            arr(b, "frame", frame);
            b.append(',');
            arr(b, "flow", flow);
        }
        return b.append('}').toString();
    }
}
