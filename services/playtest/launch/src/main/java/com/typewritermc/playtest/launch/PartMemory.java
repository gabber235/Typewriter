package com.typewritermc.playtest.launch;

import java.util.ArrayList;
import java.util.List;

/**
 * The memory each kind of game JVM holds: its heap, capped at a share of the machine with
 * {@code -XX:MaxRAMPercentage} so the caps scale with the machine, and what it keeps beside its heap.
 * A Paper's and the pool's memory beside the heap is bounded by flags on the pools that grow with use
 * (direct buffers, class metadata, compiled code); its allowance is what that memory measured. A
 * client's is mostly the software renderer's, which no JVM flag bounds, so its allowance is measured
 * alone. {@link MemoryBudget} counts each part's expected resident size, heap and allowance, against
 * the machine.
 *
 * <p>The allowances come from the kernel's process table when CI's 4x16 runner ran out of memory
 * (run 45115703169, Namespace instance 4p0eqngb8rca8): the shared Paper held 3203 MiB on a 2568 MiB
 * heap cap, the clients 1482 to 1674 MiB on a 722 MiB cap, the pool 448 MiB on a 321 MiB cap.
 */
public enum PartMemory {
    /** The shared Paper: its heap peaked at 2.7 GB used under a 4 GB cap; beside it 635 MiB were resident. */
    PAPER(16, 640, paperCaps()),
    /**
     * The Paper of its own a restart attempt runs on, for a fresh world that took 1.3 GB in all with its
     * heap uncapped. It runs C1 only with the serial collector, so it keeps less beside its heap.
     */
    OWN_PAPER(7, 288, paperCaps()),
    /** One warm client: its heap peaked at 540 MB used; beside it up to 952 MiB were resident. */
    CLIENT(4.5, 960, List.of()),
    /** The pool: its heap peaked at 130 MB used; beside it 127 MiB were resident. */
    POOL(2, 128, List.of("-XX:MaxDirectMemorySize=64m", "-XX:MaxMetaspaceSize=256m", "-XX:ReservedCodeCacheSize=128m"));

    /** The heap cap, in percent of the machine's memory. */
    public final double heapPercent;

    /** What the part is expected to keep resident beside its heap, in MiB. */
    public final long besideHeapMib;

    /** The flags that bound the part's memory beside its heap. */
    public final List<String> besideHeapCaps;

    PartMemory(double heapPercent, long besideHeapMib, List<String> besideHeapCaps) {
        this.heapPercent = heapPercent;
        this.besideHeapMib = besideHeapMib;
        this.besideHeapCaps = besideHeapCaps;
    }

    /**
     * A Paper's bounds beside its heap, each well over its measured share of the 635 MiB the shared
     * Paper kept beside its heap with none set: direct buffers for Netty's few connections, class
     * metadata for Paper with its plugins and agents, and compiled code above the JVM's 240 MB default.
     * Reaching one fails the Paper loudly instead of letting it outgrow the budget.
     */
    private static List<String> paperCaps() {
        return List.of("-XX:MaxDirectMemorySize=256m", "-XX:MaxMetaspaceSize=512m", "-XX:ReservedCodeCacheSize=256m");
    }

    /** The JVM flags that cap this part's memory: its heap share and its bounds beside the heap. */
    public List<String> flags() {
        List<String> flags = new ArrayList<>();
        flags.add("-XX:MaxRAMPercentage=" + heapPercent);
        flags.addAll(besideHeapCaps);
        return flags;
    }

    /** The part's expected resident size on a machine of {@code machineMib}: its heap cap and its allowance beside it. */
    public long residentMib(long machineMib) {
        return (long) Math.ceil(machineMib * heapPercent / 100) + besideHeapMib;
    }
}
