package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;
import java.util.function.LongSupplier;

/**
 * The work plugins count for each player through {@link PlayerWork}, and when it holds the stepped
 * Paper's next tick. Any thread begins and ends work; the main thread tells the ledger where the ticks
 * are and asks it between ticks.
 *
 * <p>Work that already runs when it begins holds the next tick to start until it ends. A task handed to
 * Bukkit's async scheduler starts only at the next tick's heartbeat, so it lets that tick start and
 * holds every tick after it until it ends. Work that still runs
 * {@link #HUNG_NANOS} after it began is hung: reported once, it holds no tick from then on, and it is
 * never cancelled; once it ends, that is reported once too, so its player can come back to the pool.
 *
 * <p>Each piece of work has a deadline of its own, {@link #HUNG_NANOS} after it began, on a thread of
 * its own: the main thread may spend that moment in one long tick, and the report must reach the pool
 * while the work still runs, before anything the work does later. A deadline that runs late, after the
 * work ended past its limit, leaves the report to the end of the work.
 */
final class WorkLedger {
    /** How long work may run before it is reported as hung. */
    static final long HUNG_NANOS = 1_000_000_000L;

    /** [player]'s work [name], which began after tick [beganAfter], still ran {@link #HUNG_NANOS} later. */
    record Hung(UUID player, String playerName, String name, int beganAfter) {}

    /** One piece of counted work, from its begin until {@link #end()}. */
    final class Entry {
        private final UUID player;
        private final String playerName;
        private final String name;
        private final int beganAfter;
        private final int holdsFrom;
        private final long beganNanos;

        private Entry(UUID player, String playerName, String name, int beganAfter, int holdsFrom, long beganNanos) {
            this.player = player;
            this.playerName = playerName;
            this.name = name;
            this.beganAfter = beganAfter;
            this.holdsFrom = holdsFrom;
            this.beganNanos = beganNanos;
        }

        /** The work is done; ending it again does nothing. */
        void end() {
            boolean outranUnseen;
            synchronized (WorkLedger.this) {
                if (hung.remove(this)) {
                    ended.add(this);
                    return;
                }
                if (!counted.remove(this)) return;
                outranUnseen = nanos.getAsLong() - beganNanos >= HUNG_NANOS;
            }
            if (!outranUnseen) return;
            reportHung.accept(report());
            synchronized (WorkLedger.this) {
                ended.add(this);
            }
        }

        private Hung report() {
            return new Hung(player, playerName, name, beganAfter);
        }
    }

    /** Runs [task] [nanos] from now, off the main thread. */
    @FunctionalInterface
    interface Deadlines {
        void after(long nanos, Runnable task);
    }

    /** One daemon thread that runs every deadline. */
    static Deadlines deadlineThread() {
        ScheduledExecutorService thread = Executors.newSingleThreadScheduledExecutor(task -> {
            var named = new Thread(task, "playtest-work-deadlines");
            named.setDaemon(true);
            return named;
        });
        return (nanos, task) -> thread.schedule(task, nanos, TimeUnit.NANOSECONDS);
    }

    private final LongSupplier nanos;
    private final Deadlines deadlines;
    private volatile Consumer<Hung> reportHung = hung -> {};
    // Work that is neither ended nor hung, in begin order.
    private final List<Entry> counted = new ArrayList<>();
    // Hung work that still runs, and hung work that ended since the last report.
    private final List<Entry> hung = new ArrayList<>();
    private final List<Entry> ended = new ArrayList<>();
    private int lastEnded = -1;
    private int running = -1;

    WorkLedger(LongSupplier nanos, Deadlines deadlines) {
        this.nanos = nanos;
        this.deadlines = deadlines;
    }

    /** Hung work goes to [report], from the deadline's thread or the thread that ended the work. */
    void reportHungTo(Consumer<Hung> report) {
        reportHung = report;
    }

    /** Paper started [tick]. Main thread. */
    synchronized void tickStarted(int tick) {
        running = tick;
    }

    /** Paper ended [tick]. Main thread. */
    synchronized void tickEnded(int tick) {
        lastEnded = tick;
        running = -1;
    }

    /** [player]'s plugin began work [name] that already runs; it holds the next tick to start. Any thread. */
    synchronized Entry begin(UUID player, String playerName, String name) {
        return count(player, playerName, name, nextToStart());
    }

    /**
     * [player]'s plugin handed work [name] to Bukkit's async scheduler; it lets the next tick start, whose
     * heartbeat starts it, and holds the one after. Any thread.
     */
    synchronized Entry schedule(UUID player, String playerName, String name) {
        return count(player, playerName, name, nextToStart() + 1);
    }

    private int nextToStart() {
        return (running >= 0 ? running : lastEnded) + 1;
    }

    private Entry count(UUID player, String playerName, String name, int holdsFrom) {
        var entry = new Entry(player, playerName, name, lastEnded, holdsFrom, nanos.getAsLong());
        counted.add(entry);
        deadlines.after(HUNG_NANOS, () -> deadline(entry));
        return entry;
    }

    /** Whether work of any of [players] holds [tick] from starting. */
    synchronized boolean holds(Collection<UUID> players, int tick) {
        for (Entry entry : counted) {
            if (tick >= entry.holdsFrom && players.contains(entry.player)) return true;
        }
        return false;
    }

    /** Whether none of [players] has work that is neither ended nor hung. */
    synchronized boolean quiet(Collection<UUID> players) {
        for (Entry entry : counted) {
            if (players.contains(entry.player)) return false;
        }
        return true;
    }

    /** The hung work that ended since the last call, each reported once. */
    synchronized List<Hung> ended() {
        var reports = ended.stream().map(Entry::report).toList();
        ended.clear();
        return reports;
    }

    /** [entry]'s deadline: work still running is hung, reported now, while it runs. Deadline thread. */
    private void deadline(Entry entry) {
        synchronized (this) {
            if (!counted.remove(entry)) return;
            hung.add(entry);
        }
        reportHung.accept(entry.report());
    }
}
