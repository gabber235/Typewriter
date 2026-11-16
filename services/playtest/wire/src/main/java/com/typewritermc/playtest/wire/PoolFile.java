package com.typewritermc.playtest.wire;

import java.io.IOException;
import java.io.Reader;
import java.io.StringReader;
import java.nio.file.Files;
import java.nio.file.NoSuchFileException;
import java.nio.file.Path;
import java.nio.file.StandardCopyOption;
import java.time.Instant;
import java.util.Optional;
import java.util.Properties;

/**
 * What a running game pool leaves in its folder so test JVMs find it: the loopback {@code port} it
 * listens on, the {@code run} it serves, and its process, named by its {@code pid} and the moment it
 * started ({@code startedMillis}), so a pid the system later gives another process never passes for
 * the pool. The pool writes it once it listens and removes it as it exits.
 */
public record PoolFile(int port, String run, long pid, long startedMillis) {
    /** The file's name in the pool folder. */
    public static final String NAME = "pool.running";

    /** The file of this process, a pool that listens on {@code port} for {@code run}. */
    public static PoolFile of(int port, String run) {
        return of(port, run, ProcessHandle.current());
    }

    /** The file of {@code process}, a pool that listens on {@code port} for {@code run}. */
    public static PoolFile of(int port, String run, ProcessHandle process) {
        return new PoolFile(port, run, process.pid(), startedMillis(process));
    }

    /** Writes the file to {@code file} at once: a reader sees the whole file or none. */
    public void write(Path file) throws IOException {
        Path partial = file.resolveSibling(file.getFileName() + ".partial");
        Files.writeString(partial, "port=" + port + "\nrun=" + run + "\npid=" + pid + "\nstarted=" + startedMillis + "\n");
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
    }

    /** The file at {@code file}, or empty when there is none or it is not a pool file. */
    public static Optional<PoolFile> read(Path file) throws IOException {
        String text;
        try {
            text = Files.readString(file);
        } catch (NoSuchFileException gone) {
            return Optional.empty();
        }
        Properties keys = new Properties();
        try (Reader reader = new StringReader(text)) {
            keys.load(reader);
        }
        try {
            return Optional.of(new PoolFile(
                    Integer.parseInt(keys.getProperty("port")),
                    Optional.ofNullable(keys.getProperty("run")).orElseThrow(),
                    Long.parseLong(keys.getProperty("pid")),
                    Long.parseLong(keys.getProperty("started"))));
        } catch (RuntimeException garbled) {
            return Optional.empty();
        }
    }

    /** The pool's process while it still runs; empty once it ended, even when another process took its pid. */
    public Optional<ProcessHandle> process() {
        return ProcessHandle.of(pid).filter(ProcessHandle::isAlive).filter(it -> startedMillis(it) == startedMillis);
    }

    private static long startedMillis(ProcessHandle process) {
        return process.info().startInstant().map(Instant::toEpochMilli).orElse(0L);
    }
}
