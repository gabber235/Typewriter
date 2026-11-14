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
 *
 * <p>No tick runs, not even the idle one, while the {@link WorkLedger} says a claimed player's counted
 * work holds it, so work takes no ticks from any attempt's windows; work that hangs is reported and
 * holds no tick from then on. An attempt is settled once its players' work is quiet, stepping on
 * meanwhile so work handed to Bukkit's async scheduler can start.
 *
 * <p>A client that {@link Acks} finds stalled holds back no tick from then on, and counts as lost.
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

    /** An attempt whose body ended, waiting until its [players]' counted work is quiet. */
    private record Settling(Set<UUID> players, Runnable done) {}

    private final Set<UUID> claimed = new HashSet<>();
    private final List<Settling> settling = new ArrayList<>();
    private final Map<UUID, Window> windows = new HashMap<>();
    private final Set<UUID> busy = new HashSet<>();
    private final List<Delivery> deliveries = new ArrayList<>();
    private final BiConsumer<UUID, Integer> sendBarrier;
    private final Predicate<UUID> nothingLeftToSend;
    private final Consumer<Runnable> queueOnMain;
    private final WorkLedger work;
    private final Consumer<WorkLedger.Hung> reportHung;
    private final Consumer<WorkLedger.Hung> reportEnded;
    private final Acks acks;
    private final Consumer<Acks.Stalled> reportStalled;
    private int lastEnded = -1;
    private long lastIdleTick;

    /**
     * @param nothingLeftToSend whether Paper has nothing more to send the player, now or from work in
     *     flight off the main thread
     * @param queueOnMain queues a task behind every task the main thread holds, even from the main thread
     * @param work the work plugins count for each player
     * @param reportHung tells the player's attempt that its work hung
     * @param reportEnded tells the pool that work reported hung ended
     * @param acks the tick each client acked last
     * @param reportStalled tells the pool that a client stalled
     */
    StepPolicy(
            BiConsumer<UUID, Integer> sendBarrier,
            Predicate<UUID> nothingLeftToSend,
            Consumer<Runnable> queueOnMain,
            WorkLedger work,
            Consumer<WorkLedger.Hung> reportHung,
            Consumer<WorkLedger.Hung> reportEnded,
            Acks acks,
            Consumer<Acks.Stalled> reportStalled) {
        this.sendBarrier = sendBarrier;
        this.nothingLeftToSend = nothingLeftToSend;
        this.queueOnMain = queueOnMain;
        this.work = work;
        this.reportHung = reportHung;
        this.reportEnded = reportEnded;
        this.acks = acks;
        this.reportStalled = reportStalled;
    }

    /** The tick that ended last; a stimulus between ticks takes effect from the next one. */
    int lastEnded() {
        return lastEnded;
    }

    void tickEnded(int tick) {
        lastEnded = tick;
        acks.tickEnded(tick);
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
        acks.acked(player, tick);
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

    /** [player] left Paper: it holds back no tick, and nothing waits for its client any more. */
    void lose(UUID player) {
        claimed.remove(player);
        windows.remove(player);
        busy.remove(player);
        acks.lose(player);
        for (Delivery delivery : deliveries) delivery.waiting.remove(player);
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

    /** [players]' attempt ended its body; [done] runs once their counted work is quiet. */
    void settle(Collection<UUID> players, Runnable done) {
        settling.add(new Settling(Set.copyOf(players), done));
    }

    /**
     * One idle pass between ticks: reports hung work, ended hung work and stalled clients, finishes
     * deliveries and settled attempts, grants the next tick or sends barriers.
     */
    void run() {
        if (Step.pending()) return;
        work.hung().forEach(reportHung);
        work.ended().forEach(reportEnded);
        for (Acks.Stalled stalled : acks.stalled()) {
            lose(stalled.player());
            reportStalled.accept(stalled);
        }
        for (Iterator<Delivery> open = deliveries.iterator(); open.hasNext(); ) {
            Delivery delivery = open.next();
            delivery.waiting.removeIf(player -> acks.lastAcked(player) >= delivery.confirmedBy.getOrDefault(player, UNCONFIRMED));
            if (!delivery.waiting.isEmpty()) continue;
            open.remove();
            delivery.done.run();
        }
        for (Iterator<Settling> open = settling.iterator(); open.hasNext(); ) {
            Settling settled = open.next();
            if (!work.quiet(settled.players())) continue;
            open.remove();
            settled.done().run();
        }
        if (work.holds(claimed, lastEnded + 1)) return;
        if (windows.isEmpty() && busy.isEmpty() && deliveries.isEmpty() && settling.isEmpty()) {
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
        if (!windows.isEmpty() || !busy.isEmpty() || !deliveries.isEmpty() || !settling.isEmpty()) Step.grant();
    }

    private boolean allAcked(Set<UUID> players) {
        for (UUID player : players) {
            if (acks.lastAcked(player) < lastEnded) return false;
        }
        return true;
    }
}
