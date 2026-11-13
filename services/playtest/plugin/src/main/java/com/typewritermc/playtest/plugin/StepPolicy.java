package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.agent.Step;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.BiConsumer;
import java.util.function.Consumer;
import java.util.function.Predicate;

/**
 * Decides when the stepped Paper runs its next tick. Main thread only, between ticks.
 *
 * <p>While a player waits in a window, its client runs an input that needs ticks, or a probe's effect is
 * on its way to it, the next tick runs once every such player's client acked the tick that ended last,
 * so server and client move one tick at a time. Once a window's last tick ended and was acked, the
 * player gets the window's barrier. With none of these, Paper still ticks once a second, or its watchdog
 * stops it and keepalives stop.
 *
 * <p>A probe's effect reached its player once a tick after the probe ended with nothing left to send to
 * that player, the main thread ran every task queued before that, and the client acked a tick whose
 * step ping went out after them: a client handles packets in order, so it then holds all of them.
 */
final class StepPolicy {
    /** Step pings carry the tick plus this, so they never collide with a barrier. */
    static final int STEP_BASE = 1 << 30;

    private static final long IDLE_TICK_NANOS = 1_000_000_000L;
    private static final int UNCONFIRMED = Integer.MAX_VALUE;

    private record Window(int until, int barrier) {}

    /** A probe that ran after tick [ranAfter], waiting until its effect reached [player]'s client. */
    private static final class Delivery {
        final UUID player;
        final int ranAfter;
        final Runnable done;
        boolean draining;
        int confirmedBy = UNCONFIRMED;

        Delivery(UUID player, int ranAfter, Runnable done) {
            this.player = player;
            this.ranAfter = ranAfter;
            this.done = done;
        }
    }

    private final Map<UUID, Window> windows = new HashMap<>();
    private final Map<UUID, Integer> acked = new HashMap<>();
    private final Set<UUID> busy = new HashSet<>();
    private final List<Delivery> deliveries = new ArrayList<>();
    private final BiConsumer<UUID, Integer> sendBarrier;
    private final Predicate<UUID> nothingLeftToSend;
    private final Consumer<Runnable> queueOnMain;
    private int lastEnded = -1;
    private long lastIdleTick;

    /**
     * @param nothingLeftToSend whether Paper has nothing more to send the player, now or from work in
     *     flight off the main thread
     * @param queueOnMain queues a task behind every task the main thread holds, even from the main thread
     */
    StepPolicy(BiConsumer<UUID, Integer> sendBarrier, Predicate<UUID> nothingLeftToSend, Consumer<Runnable> queueOnMain) {
        this.sendBarrier = sendBarrier;
        this.nothingLeftToSend = nothingLeftToSend;
        this.queueOnMain = queueOnMain;
    }

    /** The tick that ended last; a stimulus between ticks takes effect from the next one. */
    int lastEnded() {
        return lastEnded;
    }

    void tickEnded(int tick) {
        lastEnded = tick;
        for (Delivery delivery : deliveries) {
            if (delivery.draining || tick <= delivery.ranAfter || !nothingLeftToSend.test(delivery.player)) continue;
            delivery.draining = true;
            // The next step ping goes out after every packet the tasks queued so far send.
            queueOnMain.accept(() -> delivery.confirmedBy = lastEnded + 1);
        }
    }

    /** The player's client ran and perceived [tick]; [busy] while it runs an input that needs further ticks. */
    void acked(UUID player, int tick, boolean busy) {
        acked.merge(player, tick, Math::max);
        if (busy) this.busy.add(player);
        else this.busy.remove(player);
    }

    void stepUntil(UUID player, int tick, int barrier) {
        windows.put(player, new Window(tick, barrier));
    }

    void stop(UUID player) {
        windows.remove(player);
    }

    /** A probe for [player] just ran; [done] runs once its effect reached the player's client. */
    void deliver(UUID player, Runnable done) {
        deliveries.add(new Delivery(player, lastEnded, done));
    }

    /** One idle pass between ticks: finishes deliveries, grants the next tick or sends barriers. */
    void run() {
        if (Step.pending()) return;
        for (Iterator<Delivery> waiting = deliveries.iterator(); waiting.hasNext(); ) {
            Delivery delivery = waiting.next();
            if (acked.getOrDefault(delivery.player, -1) < delivery.confirmedBy) continue;
            waiting.remove();
            delivery.done.run();
        }
        if (windows.isEmpty() && busy.isEmpty() && deliveries.isEmpty()) {
            long now = System.nanoTime();
            if (now - lastIdleTick >= IDLE_TICK_NANOS) {
                lastIdleTick = now;
                Step.grant();
            }
            return;
        }
        if (!allAcked(windows.keySet()) || !allAcked(busy)) return;
        for (Delivery delivery : deliveries) {
            if (acked.getOrDefault(delivery.player, -1) < lastEnded) return;
        }
        for (Iterator<Map.Entry<UUID, Window>> open = windows.entrySet().iterator(); open.hasNext(); ) {
            var window = open.next();
            if (lastEnded >= window.getValue().until()) {
                sendBarrier.accept(window.getKey(), window.getValue().barrier());
                open.remove();
            }
        }
        if (!windows.isEmpty() || !busy.isEmpty() || !deliveries.isEmpty()) Step.grant();
    }

    private boolean allAcked(Set<UUID> players) {
        for (UUID player : players) {
            if (acked.getOrDefault(player, -1) < lastEnded) return false;
        }
        return true;
    }
}
