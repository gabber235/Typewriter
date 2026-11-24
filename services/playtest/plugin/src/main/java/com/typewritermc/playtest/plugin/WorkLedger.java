package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

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
 * while the work still runs, before anything the work does later. The deadline alone decides hung, and
 * the end of hung work is reported only after its hang.
 */
final class WorkLedger {
    /** How long work may run before it is reported as hung. */
    static final long HUNG_NANOS = 1_000_000_000L;

    /**
     * The work [name] of [players], which began after tick [beganAfter], still ran {@link #HUNG_NANOS}
     * later. Work for no player is the work of the players claimed at its deadline.
     */
    record Hung(Set<UUID> players, String name, int beganAfter) {}

    /**
     * The work [name] of [players], which began after tick [beganAfter], ended without its effect because
     * of [cause]. Work for no player is the work of the players claimed when it failed.
     */
    record Failed(Set<UUID> players, String name, int beganAfter, String cause) {}

    /** One piece of counted work, from its begin until {@link #end()}. */
    final class Entry {
        private final Set<UUID> players;
        private final String name;
        private final int beganAfter;
        private final int holdsFrom;
        // Whom the hang was reported to, which its end is reported to as well.
        private Set<UUID> reportedTo;
        // Set once the hang report went out; work that ends before then is reported ended by the deadline.
        private boolean reported;
        private boolean endedUnreported;

        private Entry(Set<UUID> players, String name, int beganAfter, int holdsFrom) {
            this.players = players;
            this.name = name;
            this.beganAfter = beganAfter;
            this.holdsFrom = holdsFrom;
        }

        /**
         * The work is done; ending it again does nothing. Hung work is reported ended only once its hang
         * report went out, so the pool never hears the end before the hang.
         */
        void end() {
            synchronized (WorkLedger.this) {
                if (counted.remove(this)) return;
                endHung();
            }
        }

        /**
         * The work ended without its effect because of [cause]: reported once, now, on this thread, and it
         * holds no tick from then on. Hung work that fails ends as hung work does; ending it again does
         * nothing.
         */
        void failed(String cause) {
            Failed report;
            synchronized (WorkLedger.this) {
                if (!counted.remove(this)) {
                    endHung();
                    return;
                }
                report = new Failed(players == null ? claimed : players, name, beganAfter, cause);
            }
            reportFailed.accept(report);
        }

        private void endHung() {
            if (!hung.remove(this)) return;
            if (reported) ended.add(this);
            else endedUnreported = true;
        }

        /** Whether this is work of any of [claimed]; work for no player is everyone's. */
        private boolean of(Collection<UUID> claimed) {
            if (players == null) return !claimed.isEmpty();
            for (UUID player : players) {
                if (claimed.contains(player)) return true;
            }
            return false;
        }

        private Hung report() {
            return new Hung(reportedTo, name, beganAfter);
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

    private final Deadlines deadlines;
    private volatile Consumer<Hung> reportHung = hung -> {};
    private volatile Consumer<Failed> reportFailed = failed -> {};
    private volatile Set<UUID> claimed = Set.of();
    // Work that is neither ended nor hung, in begin order.
    private final List<Entry> counted = new ArrayList<>();
    // Hung work that still runs, and hung work that ended since the last report.
    private final List<Entry> hung = new ArrayList<>();
    private final List<Entry> ended = new ArrayList<>();
    private int lastEnded = -1;
    private int running = -1;

    WorkLedger(Deadlines deadlines) {
        this.deadlines = deadlines;
    }

    /** Hung work goes to [report], from the deadline's thread or the thread that ended the work. */
    void reportHungTo(Consumer<Hung> report) {
        reportHung = report;
    }

    /** [players] are claimed now: work for no player is theirs when it hangs or fails. Main thread. */
    void claimed(Set<UUID> players) {
        claimed = Set.copyOf(players);
    }

    /** Failed work goes to [report], from the thread that failed it. */
    void reportFailedTo(Consumer<Failed> report) {
        reportFailed = report;
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

    /**
     * A plugin began work [name] for [players] (null: for every claimed player) that already runs; it
     * holds the next tick to start. Any thread.
     */
    synchronized Entry begin(Set<UUID> players, String name) {
        return count(players, name, nextToStart());
    }

    /**
     * [player]'s plugin handed work [name] to Bukkit's async scheduler; it lets the next tick start, whose
     * heartbeat starts it, and holds the one after. Any thread.
     */
    synchronized Entry schedule(Set<UUID> players, String name) {
        return count(players, name, nextToStart() + 1);
    }

    private int nextToStart() {
        return (running >= 0 ? running : lastEnded) + 1;
    }

    private Entry count(Set<UUID> players, String name, int holdsFrom) {
        var entry = new Entry(players == null ? null : Set.copyOf(players), name, lastEnded, holdsFrom);
        counted.add(entry);
        deadlines.after(HUNG_NANOS, () -> deadline(entry));
        return entry;
    }

    /** Whether work of any of [players] holds [tick] from starting. */
    synchronized boolean holds(Collection<UUID> players, int tick) {
        for (Entry entry : counted) {
            if (tick >= entry.holdsFrom && entry.of(players)) return true;
        }
        return false;
    }

    /** Whether none of [players] has work that is neither ended nor hung. */
    synchronized boolean quiet(Collection<UUID> players) {
        for (Entry entry : counted) {
            if (entry.of(players)) return false;
        }
        return true;
    }

    /** The hung work that ended since the last call, each reported once. */
    synchronized List<Hung> ended() {
        var reports = ended.stream().map(Entry::report).toList();
        ended.clear();
        return reports;
    }

    /**
     * [entry]'s deadline: work still running is hung and reported now, while it runs; if it ends while the
     * report goes out, its end is reported after it. Deadline thread.
     */
    private void deadline(Entry entry) {
        synchronized (this) {
            if (!counted.remove(entry)) return;
            hung.add(entry);
            entry.reportedTo = entry.players == null ? claimed : entry.players;
        }
        reportHung.accept(entry.report());
        synchronized (this) {
            entry.reported = true;
            if (entry.endedUnreported) ended.add(entry);
        }
    }
}
