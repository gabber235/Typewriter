package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.Iterator;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.function.LongSupplier;

/**
 * The tick each player's client acked last, and which clients stalled: a client watched since its first
 * ack that acked nothing for {@link #STALL_NANOS} of wall clock while behind the tick that ended last.
 * Main thread only.
 */
final class Acks {
    /** How long a client behind the last tick may go without an ack before it counts as lost. */
    static final long STALL_NANOS = 5_000_000_000L;

    /** [player]'s client acked tick [lastAcked] last and nothing in {@link #STALL_NANOS} since. */
    record Stalled(UUID player, int lastAcked) {}

    private final LongSupplier nanos;
    private final Map<UUID, Integer> acked = new HashMap<>();
    // Watched clients behind the tick that ended last, since their last ack or since that tick ended.
    private final Map<UUID, Long> behindSince = new HashMap<>();
    private int lastEnded = -1;

    Acks(LongSupplier nanos) {
        this.nanos = nanos;
    }

    /** Paper ended [tick]; every watched client is behind until it acks it. */
    void tickEnded(int tick) {
        lastEnded = tick;
        long now = nanos.getAsLong();
        acked.forEach((player, last) -> {
            if (last < tick) behindSince.putIfAbsent(player, now);
        });
    }

    /** [player]'s client ran and perceived [tick]. */
    void acked(UUID player, int tick) {
        Integer before = acked.get(player);
        if (before != null && tick <= before) return;
        acked.put(player, tick);
        if (tick >= lastEnded) behindSince.remove(player);
        else behindSince.put(player, nanos.getAsLong());
    }

    /** The tick [player]'s client acked last, or -1. */
    int lastAcked(UUID player) {
        return acked.getOrDefault(player, -1);
    }

    /** [player] left Paper; its client is watched no more. */
    void lose(UUID player) {
        acked.remove(player);
        behindSince.remove(player);
    }

    /** The clients that stalled since the last call, each reported once and watched no more. */
    List<Stalled> stalled() {
        long now = nanos.getAsLong();
        var stalled = new ArrayList<Stalled>();
        for (Iterator<Map.Entry<UUID, Long>> behind = behindSince.entrySet().iterator(); behind.hasNext(); ) {
            var entry = behind.next();
            if (now - entry.getValue() < STALL_NANOS) continue;
            behind.remove();
            stalled.add(new Stalled(entry.getKey(), acked.remove(entry.getKey())));
        }
        return stalled;
    }
}
