package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.Collection;
import java.util.LinkedHashSet;
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
 * <p>Each piece of work has a deadline, {@link #HUNG_NANOS} after it began. One watchdog, on a thread
 * of its own, wakes at the deadline of the oldest open work: the main thread may spend that moment in one
 * long tick, and the report must reach the pool while the work still runs, before anything the work does
 * later. Open work is kept in begin order and every deadline is as far from its begin, so the oldest is
 * always due first; the watchdog reports every piece due, then sleeps until the next. The deadline alone
 * decides hung, and the end of hung work is reported only after its hang.
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
        private final long dueNanos;
        // Whom the hang was reported to, which its end is reported to as well.
        private Set<UUID> reportedTo;
        // Set once the hang report went out; work that ends before then is reported ended by the deadline.
        private boolean reported;
        private boolean endedUnreported;

        private Entry(Set<UUID> players, String name, int beganAfter, int holdsFrom, long dueNanos) {
            this.players = players;
            this.name = name;
            this.beganAfter = beganAfter;
            this.holdsFrom = holdsFrom;
            this.dueNanos = dueNanos;
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

    /** The watchdog's clock and its alarm, which tests replace with time of their own. */
    interface Watch {
        /** Now, in nanoseconds of a monotonic clock. */
        long nanoTime();

        /** Runs [task] once, [nanos] from now, off the main thread. */
        void after(long nanos, Runnable task);
    }

    /** The monotonic clock, and one daemon thread that runs the watchdog. */
    static Watch watchThread() {
        ScheduledExecutorService thread = Executors.newSingleThreadScheduledExecutor(task -> {
            var named = new Thread(task, "playtest-work-watchdog");
            named.setDaemon(true);
            return named;
        });
        return new Watch() {
            @Override
            public long nanoTime() {
                return System.nanoTime();
            }

            @Override
            public void after(long nanos, Runnable task) {
                thread.schedule(task, nanos, TimeUnit.NANOSECONDS);
            }
        };
    }

    private final Watch watch;
    private volatile Consumer<Hung> reportHung = hung -> {};
    private volatile Consumer<Failed> reportFailed = failed -> {};
    private volatile Set<UUID> claimed = Set.of();
    // Work that is neither ended nor hung, in begin order, so the oldest deadline comes first.
    private final Set<Entry> counted = new LinkedHashSet<>();
    // Whether the watchdog is set to wake for the oldest open work.
    private boolean watching;
    // Hung work that still runs, and hung work that ended since the last report.
    private final List<Entry> hung = new ArrayList<>();
    private final List<Entry> ended = new ArrayList<>();
    private int lastEnded = -1;
    private int running = -1;

    WorkLedger(Watch watch) {
        this.watch = watch;
    }

    /** Hung work goes to [report], from the watchdog's thread or the thread that ended the work. */
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
        var entry =
                new Entry(players == null ? null : Set.copyOf(players), name, lastEnded, holdsFrom, watch.nanoTime() + HUNG_NANOS);
        counted.add(entry);
        if (!watching) watchFor(entry);
        return entry;
    }

    private void watchFor(Entry oldest) {
        watching = true;
        watch.after(Math.max(0, oldest.dueNanos - watch.nanoTime()), this::wake);
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
     * The watchdog woke: every open work whose deadline passed is hung and reported now, oldest first,
     * while it runs; work that ends while its report goes out is reported ended after it. Then the
     * watchdog sleeps until the deadline of the oldest work still open. Watchdog thread.
     */
    private void wake() {
        List<Entry> due = new ArrayList<>();
        synchronized (this) {
            watching = false;
            long now = watch.nanoTime();
            for (var open = counted.iterator(); open.hasNext(); ) {
                Entry entry = open.next();
                if (entry.dueNanos > now) break;
                open.remove();
                hung.add(entry);
                entry.reportedTo = entry.players == null ? claimed : entry.players;
                due.add(entry);
            }
            if (!counted.isEmpty()) watchFor(counted.iterator().next());
        }
        for (Entry entry : due) {
            reportHung.accept(entry.report());
            synchronized (this) {
                entry.reported = true;
                if (entry.endedUnreported) ended.add(entry);
            }
        }
    }
}
