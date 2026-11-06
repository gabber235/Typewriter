package probe.mod.golden;

import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.texture.AbstractTexture;
import net.minecraft.client.renderer.texture.SpriteContents;
import net.minecraft.client.renderer.texture.TextureAtlas;
import probe.mod.golden.mixin.AnimationStateAccessor;
import probe.mod.golden.mixin.TextureAtlasAccessor;
import probe.mod.golden.mixin.TextureManagerAccessor;
import probe.mod.observe.Drawn;
import probe.mod.observe.Frames;

/**
 * Spike F: knobs that take time out of a frame, and raw frame dumps for golden comparison.
 * Each knob is independent so the orchestrator can measure what each one is worth.
 */
public final class Golden {
    /** Light flicker pinned to zero: the lightmap otherwise takes a random walk every client tick. */
    public static volatile boolean flicker;
    /** Deliberate break: the title drawn this many GUI units lower (0.5 is one framebuffer pixel at scale 2). */
    public static volatile float titleDy;

    private Golden() {}

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

    /** Every animated sprite back to its first frame, uploaded now. Same phase whatever ran before. */
    public static int animationsToStart(Minecraft mc) {
        int n = 0;
        for (AbstractTexture t : ((TextureManagerAccessor) mc.getTextureManager()).probe$byPath().values()) {
            if (!(t instanceof TextureAtlas atlas)) continue;
            for (SpriteContents.AnimationState s : ((TextureAtlasAccessor) atlas).probe$states()) {
                AnimationStateAccessor a = (AnimationStateAccessor) (Object) s;
                a.probe$setFrame(0);
                a.probe$setSubFrame(0);
                a.probe$setDirty(true);
                n++;
            }
            ((TextureAtlasAccessor) atlas).probe$upload();
        }
        return n;
    }

    private static boolean on(Map<String, String> p, String k) {
        return "1".equals(p.get(k));
    }

    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        return switch (name) {
            case "g.knobs" -> onClient(mc, () -> {
                StringBuilder r = new StringBuilder("{\"ok\":true");
                if (p.containsKey("freeze")) mc.level.tickRateManager().setFrozen(on(p, "freeze"));
                if (on(p, "anim0")) r.append(",\"sprites\":").append(animationsToStart(mc));
                if (p.containsKey("flicker")) flicker = on(p, "flicker");
                if (p.containsKey("pin")) {
                    Drawn.pinned = Float.parseFloat(p.get("pin"));
                    Drawn.pinning = !Float.isNaN(Drawn.pinned);
                }
                if (p.containsKey("bob")) mc.options.bobView().set(on(p, "bob"));
                if (p.containsKey("vignette")) mc.options.vignette().set(on(p, "vignette"));
                if (p.containsKey("glint")) mc.options.glintSpeed().set(Double.parseDouble(p.get("glint")));
                if (on(p, "hud")) {
                    mc.gui.hud.getChat().clearMessages(false);
                    mc.gui.toastManager().clear();
                }
                if (p.containsKey("titleDy")) titleDy = Float.parseFloat(p.get("titleDy"));
                r.append(",\"frozen\":").append(mc.level.tickRateManager().isFrozen());
                r.append(",\"tick\":").append(Drawn.ticks).append("}");
                return r.toString();
            });
            case "g.grab" -> {
                long t0 = System.nanoTime();
                Frames.Img img = Frames.grabAfter(mc, Integer.parseInt(p.getOrDefault("frames", "1"))).get(30, TimeUnit.SECONDS);
                long t1 = System.nanoTime();
                Frames.put(p.getOrDefault("slot", "g"), img);
                String extra = "";
                if (p.containsKey("path")) {
                    ByteBuffer b = ByteBuffer.allocate(img.px().length * 4).order(ByteOrder.LITTLE_ENDIAN);
                    b.asIntBuffer().put(img.px());
                    Path out = Path.of(p.get("path"));
                    Files.createDirectories(out.toAbsolutePath().getParent());
                    try (OutputStream o = Files.newOutputStream(out)) {
                        o.write(b.array());
                    }
                    extra = String.format(java.util.Locale.ROOT, ",\"writeMs\":%.2f", (System.nanoTime() - t1) / 1e6);
                }
                yield String.format(java.util.Locale.ROOT, "{\"w\":%d,\"h\":%d,\"tick\":%d,\"grabMs\":%.2f%s}", img.w(), img.h(), img.tick(), (t1 - t0) / 1e6, extra);
            }
            case "g.same" -> {
                Frames.Img a = Frames.get(p.get("a")), b = Frames.get(p.get("b"));
                yield Frames.diff(a, b, Integer.parseInt(p.getOrDefault("thr", "0")), null).json("");
            }
            default -> null;
        };
    }
}
