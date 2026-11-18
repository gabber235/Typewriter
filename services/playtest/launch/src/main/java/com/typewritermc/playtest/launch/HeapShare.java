package com.typewritermc.playtest.launch;

/**
 * The share of the machine's memory each kind of game JVM may take for its heap, as
 * {@code -XX:MaxRAMPercentage}, so the caps scale with the machine: without one every JVM may grow to
 * a quarter of it, and the parts that run at once outgrew a 16 GB CI runner. The pool starts every
 * part with its kind's share, and the build starts the pool with the pool's.
 */
public enum HeapShare {
    /** The shared Paper: 2.6 GB on a 16 GB runner, where its heap peaked at 2.7 GB used under a 4 GB cap. */
    PAPER(16),
    /** The Paper of its own a restart attempt runs on: 1.1 GB, for a fresh world that took 1.3 GB in all. */
    OWN_PAPER(7),
    /** One warm client: 740 MB, where each heap peaked at 540 MB used under a 4 GB cap. */
    CLIENT(4.5),
    /** The pool: 330 MB, where its heap peaked at 130 MB used. */
    POOL(2);

    /**
     * At most this share of the machine for the heaps of the parts that can run at once; the rest is
     * for what each JVM keeps beside its heap, the test JVMs and the Gradle daemon.
     */
    public static final double CONCURRENT_LIMIT = 50;

    /** At most this many own Papers run at once; the pool claims no further restart attempt until one is gone. */
    public static final int OWN_PAPERS = 2;

    /** The share, in percent of the machine's memory. */
    public final double percent;

    HeapShare(double percent) {
        this.percent = percent;
    }

    /** The JVM flag that caps a heap at this share. */
    public String flag() {
        return "-XX:MaxRAMPercentage=" + percent;
    }

    /**
     * The shares of the parts that can run at once: the shared Paper, the {@link #OWN_PAPERS} own
     * Papers of restart attempts, the pool's {@code clients} warm clients and the pool.
     */
    public static double concurrent(int clients) {
        return PAPER.percent + OWN_PAPERS * OWN_PAPER.percent + clients * CLIENT.percent + POOL.percent;
    }

    /**
     * Why a pool of {@code clients} warm clients cannot run, as their heaps with the Papers' and the
     * pool's would take more than {@link #CONCURRENT_LIMIT} of the machine; null when they fit.
     */
    public static String overLimit(int clients) {
        double share = concurrent(clients);
        if (share <= CONCURRENT_LIMIT) return null;
        int fit = (int) Math.floor((CONCURRENT_LIMIT - concurrent(0)) / CLIENT.percent);
        return clients + " clients would take " + share + "% of the machine's memory in heaps with the Papers and the pool, over the "
                + CONCURRENT_LIMIT + "% limit; run at most " + fit + " clients (-Pplaytest.clients)";
    }
}
