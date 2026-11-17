package com.typewritermc.playtest.wire;

import java.io.IOException;
import java.nio.file.Path;
import java.util.Optional;

/**
 * What a running game pool leaves in its folder so test JVMs find it: the loopback {@code port} it
 * listens on, the {@code run} it serves, and its {@code process}, so a pool that ended, or a pid the
 * system later gives another process, never passes for the pool. The pool writes it once it listens
 * and removes it as it exits.
 */
public record PoolFile(int port, String run, PartFile process) {
    /** The file's name in the pool folder. */
    public static final String NAME = "pool.running";

    /** The file of this process, a pool that listens on {@code port} for {@code run}. */
    public static PoolFile of(int port, String run) {
        return of(port, run, ProcessHandle.current());
    }

    /** The file of {@code process}, a pool that listens on {@code port} for {@code run}. */
    public static PoolFile of(int port, String run, ProcessHandle process) {
        return new PoolFile(port, run, PartFile.of(process));
    }

    /** Writes the file to {@code file} at once: a reader sees the whole file or none. */
    public void write(Path file) throws IOException {
        PartFile.writeKeys(file, "port=" + port + "\nrun=" + run + "\n" + process.keys());
    }

    /** The file at {@code file}, or empty when there is none or it is not a pool file. */
    public static Optional<PoolFile> read(Path file) throws IOException {
        return PartFile.readKeys(file).flatMap(keys -> {
            String run = keys.getProperty("run");
            Optional<PartFile> process = PartFile.from(keys);
            try {
                int port = Integer.parseInt(keys.getProperty("port"));
                return run == null || process.isEmpty() ? Optional.empty() : Optional.of(new PoolFile(port, run, process.get()));
            } catch (NumberFormatException garbled) {
                return Optional.empty();
            }
        });
    }
}
