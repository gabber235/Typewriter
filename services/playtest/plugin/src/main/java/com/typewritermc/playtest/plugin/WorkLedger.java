package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.UUID;
import java.util.function.LongSupplier;

/**
 * The work plugins count for each player through {@link PlayerWork}, and when it holds the stepped
 * Paper's next tick. Any thread begins and ends work; the main thread tells the ledger where the ticks
 * are and asks it between ticks.
 *
 * <p>Work lets the next tick to start after its begin run, since Bukkit's async scheduler starts a task
 * only at that tick's heartbeat, and holds every tick after it until it ends. Work that still runs
 * {@link #HUNG_NANOS} after it began is hung: reported once, it holds no tick from then on, and it is
 * never cancelled.
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
            synchronized (WorkLedger.this) {
                counted.remove(this);
            }
        }
    }

    private final LongSupplier nanos;
    // Work that is neither ended nor hung, in begin order.
    private final List<Entry> counted = new ArrayList<>();
    private int lastEnded = -1;
    private int running = -1;

    WorkLedger(LongSupplier nanos) {
        this.nanos = nanos;
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

    /** [player]'s plugin began work [name]. Any thread. */
    synchronized Entry begin(UUID player, String playerName, String name) {
        int nextToStart = (running >= 0 ? running : lastEnded) + 1;
        var entry = new Entry(player, playerName, name, lastEnded, nextToStart + 1, nanos.getAsLong());
        counted.add(entry);
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

    /** The work that became hung since the last call, each reported once. */
    synchronized List<Hung> hung() {
        long now = nanos.getAsLong();
        var hung = new ArrayList<Hung>();
        counted.removeIf(entry -> {
            if (now - entry.beganNanos < HUNG_NANOS) return false;
            hung.add(new Hung(entry.player, entry.playerName, entry.name, entry.beganAfter));
            return true;
        });
        return hung;
    }
}
