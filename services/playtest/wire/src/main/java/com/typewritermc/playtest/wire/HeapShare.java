package com.typewritermc.playtest.wire;

/**
 * The share of the machine's memory each kind of game JVM may take for its heap, as
 * {@code -XX:MaxRAMPercentage}, so the caps scale with the machine: without one every JVM may grow to
 * a quarter of it, and the parts that run at once outgrew a 16 GB CI runner. The pool starts every
 * part with its kind's share, and the test JVM starts the pool with the pool's.
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
     * The shares of the parts that can run at once: the shared Paper, the own Papers of two restart
     * attempts, four clients and the pool.
     */
    public static double concurrent() {
        return PAPER.percent + 2 * OWN_PAPER.percent + 4 * CLIENT.percent + POOL.percent;
    }
}
