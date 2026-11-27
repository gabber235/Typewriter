package com.typewritermc.playtest.client;

import com.mojang.blaze3d.platform.NativeImage;
import build.skir.internal.MustNameArguments;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;
import net.minecraft.client.Minecraft;
import net.minecraft.client.renderer.GameRenderer;
import skirout.harness.v1.wire.Answer;
import skirout.harness.v1.wire.ClientTask;
import skirout.harness.v1.wire.Message;
import skirout.harness.v1.wire.Reply;

/**
 * The frames a stepped client draws for real, and only these: for every watched entity a perceived
 * frame draws, the share of the frame it owns, a captured frame, and a clip's frames. For a share the client
 * draws once with every entity, then once without each watched entity the frame draws, and an entity
 * owns the pixels that show another colour without it. The perceive step's section compiles and
 * occlusion update run first, so every draw sees the same world. Render thread only.
 */
final class Looks {
    private static UUID hidden;
    private static ClientTask.Capture capture;
    private static long captureRequest;

    private Looks() {}

    /** The next frame that runs is written as {@code asked} says, then answered as request {@code request}. */
    static void capture(long request, ClientTask.Capture asked) {
        captureRequest = request;
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
        boolean clip = Clips.drawsFrame();
        // A capture takes the tick's end, as the gated run draws it; a clip's passes before it leave it waiting.
        boolean captures = capture != null && Clips.partial() >= 1f;
        if (!captures && !clip && drawn.isEmpty()) return;
        var copies = new ArrayList<Grab.Copy>(drawn.size() + 1);
        copies.add(drawWithout(mc, renderer, null));
        for (UUID entity : drawn) copies.add(drawWithout(mc, renderer, entity));
        List<Pixels> frames = Grab.read(copies);
        if (captures) answerCapture(frames.getFirst());
        if (clip) Clips.add(frames.getFirst());
        for (int index = 0; index < drawn.size(); index++) {
            Perceiver.owns(drawn.get(index), frames.getFirst().differingShare(frames.get(index + 1)));
        }
    }

    /** After a frame drawn as any client draws, before the client steps: a capture takes that frame. */
    static void drawn(GameRenderer renderer) {
        if (capture != null) answerCapture(Grab.read(List.of(Grab.copy(renderer.mainRenderTarget()))).getFirst());
    }

    /** Writes {@code frame} as the capture asked and answers it. */
    private static void answerCapture(Pixels frame) {
        ClientTask.Capture asked = capture;
        capture = null;
        var answer = Answer.Companion.createCaptured(MustNameArguments.INSTANCE, writePng(frame, Path.of(asked.getPath())));
        PlaytestClient.send(new Message.ReplyWrapper(new Reply(MustNameArguments.INSTANCE, captureRequest, answer, null)));
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
