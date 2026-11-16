package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.ClipStarted;
import com.typewritermc.playtest.wire.Message.ClipWritten;
import com.typewritermc.playtest.wire.Message.StartClip;
import com.typewritermc.playtest.wire.Message.StopClip;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.nio.ByteOrder;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.ArrayDeque;
import java.util.List;

/**
 * The clip a demo records. While it records, every tick is followed by the passes its {@link ClipSchedule}
 * names: each perceives and sends its own record, a pass on a clip frame draws that frame for real
 * and hands its pixels to ffmpeg, and the tick's record and its ack wait for the last pass, at the
 * tick's end, as they would without a clip. The packets that arrive meanwhile stay queued, so every
 * pass of a tick shows that tick. Render thread only.
 */
final class Clips {
    private static final ArrayDeque<ClipSchedule.Pass> due = new ArrayDeque<>();
    private static ClipSchedule schedule;
    private static Path path;
    private static Process encoder;
    private static ClipWriter writer;
    private static int width;
    private static int height;
    private static String failure;

    private Clips() {}

    /** Records from the next tick on, as {@code asked} says, and answers it. */
    static void start(StartClip asked) {
        stopEncoder();
        schedule = new ClipSchedule();
        path = Path.of(asked.path());
        failure = null;
        due.clear();
        PlaytestClient.send(new ClipStarted(asked.request(), null));
    }

    /** Finishes the clip and answers {@code asked} with what it holds. */
    static void stop(StopClip asked) {
        int frames = 0;
        String failed = schedule == null ? "no clip was recording" : failure;
        if (writer != null) {
            try {
                frames = writer.finish();
            } catch (IOException broken) {
                failed = failed != null ? failed : broken.getMessage() + "; see " + log();
            }
        } else if (failed == null) {
            failed = "the clip holds no frame: no tick ran while it recorded";
        }
        writer = null;
        encoder = null;
        schedule = null;
        due.clear();
        PlaytestClient.send(new ClipWritten(asked.request(), frames, failed));
    }

    /** A new attempt or a lost Paper: a clip still recording is dropped. */
    static void reset() {
        stopEncoder();
        schedule = null;
        due.clear();
    }

    /** The client left its Paper: the passes of its last tick are gone with it, and the clip goes on with the next Paper's ticks. */
    static void leftPaper() {
        due.clear();
    }

    /** Tail of a tick that ran: its passes are due. */
    static void ticked() {
        if (schedule != null) due.addAll(schedule.ticked());
    }

    /** Whether the frame that runs now is one of the passes after a tick but not its last. */
    static boolean morePassesDue() {
        return due.size() > 1;
    }

    /** How far from the tick before to the last tick the frame that runs now draws: 1 at the tick's end. */
    static float partial() {
        ClipSchedule.Pass pass = due.peek();
        return pass == null ? 1f : pass.partial();
    }

    /** The clip frame the pass that runs now draws, or -1. */
    static int frame() {
        ClipSchedule.Pass pass = due.peek();
        return pass == null ? -1 : pass.frame();
    }

    /** Whether the pass that runs now draws a clip frame. */
    static boolean drawsFrame() {
        return frame() >= 0;
    }

    /** Whether the pass that runs now sends its record whatever it shows: each pass of a clip has its own. */
    static boolean recordsEveryPass() {
        return !due.isEmpty();
    }

    /** After a pass: the next one, if any, runs in the next frame. */
    static void passed() {
        due.poll();
    }

    /** The pass draws {@code frame}, its pixels from the bottom row up, as the clip's next frame. */
    static void add(Pixels frame) {
        if (failure != null) return;
        if (writer == null && !startEncoder(frame.width(), frame.height())) return;
        if (frame.width() != width || frame.height() != height) {
            failure = "the window changed from " + width + "x" + height + " to " + frame.width() + "x" + frame.height() + " while the clip recorded";
            return;
        }
        var bytes = ByteBuffer.allocate(frame.rgba().length * 4).order(ByteOrder.LITTLE_ENDIAN);
        bytes.asIntBuffer().put(frame.rgba());
        writer.add(bytes.array());
    }

    /** Starts ffmpeg for frames of this size; returns whether it runs. */
    private static boolean startEncoder(int frameWidth, int frameHeight) {
        width = frameWidth;
        height = frameHeight;
        try {
            Files.createDirectories(path.getParent());
            encoder = new ProcessBuilder(List.of(
                            "ffmpeg", "-nostdin", "-loglevel", "error", "-y",
                            "-f", "rawvideo", "-pixel_format", "rgba", "-video_size", width + "x" + height, "-framerate", "30", "-i", "-",
                            // The GPU hands rows over from the bottom; H.264 in yuv420p needs an even size.
                            "-vf", "vflip,scale=trunc(iw/2)*2:trunc(ih/2)*2",
                            "-c:v", "libx264", "-preset", "veryfast", "-pix_fmt", "yuv420p", "-movflags", "+faststart",
                            path.toString()))
                    .redirectOutput(ProcessBuilder.Redirect.DISCARD)
                    .redirectError(log().toFile())
                    .start();
        } catch (IOException unstartable) {
            failure = "ffmpeg did not start: " + unstartable.getMessage();
            return false;
        }
        Process started = encoder;
        writer = new ClipWriter(started.getOutputStream(), () -> {
            try {
                return started.waitFor();
            } catch (InterruptedException interrupted) {
                Thread.currentThread().interrupt();
                return -1;
            }
        });
        return true;
    }

    private static void stopEncoder() {
        if (encoder != null) encoder.destroyForcibly();
        encoder = null;
        writer = null;
    }

    /** ffmpeg's log beside the clip. */
    private static Path log() {
        return path.resolveSibling(path.getFileName() + ".log");
    }
}
