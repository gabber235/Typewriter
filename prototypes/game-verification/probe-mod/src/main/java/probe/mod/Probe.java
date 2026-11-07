package probe.mod;

import com.mojang.blaze3d.systems.RenderSystem;
import com.mojang.renderpearl.api.device.DeviceInfo;
import java.io.BufferedWriter;
import java.io.IOException;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.List;
import java.util.Locale;
import net.fabricmc.api.ClientModInitializer;
import net.minecraft.client.Camera;
import net.minecraft.client.Minecraft;
import net.minecraft.client.Screenshot;
import net.minecraft.client.multiplayer.chat.GuiMessage;
import net.minecraft.client.gui.screens.Screen;
import net.minecraft.core.BlockPos;
import net.minecraft.core.registries.BuiltInRegistries;
import net.minecraft.network.chat.Component;
import net.minecraft.sounds.SoundSource;
import net.minecraft.world.entity.Display;
import net.minecraft.world.entity.Entity;
import net.minecraft.world.phys.Vec3;
import probe.mod.mixin.ChatAccessor;
import probe.mod.mixin.HudAccessor;
import probe.mod.speed.Speed;

/**
 * Throwaway fact recorder. Writes JSON lines to -Dprobe.facts:
 *   k=e  event (startup, renderer, screen changes, first world frame)
 *   k=t  fact at the end of each client tick
 *   k=f  fact at the end of each rendered frame (all frames, or only on perceived change when
 *        -Dprobe.factsMode=changes)
 * Times are epoch microseconds, comparable with the plugin's sentMicros.
 */
public final class Probe implements ClientModInitializer {
    private static BufferedWriter out;
    private static final List<BlockPos> WATCHED = new ArrayList<>();
    private static boolean frameFactsAll = true;
    private static long ticks;
    private static long frames;
    private static boolean renderer;
    private static String lastScreen = "";
    private static String lastPerceived = "";
    private static boolean overlayGone;
    private static boolean levelSeen;
    private static boolean sectionsSeen;
    private static boolean feetCompiled;
    private static Path stopFile;
    private static boolean lastFocused = true;

    @Override
    public void onInitializeClient() {
        String path = System.getProperty("probe.facts");
        if (path == null) return;
        try {
            Files.createDirectories(Path.of(path).toAbsolutePath().getParent());
            out = Files.newBufferedWriter(Path.of(path), StandardCharsets.UTF_8);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        frameFactsAll = !"changes".equals(System.getProperty("probe.factsMode"));
        String watch = System.getProperty("probe.watchBlocks", "");
        for (String p : watch.split(";")) {
            if (p.isBlank()) continue;
            String[] c = p.split(",");
            WATCHED.add(new BlockPos(Integer.parseInt(c[0]), Integer.parseInt(c[1]), Integer.parseInt(c[2])));
        }
        String stop = System.getProperty("probe.stopFile");
        stopFile = stop == null ? null : Path.of(stop);
        long max = Long.getLong("probe.maxRuntimeSec", 600);
        Thread dog = new Thread(() -> {
            try {
                Thread.sleep(max * 1000);
            } catch (InterruptedException e) {
                return;
            }
            System.err.println("probe watchdog: halting client after " + max + " s");
            Runtime.getRuntime().halt(99);
        }, "probe-watchdog");
        dog.setDaemon(true);
        dog.start();
        Speed.init();
        probe.mod.input.Input.init();
        probe.mod.n.N.init();
        event("mod_init", "\"jvmStartMicros\":" + java.lang.management.ManagementFactory.getRuntimeMXBean().getStartTime() * 1000);
    }

    public static long frames() {
        return frames;
    }

    public static long ticks() {
        return ticks;
    }

    public static void onTick(Minecraft mc) {
        if (out == null) return;
        ticks++;
        String tp = perceived(mc);
        if (frameFactsAll || !tp.equals(lastPerceived)) {
            write(fact(mc, "t", tp));
            lastPerceived = tp;
        }
        // A tick's state is first drawn by the next frame, so a sighting names that frame (spike B).
        Speed.publish(frames + 1, ticks, tp);
        probe.mod.observe.Ride.onTick(mc);
        try {
            out.flush();
        } catch (IOException ignored) {
        }
        if (stopFile != null && ticks % 5 == 0 && Files.exists(stopFile)) {
            event("stop_requested", "");
            mc.stop();
        }
        maybeScreenshot(mc);
    }

    public static void onFrame(Minecraft mc) {
        if (out == null) return;
        frames++;
        if (!renderer) {
            renderer = true;
            DeviceInfo d = RenderSystem.getDevice().getDeviceInfo();
            event("renderer", "\"gpu\":" + q(d.name()) + ",\"vendor\":" + q(d.vendorName()) + ",\"driver\":" + q(d.driverInfo())
                + ",\"backend\":" + q(d.backendName()) + ",\"fbWidth\":" + mc.getWindow().getWidth() + ",\"fbHeight\":" + mc.getWindow().getHeight()
                + ",\"screenWidth\":" + mc.getWindow().getScreenWidth() + ",\"screenHeight\":" + mc.getWindow().getScreenHeight()
                + ",\"master\":" + mc.options.getSoundSourceVolume(SoundSource.MASTER) + ",\"music\":" + mc.options.getSoundSourceVolume(SoundSource.MUSIC)
                + ",\"renderDistance\":" + mc.options.renderDistance().get() + ",\"focused\":" + mc.getWindow().isFocused());
        }
        lifecycle(mc);
        feetSection(mc);
        String p = perceived(mc);
        if (frameFactsAll || !p.equals(lastPerceived)) {
            write(fact(mc, "f", p));
            lastPerceived = p;
        }
        if (frames % 20 == 0) {
            try {
                out.flush();
            } catch (IOException ignored) {
            }
        }
        Speed.afterFrame(mc, frames, ticks, p);
    }

    /** Writing a target path into <gameDir>/probe.shot grabs mainRenderTarget (world and GUI) as PNG. */
    private static void maybeScreenshot(Minecraft mc) {
        Path request = mc.gameDirectory.toPath().resolve("probe.shot");
        if (!Files.exists(request)) return;
        try {
            Path target = Path.of(Files.readString(request).trim());
            Files.delete(request);
            Screenshot.takeScreenshot(mc.gameRenderer.mainRenderTarget(), image -> {
                try (image) {
                    image.writeToFile(target);
                    event("screenshot", "\"path\":" + q(target.toString()));
                } catch (IOException e) {
                    event("screenshot_failed", "\"error\":" + q(e.toString()));
                }
            });
        } catch (IOException e) {
            event("screenshot_failed", "\"error\":" + q(e.toString()));
        }
    }

    private static void lifecycle(Minecraft mc) {
        if (mc.getWindow().isFocused() != lastFocused) {
            lastFocused = !lastFocused;
            event("focus", "\"focused\":" + lastFocused);
        }
        Screen screen = mc.gui.screen();
        String name = screen == null ? "none" : screen.getClass().getSimpleName();
        if (!name.equals(lastScreen)) {
            event("screen", "\"screen\":" + q(name));
            lastScreen = name;
        }
        if (!overlayGone && mc.gui.overlay() == null && mc.isGameLoadFinished()) {
            overlayGone = true;
            event("load_finished", "\"screen\":" + q(name));
        }
        if (!levelSeen && mc.level != null && mc.player != null) {
            levelSeen = true;
            event("level_ready", "");
        }
        if (levelSeen && !sectionsSeen && screen == null
            && mc.level.getChunkSource().getLoadedChunksCount() > 0
            && !mc.levelRenderer.visibleSections().isEmpty()) {
            sectionsSeen = true;
            event("all_sections_at_first_world_frame", "\"queueEmpty\":" + mc.levelRenderer.hasRenderedAllSections());
            event("first_world_frame", "\"visibleSections\":" + mc.levelRenderer.visibleSections().size()
                + ",\"loadedChunks\":" + mc.level.getChunkSource().getLoadedChunksCount());
        }
    }

    private static void feetSection(Minecraft mc) {
        if (!feetCompiled && mc.player != null && mc.levelRenderer.isSectionCompiledAndVisible(mc.player.blockPosition().below(), 0)) {
            feetCompiled = true;
            event("feet_section_compiled", "\"visibleSections\":" + mc.levelRenderer.visibleSections().size() + ",\"queueEmpty\":" + mc.levelRenderer.hasRenderedAllSections());
        }
    }

    /** Everything a change-only frame fact compares on. */
    private static String perceived(Minecraft mc) {
        StringBuilder b = new StringBuilder(256);
        HudAccessor hud = (HudAccessor) mc.gui.hud;
        b.append("\"title\":").append(text(hud.probe$title()));
        b.append(",\"sub\":").append(text(hud.probe$subtitle()));
        b.append(",\"titleTime\":").append(hud.probe$titleTime());
        b.append(",\"fade\":[").append(hud.probe$fadeIn()).append(',').append(hud.probe$stay()).append(',').append(hud.probe$fadeOut()).append(']');
        b.append(",\"bar\":").append(text(hud.probe$bar()));
        b.append(",\"barTime\":").append(hud.probe$barTime());
        b.append(",\"chat\":[");
        List<GuiMessage> all = ((ChatAccessor) mc.gui.hud.getChat()).probe$allMessages();
        for (int i = 0; i < Math.min(5, all.size()); i++) {
            if (i > 0) b.append(',');
            b.append(q(all.get(i).content().getString()));
        }
        b.append(']');
        b.append(",\"blocks\":{");
        boolean first = true;
        if (mc.level != null) {
            for (BlockPos pos : WATCHED) {
                if (!first) b.append(',');
                first = false;
                b.append('"').append(pos.getX()).append(',').append(pos.getY()).append(',').append(pos.getZ()).append("\":")
                    .append(q(BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(pos).getBlock()).toString()));
            }
        }
        b.append('}');
        b.append(",\"entities\":[");
        first = true;
        if (mc.level != null) {
            for (Entity e : mc.level.entitiesForRendering()) {
                if (!first) b.append(',');
                first = false;
                b.append("{\"id\":").append(e.getId());
                b.append(",\"type\":").append(q(BuiltInRegistries.ENTITY_TYPE.getKey(e.getType()).toString()));
                b.append(",\"name\":").append(text(e.getCustomName()));
                if (e != mc.player) {
                    Vec3 lerped = e.getPosition(mc.getDeltaTracker().getGameTimeDeltaPartialTick(false));
                    b.append(String.format(Locale.ROOT, ",\"x\":%.3f,\"rx\":%.3f", e.getX(), lerped.x));
                }
                if (e instanceof Display.TextDisplay d) b.append(",\"text\":").append(text(d.getText()));
                b.append('}');
            }
        }
        b.append(']');
        b.append(",\"ping\":").append(Speed.lastPing);
        Screen sc = mc.gui.screen();
        b.append(",\"screen\":").append(q(sc == null ? "none" : sc.getClass().getSimpleName()));
        b.append(",\"chatCount\":").append(all.size());
        if (mc.level != null && mc.player != null) {
            BlockPos feet = mc.player.blockPosition();
            b.append(",\"relBlock\":").append(q(BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(feet.offset(2, 0, 2)).getBlock()).toString()));
            b.append(",\"under\":").append(q(BuiltInRegistries.BLOCK.getKey(mc.level.getBlockState(feet.below()).getBlock()).toString()));
            Vec3 v = mc.player.getDeltaMovement();
            b.append(String.format(Locale.ROOT, ",\"vel\":[%.3f,%.3f,%.3f]", v.x, v.y, v.z));
            b.append(String.format(Locale.ROOT, ",\"pos\":[%.2f,%.2f,%.2f]", mc.player.getX(), mc.player.getY(), mc.player.getZ()));
            b.append(",\"loaded\":").append(mc.level.getChunkSource().getLoadedChunksCount());
            b.append(",\"effects\":").append(mc.player.getActiveEffects().size());
            int inv = 0;
            for (int i = 0; i < mc.player.getInventory().getContainerSize(); i++) if (!mc.player.getInventory().getItem(i).isEmpty()) inv++;
            b.append(",\"inv\":").append(inv);
            b.append(",\"fire\":").append(mc.player.isOnFire());
            b.append(",\"dim\":").append(q(mc.level.dimension().identifier().toString()));
            Speed.ready(mc, b);
        }
        return b.toString();
    }

    private static String fact(Minecraft mc, String kind, String perceived) {
        StringBuilder b = new StringBuilder(perceived.length() + 200);
        b.append("{\"k\":\"").append(kind).append("\",\"at\":").append(micros());
        b.append(",\"tick\":").append(ticks).append(",\"frame\":").append(frames).append(",\"fps\":").append(mc.getFps());
        b.append(",\"gameTime\":").append(mc.level == null ? -1 : mc.level.getGameTime());
        Camera cam = mc.gameRenderer.mainCamera();
        Vec3 pos = cam.position();
        b.append(String.format(Locale.ROOT, ",\"cam\":[%.3f,%.3f,%.3f,%.2f,%.2f]", pos.x, pos.y, pos.z, cam.yRot(), cam.xRot()));
        if (mc.level != null) {
            b.append(",\"chunks\":{\"loaded\":").append(mc.level.getChunkSource().getLoadedChunksCount());
            b.append(",\"visibleSections\":").append(mc.levelRenderer.visibleSections().size());
            b.append(",\"queueEmpty\":").append(mc.levelRenderer.hasRenderedAllSections()).append('}');
        }
        b.append(",").append(perceived).append('}');
        return b.toString();
    }

    private static void event(String name, String fields) {
        write("{\"k\":\"e\",\"at\":" + micros() + ",\"name\":" + q(name) + (fields.isEmpty() ? "" : "," + fields) + "}");
        try {
            out.flush();
        } catch (IOException ignored) {
        }
    }

    private static void write(String line) {
        try {
            out.write(line);
            out.write('\n');
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    private static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    private static String text(Component c) {
        return c == null ? "null" : q(c.getString());
    }

    private static String q(String s) {
        StringBuilder b = new StringBuilder(s.length() + 2).append('"');
        for (int i = 0; i < s.length(); i++) {
            char c = s.charAt(i);
            switch (c) {
                case '"' -> b.append("\\\"");
                case '\\' -> b.append("\\\\");
                case '\n' -> b.append("\\n");
                case '\r' -> b.append("\\r");
                case '\t' -> b.append("\\t");
                default -> {
                    if (c < 0x20) b.append(String.format("\\u%04x", (int) c));
                    else b.append(c);
                }
            }
        }
        return b.append('"').toString();
    }
}
