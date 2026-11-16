package com.typewritermc.playtest.client;

import com.typewritermc.playtest.wire.Message.Ready;
import com.typewritermc.playtest.wire.Payload.StepAck;
import java.util.ArrayDeque;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.fabricmc.fabric.api.client.networking.v1.ClientPlayNetworking;
import net.minecraft.client.Minecraft;
import net.minecraft.util.Util;

/**
 * The client's clock in step with Paper. Paper sends a step ping at the end of every stepped tick; from
 * the first one on, the client's clock stands still and moves exactly one tick for each step ping, so
 * the client runs one tick per server tick. The frame right after the tick records it; once the
 * client's own work for the tick is done too ({@link ClientWork}), the client acks it, and Paper runs
 * the next one.
 * Render thread only, except {@link #wake()}.
 */
final class Stepper {
    /** Step pings carry the server tick plus this; smaller ids are barriers. */
    static final int STEP_BASE = 1 << 30;

    private static final long TICK_NANOS = 50_000_000L;
    private static final long PARK_NANOS = TimeUnit.MILLISECONDS.toNanos(2);
    private static final long WAITING_PARK_NANOS = TimeUnit.MILLISECONDS.toNanos(50);

    private static final ArrayDeque<Integer> granted = new ArrayDeque<>();
    private static volatile Thread renderThread;
    private static volatile long virtualNanos;
    private static boolean stepping;
    private static Integer running;
    private static int lastPinged = -1;
    private static int lastRan = -1;
    private static boolean perceiveDue;
    private static boolean ackDue;
    private static int askedAfter = -1;

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
     * frame in flight could read the real clock after the switch and lose part of the first step. Until
     * the player is in the world the client ignores step pings: a client that joins a Paper that steps
     * already, replacing a lost one, loads the world on its own clock, since a stepped client draws no
     * frame of the loading screen.
     */
    static void onStepPing(int tick) {
        if (!Session.joined()) return;
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

    /**
     * The client left its Paper: its clock runs on its own again, from where the stepped clock stood so
     * time never runs backward, and it waits for the step pings of the next Paper it joins.
     */
    static void leftPaper() {
        if (stepping) {
            long offset = virtualNanos - System.nanoTime();
            Util.setTimeSource(() -> System.nanoTime() + offset);
        }
        stepping = false;
        granted.clear();
        running = null;
        lastPinged = -1;
        lastRan = -1;
        perceiveDue = false;
        ackDue = false;
    }

    /** Head of {@code Minecraft.runTick}, before it reads the clock. */
    static void beforeRunTick(Minecraft mc) {
        renderThread = Thread.currentThread();
        // Without a Paper the client only waits for the pool, which wakes it.
        if (Session.waiting()) LockSupport.parkNanos(WAITING_PARK_NANOS);
        if (!stepping) return;
        processPackets(mc);
        if (running != null) return;
        if (granted.isEmpty() && !perceiveDue && !ackDue && !Perceiver.forced()) {
            LockSupport.parkNanos(PARK_NANOS);
            processPackets(mc);
        }
        Integer next = granted.poll();
        if (next != null) {
            running = next;
            virtualNanos += TICK_NANOS;
        } else {
            // No tick runs in this pass: an input that waits to start asks Paper for a tick here.
            Inputs.betweenTicks(mc, false);
            ack();
        }
    }

    /**
     * Handles the packets queued for the render thread, here and where {@code Minecraft.runTick} does,
     * unless the record of the tick that ran is still due: a packet queued after that tick's step ping
     * belongs to the next tick, and handled before the record went out it would show a tick early. The
     * record goes out in the frame right after its tick, and Paper sends the next step ping only after
     * the ack.
     */
    static void processPackets(Minecraft mc) {
        if (stepping && perceiveDue) return;
        mc.packetProcessor().processQueuedPackets();
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

    /** After a perceived frame: the tick it recorded is acked once the client's own work for it is done. */
    static void perceived() {
        if (!perceiveDue) return;
        perceiveDue = false;
        ackDue = true;
        ack();
    }

    /** Acks the recorded tick once the events an input queued after it reached the game, so Paper may run the next. */
    private static void ack() {
        if (!ackDue || !ClientWork.done()) return;
        ackDue = false;
        ClientPlayNetworking.send(new StepAckPayload(new StepAck(lastRan, Inputs.busy())));
    }

    /**
     * An input waits for a tick while no ack is due, so Paper, idle until now, hears that this client
     * needs it to step; once for each tick the client ran.
     */
    static void needTicks() {
        if (!stepping || perceiveDue || ackDue || askedAfter == lastRan) return;
        askedAfter = lastRan;
        ClientPlayNetworking.send(new StepAckPayload(new StepAck(lastRan, true)));
    }
}
