package com.typewritermc.playtest.launch;

/**
 * The memory each kind of game part may take, declared once and absolute: where the run enforces
 * limits, the kernel holds the part's process to it and kills the part whole once it takes more. A
 * JVM's heap is a share of its own part's limit; the rest is for what the JVM keeps beside its heap.
 * The starting numbers come from the parts' peaks on a 16 GB CI runner; the peak every run reports
 * against each limit recalibrates them.
 */
public enum PartLimit {
    /** The shared Paper, whose heap peaked at 2.7 GB used. */
    SHARED_PAPER(4608, 56),
    /** The Paper of its own a restart attempt runs on, a fresh world that took 1.3 GB in all. */
    OWN_PAPER(1638, 67),
    /** One warm client, whose heap peaked at 540 MB used beside the game's native memory. */
    CLIENT(1946, 38),
    /** The pool, whose heap peaked at 130 MB used. */
    POOL(512, 64),
    /** A client's virtual display on Linux, which runs no JVM. */
    DISPLAY(256, 0);

    /** At most this many own Papers run at once, each in a slot the build prepares; memory may allow fewer. */
    public static final int OWN_PAPER_SLOTS = 2;

    private static final long MIB = 1024L * 1024;

    /** The memory the part may take, in bytes. */
    public final long limitBytes;

    /** The share of the limit a JVM part's heap may take, in percent; 0 for a part that runs no JVM. */
    public final int heapPercent;

    PartLimit(long limitMib, int heapPercent) {
        this.limitBytes = limitMib * MIB;
        this.heapPercent = heapPercent;
    }

    /** The JVM flag that caps a heap at this kind's share of its limit, in whole MiB. */
    public String heapFlag() {
        return "-Xmx" + limitBytes * heapPercent / 100 / MIB + "m";
    }
}
