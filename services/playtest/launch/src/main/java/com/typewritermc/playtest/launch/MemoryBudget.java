package com.typewritermc.playtest.launch;

import java.lang.management.ManagementFactory;

/**
 * Which game parts fit in a machine of {@code machineMib} at once: the shared Paper, the pool's
 * {@code clients} warm clients, the pool, and as many restart attempts' own Papers as fit beside them,
 * each counted at its expected resident size ({@link PartMemory}), within the machine's memory less
 * {@link #RESERVE_MIB}. The pool claims a restart attempt only while fewer own Papers run than fit, and
 * refuses to run when not even one fits.
 */
public record MemoryBudget(long machineMib, int clients) {
    /**
     * What the machine holds beside the pool's parts, in MiB. When CI's 4x16 runner ran out of memory
     * (run 45115703169, Namespace instance 4p0eqngb8rca8) the kernel's process table held 3161 MiB
     * outside them: the Realm host's JVM 1276, the Gradle daemon 994 and its client 92, the test JVM
     * 161, the rest of the stack 430 (Typewriter's services, NATS, the collector, toxiproxy), the
     * runner 160 and the clients' Xvfb 61; the kernel held 513 MiB more (slab, page tables, stacks).
     * The rest, 166 MiB, keeps a page cache for the code the JVMs run from.
     */
    public static final long RESERVE_MIB = 3840;

    /**
     * The own Paper slots the build sets up, each the identity of an engine of its own in the stack;
     * at most this many own Papers run at once, however much memory the machine has.
     */
    public static final int OWN_PAPER_SLOTS = 4;

    /** The budget of this machine for a pool of {@code clients} clients. */
    public static MemoryBudget ofThisMachine(int clients) {
        var os = (com.sun.management.OperatingSystemMXBean) ManagementFactory.getOperatingSystemMXBean();
        return new MemoryBudget(os.getTotalMemorySize() / (1024 * 1024), clients);
    }

    /** The expected resident size of the parts that can run at once with {@code ownPapers} own Papers, in MiB. */
    public long residentMib(int ownPapers) {
        return PartMemory.PAPER.residentMib(machineMib)
                + clients * PartMemory.CLIENT.residentMib(machineMib)
                + PartMemory.POOL.residentMib(machineMib)
                + ownPapers * PartMemory.OWN_PAPER.residentMib(machineMib);
    }

    /** How many own Papers of restart attempts may run at once: as many as fit, up to {@link #OWN_PAPER_SLOTS}. */
    public int ownPapers() {
        long room = machineMib - RESERVE_MIB - residentMib(0);
        if (room < 0) return 0;
        return (int) Math.min(OWN_PAPER_SLOTS, room / PartMemory.OWN_PAPER.residentMib(machineMib));
    }

    /** Why the pool cannot run on this machine, as not even one own Paper fits beside its clients; null when one fits. */
    public String refusal() {
        if (ownPapers() >= 1) return null;
        long forClients = machineMib - RESERVE_MIB - PartMemory.PAPER.residentMib(machineMib) - PartMemory.POOL.residentMib(machineMib)
                - PartMemory.OWN_PAPER.residentMib(machineMib);
        long fit = Math.max(0, forClients / PartMemory.CLIENT.residentMib(machineMib));
        String parts = clients + " clients with the shared Paper, the pool and one restart Paper would hold " + residentMib(1)
                + " MiB, over the " + (machineMib - RESERVE_MIB) + " MiB this machine of " + machineMib + " MiB has beside its "
                + RESERVE_MIB + " MiB reserve";
        if (fit < 1) return parts + "; the machine is too small for even one client";
        return parts + "; run at most " + fit + " clients (cargo xtask e2e game --clients " + fit + ")";
    }
}
