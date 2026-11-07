package probe.agent;

import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.atomic.AtomicLong;
import java.util.concurrent.locks.LockSupport;

/**
 * The runner's tick permits. With {@code on} false Paper ticks on its own clock, unchanged.
 * With {@code on} true the main loop starts a tick only when it takes a permit; between ticks it
 * keeps handling packets and tasks (Paper's own idle loop) and calls {@link #hook} every pass.
 */
public final class Step {
    public static volatile boolean on;
    /** Paper's block break clock (lag compensation tick) counts server ticks instead of wall clock. */
    public static volatile boolean tickClock;
    /** Called on the main thread on every idle pass between ticks; the plugin's step policy lives here. */
    public static volatile Runnable hook;

    private static final AtomicInteger permits = new AtomicInteger();
    private static final AtomicLong taken = new AtomicLong();
    private static final AtomicLong idleNanos = new AtomicLong();
    private static volatile Thread main;
    /** True while the main loop waits between ticks; a managedBlock inside a tick also idles, but must not step. */
    private static volatile boolean between;

    private Step() {}

    /** The next tick may start: called from the waitUntilNextTick condition. */
    public static boolean take() {
        main = Thread.currentThread();
        between = true;
        Runnable h = hook;
        if (h != null) h.run();
        while (true) {
            int p = permits.get();
            if (p <= 0) return false;
            if (permits.compareAndSet(p, p - 1)) {
                between = false;
                taken.incrementAndGet();
                return true;
            }
        }
    }

    public static void idle() {
        main = Thread.currentThread();
        Runnable h = hook;
        if (h != null && between) h.run();
        if (permits.get() > 0) return;
        long t0 = System.nanoTime();
        LockSupport.parkNanos("waiting for the runner", 50_000L);
        idleNanos.addAndGet(System.nanoTime() - t0);
    }

    /** While stepping there is no deadline: idle passes always have time, a tick does not wait for one. */
    public static boolean haveTime() {
        return permits.get() <= 0;
    }

    public static void grant(int n) {
        permits.addAndGet(n);
        Thread m = main;
        if (m != null) LockSupport.unpark(m);
    }

    public static int permits() {
        return permits.get();
    }

    public static long taken() {
        return taken.get();
    }

    public static long idleNanos() {
        return idleNanos.get();
    }
}
