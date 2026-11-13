package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Ready;
import java.util.ArrayDeque;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.minecraft.client.Minecraft;
import net.minecraft.util.Util;

/**
 * The client's clock in step with Paper. Paper sends a step ping at the end of every stepped tick; from
 * the first one on, the client's clock stands still and moves exactly one tick for each step ping, so
 * the client runs one tick per server tick. After the tick's frame is perceived the client acks the
 * tick, and Paper runs the next one. Render thread only, except {@link #wake()}.
 */
final class Stepper {
    /** Step pings carry the server tick plus this; smaller ids are barriers. */
    static final int STEP_BASE = 1 << 30;

    private static final long TICK_NANOS = 50_000_000L;
    private static final long PARK_NANOS = TimeUnit.MILLISECONDS.toNanos(2);

    private static final ArrayDeque<Integer> granted = new ArrayDeque<>();
    private static volatile Thread renderThread;
    private static volatile long virtualNanos;
    private static boolean stepping;
    private static Integer running;
    private static int lastPinged = -1;
    private static int lastRan = -1;
    private static boolean perceiveDue;

    private Stepper() {}

    static boolean stepping() {
        return stepping;
    }

    /**
     * The server tick something arriving now belongs to: it arrived after the last step ping, so after
     * that tick ended, and shows from the next tick on.
     */
    static int arrivalTick() {
        return lastPinged + 1;
    }

    /**
     * The server tick a change made now belongs to: the tick running, or, between ticks, the tick
     * something arriving now shows in.
     */
    static int currentTick() {
        return running != null ? running : arrivalTick();
    }

    /** The last server tick this client ran. */
    static int lastRan() {
        return lastRan;
    }

    /**
     * A step ping arrived, inside the client's packet handling and so between frames. The clock switches
     * to stepping here, on the render thread before the frame reads it: switched from another thread, a
     * frame in flight could read the real clock after the switch and lose part of the first step.
     */
    static void onStepPing(int tick) {
        if (!stepping) {
            virtualNanos = Util.getNanos();
            Util.setTimeSource(() -> virtualNanos);
            stepping = true;
            // Packets handled after this one arrive after a step ping, so they belong to a tick.
            PlaytestClient.send(new Ready());
        }
        lastPinged = tick;
        granted.add(tick);
    }

    /** Another thread queued work for the render thread; it should not wait out its park. */
    static void wake() {
        Thread thread = renderThread;
        if (thread != null) LockSupport.unpark(thread);
    }

    /** Head of {@code Minecraft.runTick}, before it reads the clock. */
    static void beforeRunTick(Minecraft mc) {
        renderThread = Thread.currentThread();
        if (!stepping) return;
        mc.packetProcessor().processQueuedPackets();
        if (running != null) return;
        if (granted.isEmpty() && !Perceiver.forced()) {
            LockSupport.parkNanos(PARK_NANOS);
            mc.packetProcessor().processQueuedPackets();
        }
        Integer next = granted.poll();
        if (next != null) {
            running = next;
            virtualNanos += TICK_NANOS;
        } else {
            // No tick runs in this pass, so this is a point between ticks where input may start.
            Inputs.betweenTicks(mc, false);
        }
    }

    /** Tail of {@code Minecraft.tick}. */
    static void afterTick(Minecraft mc) {
        if (running == null) return;
        lastRan = running;
        running = null;
        perceiveDue = true;
        Inputs.betweenTicks(mc, true);
    }

    /** Whether this frame runs at all: while stepping, only to perceive a tick that ran or a forced record. */
    static boolean perceiveFrame() {
        return perceiveDue || Perceiver.forced();
    }

    /** After a perceived frame: the tick it showed is acked, so Paper may run the next. */
    static void perceived() {
        if (!perceiveDue) return;
        perceiveDue = false;
        ClientPlayNetworking.send(new StepAck(lastRan, Inputs.busy()));
    }

    /**
     * An input that needs ticks started while no ack is due, so Paper, idle until now, hears at once
     * that this client needs it to step.
     */
    static void needTicks() {
        if (stepping && !perceiveDue) ClientPlayNetworking.send(new StepAck(lastRan, true));
    }
}
