package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.agent.Step;
import java.util.ArrayList;
import java.util.Collection;
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
 * on its way to it, the next tick runs once every claimed player's client, and every such player's,
 * acked the tick that ended last, so server and every attempt's clients move one tick at a time and a
 * claimed client never lags behind. Once a window's last tick ended and was acked, the player gets the
 * window's barrier. With none of these, Paper still ticks once a second, or its watchdog stops it and
 * keepalives stop.
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

    /** Work that ran after tick [ranAfter], waiting until its effect reached the clients of [waiting]. */
    private static final class Delivery {
        final Set<UUID> waiting;
        final int ranAfter;
        final Runnable done;
        final Map<UUID, Integer> confirmedBy = new HashMap<>();

        Delivery(Collection<UUID> players, int ranAfter, Runnable done) {
            this.waiting = new HashSet<>(players);
            this.ranAfter = ranAfter;
            this.done = done;
        }
    }

    private final Set<UUID> claimed = new HashSet<>();
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
            if (tick <= delivery.ranAfter) continue;
            for (UUID player : delivery.waiting) {
                if (delivery.confirmedBy.containsKey(player) || !nothingLeftToSend.test(player)) continue;
                delivery.confirmedBy.put(player, UNCONFIRMED);
                // The next step ping goes out after every packet the tasks queued so far send.
                queueOnMain.accept(() -> delivery.confirmedBy.put(player, lastEnded + 1));
            }
        }
    }

    /** The player's client ran and perceived [tick]; [busy] while it runs an input that needs further ticks. */
    void acked(UUID player, int tick, boolean busy) {
        acked.merge(player, tick, Math::max);
        if (busy) this.busy.add(player);
        else this.busy.remove(player);
    }

    /** [players] belong to an attempt: from now on no tick runs before each of their clients ran the one before. */
    void claim(Collection<UUID> players) {
        claimed.addAll(players);
    }

    /** [players]' attempt ended: they hold back no tick and their windows close without a barrier. */
    void release(Collection<UUID> players) {
        claimed.removeAll(players);
        players.forEach(windows::remove);
    }

    void stepUntil(UUID player, int tick, int barrier) {
        windows.put(player, new Window(tick, barrier));
    }

    void stop(UUID player) {
        windows.remove(player);
    }

    /** Work for [players] just ran; [done] runs once its effect reached each of their clients. */
    void deliver(Collection<UUID> players, Runnable done) {
        deliveries.add(new Delivery(players, lastEnded, done));
    }

    /** One idle pass between ticks: finishes deliveries, grants the next tick or sends barriers. */
    void run() {
        if (Step.pending()) return;
        for (Iterator<Delivery> open = deliveries.iterator(); open.hasNext(); ) {
            Delivery delivery = open.next();
            delivery.waiting.removeIf(player -> acked.getOrDefault(player, -1) >= delivery.confirmedBy.getOrDefault(player, UNCONFIRMED));
            if (!delivery.waiting.isEmpty()) continue;
            open.remove();
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
        if (!allAcked(claimed) || !allAcked(windows.keySet()) || !allAcked(busy)) return;
        for (Delivery delivery : deliveries) {
            if (!allAcked(delivery.waiting)) return;
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
