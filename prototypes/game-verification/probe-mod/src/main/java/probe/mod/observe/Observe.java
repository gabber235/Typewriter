package probe.mod.observe;

import java.nio.file.Path;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import net.minecraft.client.Minecraft;
import net.minecraft.client.PrioritizeChunkUpdates;
import net.minecraft.client.gui.screens.inventory.InventoryScreen;
import net.minecraft.core.BlockPos;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.player.ChatVisiblity;
import net.minecraft.world.level.block.Blocks;
import net.minecraft.world.level.block.state.BlockState;
import probe.mod.speed.Speed;

/** Spike A: requests for the four observers, one JSON reply each. Called from the live channel. */
public final class Observe {
    private Observe() {}

    private static <T> T get(CompletableFuture<T> f) throws Exception {
        return f.get(30, TimeUnit.SECONDS);
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
        return get(f);
    }

    private static void draw(int frames) throws Exception {
        if (frames <= 0) return;
        CompletableFuture<Void> f = new CompletableFuture<>();
        Speed.drawThen(frames, () -> f.complete(null));
        get(f);
    }

    /** Perceive frames: extract and submit without the GPU draw. */
    private static void perceive(int frames) throws Exception {
        if (frames <= 0) return;
        CompletableFuture<Void> f = new CompletableFuture<>();
        Speed.perceiveThen(frames, () -> f.complete(null));
        get(f);
    }

    private static void frames(Map<String, String> p) throws Exception {
        if ("1".equals(p.get("perceive"))) perceive(i(p, "frames", 1));
        else draw(i(p, "frames", 1));
    }

    private static BlockPos pos(Map<String, String> p) {
        return new BlockPos(Integer.parseInt(p.get("x")), Integer.parseInt(p.get("y")), Integer.parseInt(p.get("z")));
    }

    private static int[] rect(Map<String, String> p) {
        if (!p.containsKey("rect")) return null;
        String[] v = p.get("rect").split(",");
        return new int[] {Integer.parseInt(v[0]), Integer.parseInt(v[1]), Integer.parseInt(v[2]), Integer.parseInt(v[3])};
    }

    private static int i(Map<String, String> p, String k, int d) {
        return p.containsKey(k) ? Integer.parseInt(p.get(k)) : d;
    }

    private static String ms(long t0) {
        return String.format(java.util.Locale.ROOT, ",\"ms\":%.2f", (System.nanoTime() - t0) / 1e6);
    }

    /** Returns null when the name is not ours. */
    public static String handle(String name, Map<String, String> p, Minecraft mc) throws Exception {
        long t0 = System.nanoTime();
        return switch (name) {
            case "held" -> onClient(mc, () -> Held.json(mc));
            case "heldBlock" -> onClient(mc, () -> Held.block(mc, pos(p)));
            case "perceive" -> {
                perceive(i(p, "frames", 1));
                yield "{\"ok\":true" + ms(t0) + "}";
            }
            case "draw" -> {
                draw(i(p, "frames", 1));
                yield "{\"ok\":true" + ms(t0) + "}";
            }
            case "drawn" -> {
                frames(p);
                yield Drawn.frameJson();
            }
            case "drawnBlock" -> {
                frames(p);
                yield onClient(mc, () -> Drawn.blockJson(mc, pos(p)));
            }
            case "sounds" -> Drawn.soundsJson(Long.parseLong(p.getOrDefault("since", "0")));
            case "a2" -> {
                Drawn.on = "1".equals(p.get("on"));
                yield "{\"ok\":true}";
            }
            case "hooks" -> {
                long n = Drawn.hookNanos, f = Drawn.framesCounted;
                Drawn.hookNanos = 0;
                Drawn.framesCounted = 0;
                yield "{\"hookNanos\":" + n + ",\"frames\":" + f + "}";
            }
            case "pix.grab" -> {
                Frames.Img img = get(Frames.grabAfter(mc, i(p, "frames", 1)));
                Frames.put(p.get("slot"), img);
                yield "{\"ok\":true,\"w\":" + img.w() + ",\"h\":" + img.h() + ms(t0) + "}";
            }
            case "pix.stable" -> {
                int max = i(p, "maxMs", 2000), thr = i(p, "thr", 8), tries = 0, n = -1;
                Frames.Img prev = get(Frames.grabAfter(mc, 2));
                while ((System.nanoTime() - t0) / 1_000_000 < max) {
                    Frames.Img img = get(Frames.grabAfter(mc, i(p, "frames", 3)));
                    n = Frames.diff(prev, img, thr, null).count();
                    prev = img;
                    tries++;
                    if (n >= 0 && n < i(p, "under", 3)) break;
                }
                yield "{\"tries\":" + tries + ",\"last\":" + n + ms(t0) + "}";
            }
            case "clearToasts" -> {
                onClient(mc, () -> {
                    mc.gui.toastManager().clear();
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "pix.diff" -> {
                Frames.Img a = Frames.get(p.get("a")), b = Frames.get(p.get("b"));
                Frames.Diff d = Frames.diff(a, b, i(p, "thr", 8), rect(p));
                yield d.json(ms(t0));
            }
            case "pix.color" -> {
                Frames.Img a = Frames.get(p.get("slot"));
                String[] c = p.get("rgb").split(",");
                int n = Frames.colorCount(a, Integer.parseInt(c[0]), Integer.parseInt(c[1]), Integer.parseInt(c[2]), i(p, "tol", 12), rect(p));
                yield "{\"count\":" + n + ms(t0) + "}";
            }
            case "pix.png" -> {
                Frames.png(Frames.get(p.get("slot")), Path.of(p.get("path")));
                yield "{\"ok\":true" + ms(t0) + "}";
            }
            case "pix.mask" -> {
                Frames.maskPng(Frames.get(p.get("a")), Frames.get(p.get("b")), i(p, "thr", 8), Path.of(p.get("path")));
                yield "{\"ok\":true" + ms(t0) + "}";
            }
            case "vis" -> visible(mc, p, t0);
            case "hud" -> {
                boolean hidden = "1".equals(p.get("hidden"));
                onClient(mc, () -> {
                    if (mc.gui.hud.isHidden() != hidden) mc.gui.hud.toggle();
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "screen" -> {
                String which = p.get("which");
                onClient(mc, () -> {
                    mc.gui.setScreen("inventory".equals(which) ? new InventoryScreen(mc.player) : null);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "chatVis" -> {
                ChatVisiblity v = "hidden".equals(p.get("v")) ? ChatVisiblity.HIDDEN : ChatVisiblity.FULL;
                onClient(mc, () -> {
                    mc.options.chatVisibility().set(v);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "overdraw" -> {
                Drawn.overdraw = p.containsKey("box") ? parseBox(p.get("box")) : null;
                yield "{\"ok\":true}";
            }
            case "category" -> {
                SoundSource s = SoundSource.valueOf(p.get("src"));
                if (s == SoundSource.MASTER || s == SoundSource.MUSIC) throw new IllegalArgumentException("never touch master or music");
                double v = Double.parseDouble(p.get("v"));
                onClient(mc, () -> {
                    mc.options.getSoundSourceOptionInstance(s).set(v);
                    return 0;
                });
                yield "{\"ok\":true,\"master\":" + mc.options.getSoundSourceVolume(SoundSource.MASTER) + "}";
            }
            case "blur" -> {
                int v = i(p, "v", 5);
                onClient(mc, () -> {
                    mc.options.menuBackgroundBlurriness().set(v);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "prio" -> {
                onClient(mc, () -> {
                    mc.options.prioritizeChunkUpdates().set(PrioritizeChunkUpdates.PLAYER_AFFECTED);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "window" -> {
                int w = i(p, "w", 854), h = i(p, "h", 480);
                onClient(mc, () -> {
                    mc.getWindow().setWindowed(w, h);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "clearMeshes" -> {
                onClient(mc, () -> {
                    Drawn.clearMeshes();
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            case "ride.start" -> {
                Ride.start("1".equals(p.get("pix")));
                yield "{\"ok\":true}";
            }
            case "ride.stop" -> {
                Ride.stop();
                yield Ride.json();
            }
            case "camera" -> {
                onClient(mc, () -> {
                    mc.setCameraEntity(mc.player);
                    return 0;
                });
                yield "{\"ok\":true}";
            }
            default -> null;
        };
    }

    private static int[] parseBox(String s) {
        String[] v = s.split(",");
        return new int[] {Integer.parseInt(v[0]), Integer.parseInt(v[1]), Integer.parseInt(v[2]), Integer.parseInt(v[3]), (int) Long.parseLong(v[4], 16)};
    }

    /**
     * A4, differential visibility: the same frame with and without one thing. Occlusion, overdraw,
     * fading, culling and colour all come for free, because both frames are the real renderer.
     */
    private static String visible(Minecraft mc, Map<String, String> p, long t0) throws Exception {
        String kind = p.get("kind");
        int settle = i(p, "settle", 1);
        int thr = i(p, "thr", 8);
        boolean pin = i(p, "pin", 1) == 1 && !"block".equals(kind);
        Frames.Img with = null;
        long tickAtWith = -1;
        if (pin) {
            Drawn.pinned = Float.NaN;
            Drawn.pinning = true;
        }
        with = get(Frames.grabAfter(mc, settle));
        tickAtWith = with.tick();
        long t1 = System.nanoTime();
        BlockState[] old = new BlockState[1];
        BlockPos at = "block".equals(kind) ? pos(p) : null;
        int hideFrames;
        Drawn.hideHits = 0;
        switch (kind) {
            case "entity" -> {
                Drawn.hideEntity = Integer.parseInt(p.get("id"));
                hideFrames = 1;
            }
            case "text" -> {
                Drawn.hideText = p.get("needle");
                hideFrames = 1;
            }
            case "item" -> {
                Drawn.hideItem = p.get("id");
                hideFrames = 1;
            }
            case "block" -> {
                onClient(mc, () -> {
                    old[0] = mc.level.getBlockState(at);
                    mc.level.setBlock(at, Blocks.AIR.defaultBlockState(), 2 | 8);
                    return 0;
                });
                Drawn.hideHits = old[0].isAir() ? 0 : 1;
                hideFrames = i(p, "hideFrames", 4);
            }
            default -> throw new IllegalArgumentException(kind);
        }
        Frames.Img without;
        long hits;
        boolean tickCrossed;
        try {
            without = get(Frames.grabAfter(mc, hideFrames));
            hits = Drawn.hideHits;
            tickCrossed = without.tick() != tickAtWith;
        } finally {
            Drawn.pinning = false;
            Drawn.hideEntity = Integer.MIN_VALUE;
            Drawn.hideText = null;
            Drawn.hideItem = null;
            if (old[0] != null) {
                onClient(mc, () -> {
                    mc.level.setBlock(at, old[0], 2 | 8);
                    return 0;
                });
            }
        }
        long t2 = System.nanoTime();
        Frames.Diff d = Frames.diff(with, without, thr, rect(p));
        String extra = String.format(java.util.Locale.ROOT, ",\"hits\":%d,\"tickCrossed\":%b,\"grabMs\":%.2f,\"hideMs\":%.2f", hits, tickCrossed, (t1 - t0) / 1e6, (t2 - t1) / 1e6);
        if (p.containsKey("mask")) Frames.maskPng(with, without, thr, Path.of(p.get("mask")));
        if (p.containsKey("rgb")) {
            String[] c = p.get("rgb").split(",");
            extra += ",\"rgbHits\":" + Frames.maskColor(with, without, thr, Integer.parseInt(c[0]), Integer.parseInt(c[1]), Integer.parseInt(c[2]), i(p, "tol", 40));
        }
        if (i(p, "sub", 0) == 1) {
            Frames.Img after = get(Frames.grabAfter(mc, i(p, "restoreFrames", old[0] != null ? 4 : 1)));
            extra += ",\"noise\":" + Frames.diff(with, after, thr, rect(p)).count() + ",\"countSub\":" + Frames.diffExcept(with, without, after, thr, rect(p));
        } else if (old[0] != null) {
            draw(i(p, "restoreFrames", 4));
        }
        return d.json(extra + ms(t0));
    }
}
