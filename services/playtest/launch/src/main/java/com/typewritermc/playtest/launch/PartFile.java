package com.typewritermc.playtest.launch;

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
 * A process of the game, named by its {@code pid} and the moment it started ({@code startedMillis}), as
 * a file in its folder: the pool writes one into each part's folder (Paper's, each client's) at every
 * boot, so tests find a part's process without reading command lines, which Linux cuts off after one
 * page. A file a crash left behind names no process, because a pid the system later gives another
 * process started at another moment.
 */
public record PartFile(long pid, long startedMillis) {
    /** The file's name in a part's folder. */
    public static final String NAME = "part.running";

    /** The file of {@code process}. */
    public static PartFile of(ProcessHandle process) {
        return new PartFile(process.pid(), process.info().startInstant().map(Instant::toEpochMilli).orElse(0L));
    }

    /** Writes the file to {@code file} at once: a reader sees the whole file or none. */
    public void write(Path file) throws IOException {
        writeKeys(file, keys());
    }

    /** The file at {@code file}, or empty when there is none or it is not a part file. */
    public static Optional<PartFile> read(Path file) throws IOException {
        return readKeys(file).flatMap(PartFile::from);
    }

    /** The process while it still runs; empty once it ended, even when another process took its pid. */
    public Optional<ProcessHandle> running() {
        return ProcessHandle.of(pid).filter(ProcessHandle::isAlive).filter(it -> of(it).equals(this));
    }

    /** The file's keys, one {@code key=value} line each. */
    String keys() {
        return "pid=" + pid + "\nstarted=" + startedMillis + "\n";
    }

    /** The part file the keys of {@code keys} name, or empty when they name none. */
    static Optional<PartFile> from(Properties keys) {
        try {
            return Optional.of(new PartFile(Long.parseLong(keys.getProperty("pid")), Long.parseLong(keys.getProperty("started"))));
        } catch (RuntimeException garbled) {
            return Optional.empty();
        }
    }

    /** Writes {@code keys} to {@code file} through a sibling file moved into place, so no reader sees half. */
    static void writeKeys(Path file, String keys) throws IOException {
        Path partial = file.resolveSibling(file.getFileName() + ".partial");
        Files.writeString(partial, keys);
        Files.move(partial, file, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE);
    }

    /** The keys in {@code file}, or empty when there is no such file. */
    static Optional<Properties> readKeys(Path file) throws IOException {
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
        return Optional.of(keys);
    }
}
