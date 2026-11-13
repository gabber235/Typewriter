package com.typewritermc.playtest.plugin;

import com.typewritermc.playtest.agent.Step;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.function.BiConsumer;

/**
 * Decides when the stepped Paper runs its next tick. Main thread only, between ticks.
 *
 * <p>While a player waits in a window, or its client runs an input that needs ticks, the next tick runs
 * once every such player's client acked the tick that ended last, so server and client move one tick
 * at a time. Once a window's last tick ended and was acked, the player gets the window's barrier. With
 * neither, Paper still ticks once a second, or its watchdog stops it and keepalives stop.
 */
final class StepPolicy {
    /** Step pings carry the tick plus this, so they never collide with a barrier. */
    static final int STEP_BASE = 1 << 30;

    private static final long IDLE_TICK_NANOS = 1_000_000_000L;

    private record Window(int until, int barrier) {}

    private final Map<UUID, Window> windows = new HashMap<>();
    private final Map<UUID, Integer> acked = new HashMap<>();
    private final Set<UUID> busy = new HashSet<>();
    private final BiConsumer<UUID, Integer> sendBarrier;
    private int lastEnded = -1;
    private long lastIdleTick;

    StepPolicy(BiConsumer<UUID, Integer> sendBarrier) {
        this.sendBarrier = sendBarrier;
    }

    /** The tick that ended last; a stimulus between ticks takes effect from the next one. */
    int lastEnded() {
        return lastEnded;
    }

    void tickEnded(int tick) {
        lastEnded = tick;
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

    /** One idle pass between ticks: grants the next tick or sends barriers. */
    void run() {
        if (Step.pending()) return;
        if (windows.isEmpty() && busy.isEmpty()) {
            long now = System.nanoTime();
            if (now - lastIdleTick >= IDLE_TICK_NANOS) {
                lastIdleTick = now;
                Step.grant();
            }
            return;
        }
        for (UUID player : windows.keySet()) {
            if (acked.getOrDefault(player, -1) < lastEnded) return;
        }
        for (UUID player : busy) {
            if (acked.getOrDefault(player, -1) < lastEnded) return;
        }
        for (Iterator<Map.Entry<UUID, Window>> open = windows.entrySet().iterator(); open.hasNext(); ) {
            var window = open.next();
            if (lastEnded >= window.getValue().until()) {
                sendBarrier.accept(window.getKey(), window.getValue().barrier());
                open.remove();
            }
        }
        if (!windows.isEmpty() || !busy.isEmpty()) Step.grant();
    }
}
