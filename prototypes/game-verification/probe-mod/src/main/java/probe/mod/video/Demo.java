package probe.mod.video;

import java.util.Locale;
import java.util.Map;
import net.minecraft.client.Camera;
import net.minecraft.client.Minecraft;
import net.minecraft.client.gui.components.LerpingBossEvent;
import net.minecraft.client.gui.screens.ChatScreen;
import net.minecraft.util.Mth;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec3;
import probe.mod.mixin.HudAccessor;
import probe.mod.observe.mixin.BossAccessor;
import probe.mod.streammix.ChatScreenAccessor;

/**
 * Video prototype: a demo rerun under stepped ticks. The client draws fps / 20 frames per stepped tick at
 * evenly spaced partial tick positions. Frame f sits at game time f / fps seconds after the demo started:
 * it needs floor(f * 20 / fps) + 1 client ticks done and draws at partial (f * 20 mod fps) / fps. The client
 * clock (Util.timeSource) is set to exactly that game time, and the delta tracker is told the partial tick
 * (TimerMixin), so nothing is rounded to milliseconds. The step ack of a tick is held until the last frame of
 * that tick is drawn, so the server never runs ahead of the frames and the packets of the next tick never
 * reach a frame of this one.
 *
 *   demo?on=1&fps=30   start (needs n.mode on); demo?on=0 stop
 *   demo.watch?ids=    entities whose interpolated position goes into the per frame facts
 */
public final class Demo {
    public static volatile boolean on;
    static int fps = 30;
    static long baseNanos;
    /** Next frame to draw, and client ticks done since the demo started. */
    public static long frame, ticksDone;
    /** Set at the head of each loop for TimerMixin and the render gate. */
    public static int ticksNow;
    public static boolean frameNow, packetsOpen;
    public static float partial, deltaTicks;
    public static volatile int[] watch = new int[0];

    private Demo() {}

    public static long ticksFor(long f) {
        return f * 20 / fps + 1;
    }

    public static float partialFor(long f) {
        return (float) ((f * 20) % fps) / fps;
    }

    public static long nanosFor(long f) {
        return baseNanos + f * 1_000_000_000L / fps;
    }

    public static void start(int framesPerSecond, long virtNanos) {
        fps = framesPerSecond;
        baseNanos = virtNanos;
        frame = 0;
        ticksDone = 0;
        ticksNow = 0;
        frameNow = false;
        deltaTicks = 20f / fps;
        on = true;
    }

    /** End of a drawn demo frame. */
    public static void frameDone() {
        if (frameNow) {
            frameNow = false;
            frame++;
        }
    }

    /** Facts of the frame being drawn, as a JSON object, read on the render thread after the frame rendered. */
    public static String facts(Minecraft mc) {
        StringBuilder b = new StringBuilder(256);
        float pt = mc.getDeltaTracker().getGameTimeDeltaPartialTick(false);
        b.append("{\"df\":").append(on ? frame : -1).append(",\"pt\":").append(f4(pt));
        Camera cam = mc.gameRenderer.mainCamera();
        Vec3 c = cam.position();
        b.append(",\"cam\":[").append(f4(c.x)).append(',').append(f4(c.y)).append(',').append(f4(c.z)).append(',').append(f4(cam.yRot())).append(',').append(f4(cam.xRot())).append(']');
        if (mc.level != null) {
            b.append(",\"ents\":{");
            boolean first = true;
            for (int id : watch) {
                Entity e = mc.level.getEntity(id);
                if (e == null) continue;
                Vec3 p = e.getPosition(pt);
                if (!first) b.append(',');
                first = false;
                b.append('"').append(id).append("\":[").append(f4(p.x)).append(',').append(f4(p.y)).append(',').append(f4(p.z)).append(']');
            }
            b.append('}');
        }
        String pc = mc.particleEngine.countParticles();
        b.append(",\"particles\":").append(pc.substring(pc.lastIndexOf(' ') + 1).trim());
        HudAccessor hud = (HudAccessor) (Object) mc.gui.hud;
        int alpha = 0;
        if (hud.probe$title() != null && hud.probe$titleTime() > 0) {
            // Hud.extractTitle's formula.
            float t = hud.probe$titleTime() - pt;
            alpha = 255;
            if (hud.probe$titleTime() > hud.probe$fadeOut() + hud.probe$stay()) {
                float time = hud.probe$fadeIn() + hud.probe$stay() + hud.probe$fadeOut() - t;
                alpha = (int) (time * 255.0F / hud.probe$fadeIn());
            }
            if (hud.probe$titleTime() <= hud.probe$fadeOut()) alpha = (int) (t * 255.0F / hud.probe$fadeOut());
            alpha = Mth.clamp(alpha, 0, 255);
        }
        b.append(",\"titleAlpha\":").append(alpha);
        b.append(",\"boss\":[");
        boolean first = true;
        for (LerpingBossEvent e : ((BossAccessor) mc.gui.hud.getBossOverlay()).probe$events().values()) {
            if (!first) b.append(',');
            first = false;
            b.append(f4(e.getProgress()));
        }
        b.append(']');
        String input = mc.gui.screen() instanceof ChatScreen cs ? ((ChatScreenAccessor) cs).probe$input().getValue() : null;
        b.append(",\"input\":").append(input == null ? "null" : q(input));
        b.append(",\"slot0\":").append(q(mc.player == null ? "" : mc.player.getInventory().getItem(0).getItem().toString()));
        b.append('}');
        return b.toString();
    }

    public static String handle(String name, Map<String, String> p, Minecraft mc) {
        switch (name) {
            case "demo.watch" -> {
                String ids = p.getOrDefault("ids", "");
                watch = ids.isEmpty() ? new int[0] : java.util.Arrays.stream(ids.split(",")).mapToInt(Integer::parseInt).toArray();
                return "{\"ok\":true}";
            }
            case "demo.particles" -> {
                // The gated client runs with minimal particles; a clip should show what a player with default settings sees.
                net.minecraft.server.level.ParticleStatus st = net.minecraft.server.level.ParticleStatus.values()[Integer.parseInt(p.getOrDefault("level", "0"))];
                mc.execute(() -> mc.options.particles().set(st));
                return "{\"ok\":true,\"particles\":\"" + st + "\"}";
            }
            case "demo.clearParticles" -> {
                // Particles outlive their requirement (an end rod lives 60 to 72 ticks); a fact barrier never sees them.
                mc.execute(mc.particleEngine::clearParticles);
                return "{\"ok\":true}";
            }
            case "demo.stats" -> {
                return "{\"on\":" + on + ",\"frame\":" + frame + ",\"ticksDone\":" + ticksDone + ",\"fps\":" + fps + "}";
            }
            default -> {
                return null;
            }
        }
    }

    static String f4(double v) {
        return String.format(Locale.ROOT, "%.4f", v);
    }

    static String q(String s) {
        return '"' + s.replace("\\", "\\\\").replace("\"", "\\\"") + '"';
    }
}
