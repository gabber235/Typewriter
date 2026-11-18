package com.typewritermc.playtest.launch;

import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ExecutionException;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.TimeoutException;

/**
 * The game pool's process, as the build that owns it starts and stops it: one pool per build, which
 * runs until the build closes its standard input. The pool ends its run when its input ends, also when
 * the build dies, so no pool outlives the build that started it.
 */
public final class PoolProcess implements AutoCloseable {
    /** The pool's main class. */
    public static final String MAIN = "com.typewritermc.playtest.pool.PoolKt";

    /** How long the pool waits, once its run ended, for its own Papers to exit; a training one assembles its cache meanwhile. */
    public static final long OWN_EXIT_SECONDS = 60;

    /** How long the pool may take to stop its game beyond its own Papers' exits: it asks every part, then forces it. */
    static final long STOP_MARGIN_SECONDS = 30;

    /** How long a pool that started may take to listen; it listens before it boots its game. */
    static final Duration LISTEN = Duration.ofMinutes(1);

    /** How long a killed process may take to end. */
    static final long KILL_SECONDS = 10;

    static final long POLL_MILLIS = 50;

    private final Process process;
    private final Duration exitWithin;

    PoolProcess(Process process, Duration exitWithin) {
        this.process = process;
        this.exitWithin = exitWithin;
    }

    /** The pool's command line: its heap capped at the pool's share, with every {@code playtest.*} property of its build. */
    public static List<String> command(String java, Map<String, String> properties, String classpath) {
        List<String> command = new ArrayList<>(List.of(java, HeapShare.POOL.flag()));
        properties.forEach((key, value) -> command.add("-D" + key + "=" + value));
        command.addAll(List.of("-cp", classpath, MAIN));
        return command;
    }

    /**
     * Starts the pool with {@code command}, its output appended to {@code log}, and returns once it
     * listens for {@code run}, as {@code poolFile} names it, or exited first, or took longer than
     * {@link #LISTEN}. The build's tests then find it through {@code poolFile}, or no pool of their run.
     */
    public static PoolProcess start(List<String> command, Path log, Path poolFile, String run) throws IOException, InterruptedException {
        Files.createDirectories(log.toAbsolutePath().getParent());
        Files.createDirectories(poolFile.toAbsolutePath().getParent());
        Process process = new ProcessBuilder(command)
                .redirectErrorStream(true)
                .redirectOutput(ProcessBuilder.Redirect.appendTo(log.toFile()))
                .start();
        long deadline = System.nanoTime() + LISTEN.toNanos();
        while (process.isAlive() && System.nanoTime() < deadline && !listens(poolFile, run, process)) Thread.sleep(POLL_MILLIS);
        return new PoolProcess(process, Duration.ofSeconds(OWN_EXIT_SECONDS + STOP_MARGIN_SECONDS));
    }

    /** Whether {@code poolFile} names {@code process} as listening for {@code run}. */
    private static boolean listens(Path poolFile, String run, Process process) throws IOException {
        return PoolFile.read(poolFile).filter(pool -> pool.run().equals(run) && pool.process().pid() == process.pid()).isPresent();
    }

    /** The pool's process id. */
    public long pid() {
        return process.pid();
    }

    /**
     * Ends the pool's run: closes its input and waits for it to stop its game and exit. A pool still
     * running once its time to exit is over is killed with every process it started.
     */
    @Override
    public void close() throws IOException, InterruptedException {
        process.getOutputStream().close();
        if (process.waitFor(exitWithin.toMillis(), TimeUnit.MILLISECONDS)) return;
        List<ProcessHandle> all = new ArrayList<>(process.descendants().toList());
        all.add(0, process.toHandle());
        System.err.println("The game pool " + process.pid() + " still runs " + exitWithin.toSeconds() + " s after its input closed; killing it and its game");
        all.forEach(ProcessHandle::destroyForcibly);
        for (ProcessHandle handle : all) {
            try {
                handle.onExit().get(KILL_SECONDS, TimeUnit.SECONDS);
            } catch (TimeoutException | ExecutionException stillRuns) {
                throw new IOException("the game pool " + process.pid() + " still runs process " + handle.pid() + " " + KILL_SECONDS + " s after it was killed", stillRuns);
            }
        }
    }
}
