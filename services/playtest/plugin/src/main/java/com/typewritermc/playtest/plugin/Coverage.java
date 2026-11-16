package com.typewritermc.playtest.plugin;

import java.util.LinkedHashSet;
import java.util.List;
import java.util.Set;
import java.util.function.Consumer;
import java.util.function.Supplier;

/**
 * Which attempts the plugin code that ran belongs to. JaCoCo counts every line of the plugin classes
 * that any thread runs, for the whole Paper at once, so this reads and resets its counts whenever an
 * attempt starts and whenever one settles, and hands each read to every attempt that held players since
 * the read before. Code that ran while no attempt held players counts for none. An attempt that runs
 * alone gets exactly its own lines; attempts that overlap on the shared Paper each get the lines of
 * the others that ran while they overlapped too. Main thread only.
 */
public final class Coverage {
    /** What JaCoCo counted since the read before, in its execution data format, for {@code attempts}; the read took {@code nanos}. */
    public record Read(List<Long> attempts, long nanos, byte[] exec) {}

    private final Supplier<byte[]> readAndReset;
    private final Consumer<Read> send;
    private final Set<Long> running = new LinkedHashSet<>();
    private final Set<Long> since = new LinkedHashSet<>();

    /** Reads JaCoCo's counts with {@code readAndReset}, which zeroes them, and hands each read on to {@code send}. */
    Coverage(Supplier<byte[]> readAndReset, Consumer<Read> send) {
        this.readAndReset = readAndReset;
        this.send = send;
    }

    /** The attempt holds its players from now on: what ran before it counts for the attempts already running. */
    void started(long attempt) {
        read();
        running.add(attempt);
        since.add(attempt);
    }

    /** The attempt's work is quiet: what ran until now counts for it and the attempts beside it, and nothing later does. */
    void settled(long attempt) {
        read();
        running.remove(attempt);
        since.remove(attempt);
    }

    /** The attempt ended without settling, as one whose session left does: nothing later counts for it. */
    void ended(long attempt) {
        // What ran since the last read may still be its own, so it keeps its place in that read.
        running.remove(attempt);
    }

    /** Hands what ran since the read before to every attempt that held players meanwhile; from now on only the running ones do. */
    private void read() {
        long start = System.nanoTime();
        byte[] exec = readAndReset.get();
        long nanos = System.nanoTime() - start;
        if (!since.isEmpty()) send.accept(new Read(List.copyOf(since), nanos, exec));
        since.clear();
        since.addAll(running);
    }
}
