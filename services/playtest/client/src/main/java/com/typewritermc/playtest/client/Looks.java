package com.typewritermc.playtest.client;

import com.mojang.blaze3d.platform.NativeImage;
import com.mojang.blaze3d.systems.RenderSystem;
import com.typewritermc.playtest.wire.Message.Capture;
import com.typewritermc.playtest.wire.Message.Captured;
import com.typewritermc.playtest.wire.Message.Renderer;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;

/**
 * The frames a stepped client draws for real, and only these: for every watched entity a perceived
 * frame draws, the share of the frame it owns, and the frame a golden asks for. For a share the client
 * draws once with every entity, then once without each watched entity the frame draws, and an entity
 * owns the pixels that show another colour without it. The perceive step's section compiles and
 * occlusion update run first, so every draw sees the same world. Render thread only.
 */
final class Looks {
    private static UUID hidden;
    private static Capture capture;

    private Looks() {}

    /** The next frame that runs is written as {@code asked} says, then answered. */
    static void capture(Capture asked) {
        capture = asked;
    }

    /** A new attempt: no capture waits any more. */
    static void reset() {
        hidden = null;
        capture = null;
    }

    /** Whether the frame extracting now leaves {@code entity} out, to draw the frame without it. */
    static boolean hides(UUID entity) {
        return entity.equals(hidden);
    }

    /**
     * The perceive step of a frame whose extract ran: perceives as {@link NoDraw} does, and when the
     * frame draws a watched entity, draws it for real and counts pixels. The world's submits consume
     * what the extract handed them, so each drawn frame extracts afresh, muted: once with every entity,
     * then once without each watched entity the frame draws.
     */
    static void perceive(Minecraft mc, GameRenderer renderer) {
        List<UUID> drawn = Perceiver.drawn();
        NoDraw.render(mc);
        if (capture != null) answerCapture(drawWithout(mc, renderer, null));
        if (drawn.isEmpty()) return;
        var copies = new ArrayList<Grab.Copy>(drawn.size() + 1);
        copies.add(drawWithout(mc, renderer, null));
        for (UUID entity : drawn) copies.add(drawWithout(mc, renderer, entity));
        List<Pixels> frames = Grab.read(copies);
        for (int index = 0; index < drawn.size(); index++) {
            Perceiver.owns(drawn.get(index), frames.getFirst().differingShare(frames.get(index + 1)));
        }
    }

    /** After a frame drawn as any client draws, before the client steps: a capture takes that frame. */
    static void drawn(GameRenderer renderer) {
        if (capture != null) answerCapture(Grab.copy(renderer.mainRenderTarget()));
    }

    /** Writes the frame {@code copy} holds as the capture asked and answers it. */
    private static void answerCapture(Grab.Copy copy) {
        Capture asked = capture;
        capture = null;
        Pixels frame = Grab.read(List.of(copy)).getFirst();
        var info = RenderSystem.getDevice().getDeviceInfo();
        var renderer = new Renderer(
                info.backendName(), info.name(), info.driverInfo(), System.getProperty("os.name"), System.getProperty("os.arch"));
        PlaytestClient.send(new Captured(asked.request(), renderer, writePng(frame, Path.of(asked.path()))));
    }

    /**
     * Writes {@code frame} as an opaque PNG to {@code path}, top row first: the GPU hands rows over from
     * the bottom. Returns why it could not, or null.
     */
    private static String writePng(Pixels frame, Path path) {
        try (var image = new NativeImage(frame.width(), frame.height(), false)) {
            for (int y = 0; y < frame.height(); y++) {
                for (int x = 0; x < frame.width(); x++) {
                    image.setPixelABGR(x, frame.height() - 1 - y, frame.rgba()[x + y * frame.width()] | 0xFF000000);
                }
            }
            Files.createDirectories(path.getParent());
            image.writeToFile(path);
            return null;
        } catch (IOException failed) {
            return "could not write the frame to " + path + ": " + failed.getMessage();
        }
    }

    /** Extracts and draws the frame again, leaving {@code entity} out unless it is null, and queues a copy of it. */
    private static Grab.Copy drawWithout(Minecraft mc, GameRenderer renderer, UUID entity) {
        hidden = entity;
        Perceiver.mute(true);
        try {
            renderer.extract(mc.getDeltaTracker(), true);
            renderer.render();
        } finally {
            Perceiver.mute(false);
            hidden = null;
        }
        return Grab.copy(renderer.mainRenderTarget());
    }
}
