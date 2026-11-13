package com.typewritermc.playtest.agent;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.LockSupport;

/**
 * The tick permits of a stepped Paper. While {@link #on} is false Paper ticks on its own clock,
 * unchanged. Once it is true the main loop starts a tick only when it takes a permit; between ticks it
 * keeps handling packets and tasks as Paper does while idle, and runs {@link #policy} on every pass.
 */
public final class Step {
    /** Every prefix a stepped Paper needs, as {@code Class.method}. */
    public static final Set<String> REQUIRED = Set.of(
            "MinecraftServer.recordTaskExecutionTimeWhileWaiting",
            "MinecraftServer.waitForTasks",
            "MinecraftServer.haveTime",
            "ServerLevel.currentLagCompensationTick");

    /** The methods {@link Prefixes} prefixed, as {@code Class.method}; the plugin refuses to step without all of them. */
    public static final Set<String> applied = ConcurrentHashMap.newKeySet();

    /** Stepping: a tick starts only on a permit, and Paper's block break clock counts ticks. */
    public static volatile boolean on;

    /** The step policy: runs on the main thread on every idle pass between ticks and grants permits. */
    public static volatile Runnable policy;

    private static final AtomicInteger permits = new AtomicInteger();
    private static volatile Thread main;
    // A blocking wait inside a tick (a chunk load) also idles; only the wait between ticks runs the policy.
    private static volatile boolean betweenTicks;

    private Step() {}

    /** Takes a permit if there is one: the next tick may start. Main thread, between ticks. */
    public static boolean take() {
        main = Thread.currentThread();
        betweenTicks = true;
        runPolicy();
        while (true) {
            int available = permits.get();
            if (available <= 0) return false;
            if (permits.compareAndSet(available, available - 1)) {
                betweenTicks = false;
                return true;
            }
        }
    }

    /** One idle pass: runs the policy between ticks, then parks briefly unless a permit waits. */
    public static void idle() {
        main = Thread.currentThread();
        if (betweenTicks) runPolicy();
        if (permits.get() > 0) return;
        LockSupport.parkNanos("waiting for the game pool to grant a tick", 50_000L);
    }

    /** Between stepped ticks there is no deadline, so idle work always has time until a permit waits. */
    public static boolean haveTime() {
        return permits.get() <= 0;
    }

    /** Grants one more tick. */
    public static void grant() {
        permits.incrementAndGet();
        Thread waiting = main;
        if (waiting != null) LockSupport.unpark(waiting);
    }

    /** Whether a granted tick has not started yet. */
    public static boolean pending() {
        return permits.get() > 0;
    }

    private static void runPolicy() {
        Runnable current = policy;
        if (current != null) current.run();
    }
}
