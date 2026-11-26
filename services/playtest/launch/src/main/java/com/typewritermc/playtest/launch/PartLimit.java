package com.typewritermc.playtest.launch;

/**
 * The memory each kind of game part may take, declared once and absolute: where the run enforces
 * limits, the kernel holds the part's process to it and kills the part whole once it takes more. A
 * JVM's heap is a share of its own part's limit; the rest is for what the JVM keeps beside its heap.
 * Each limit is the most a part of its kind took on the 16 GB CI runner (CI runs 45575711222 and
 * 45595894285, page cache included) plus 15%, at least 64 MiB; each heap kept the size it ran those
 * peaks with. The peak every run reports against each limit recalibrates them.
 */
public enum PartLimit {
    /** The shared Paper, which took 3395 MiB on the playtest suite. */
    SHARED_PAPER(3904, 66),
    /** The Paper of its own a restart attempt runs on, which took 2081 MiB while it trained its cache. */
    OWN_PAPER(2393, 46),
    /** One warm client, which took 1543 MiB recording clips for a demo run. */
    CLIENT(1775, 42),
    /** The pool, which took 706 MiB. */
    POOL(812, 40),
    /**
     * A client's virtual display on Linux, which runs no JVM and took 15 MiB; held to 64 MiB, the least any
     * part is held to, since a limit that close to a small peak kills it for noise.
     */
    DISPLAY(64, 0);

    /**
     * The build prepares this many own Paper slots, each with what the suite's Paper needs of it; as many
     * own Papers run at once as fit in the game's memory, at most one per slot.
     */
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
