package com.typewritermc.playtest.plugin;

import java.util.ArrayList;
import java.util.Collection;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletionStage;
import java.util.concurrent.ConcurrentHashMap;
import org.bukkit.entity.Player;

/**
 * Work a plugin does for a player that the game's ticks wait for: a lookup, a save, anything that runs
 * off the main thread and later changes what the player perceives. On a Paper the game pool steps, the
 * next tick waits until the player's counted work ended, so the work takes no ticks from a
 * requirement's windows; a task handed to Bukkit's async scheduler lets the next tick start, whose
 * heartbeat starts it, and holds the one after. Work that still runs 1 s after it began fails the
 * player's attempt with its name; it is never cancelled, and it holds no tick from then on.
 *
 * <p>Work that ends without its effect, such as an outbound operation that failed, ends with
 * {@link #failed} and fails the attempt of each of its players. Work for a player who is away counts
 * until its attempt releases the player.
 *
 * <p>Count work that already runs with {@link #begin} and {@link #end}, or around a future with
 * {@link #around}, or around a task handed to Bukkit's async scheduler with {@link #task}. Any thread may count work. Every piece of
 * work a plugin starts for a player must be counted, or a check may run before its effect.
 */
public final class PlayerWork implements AutoCloseable {
    static final WorkLedger LEDGER = new WorkLedger(WorkLedger.deadlineThread());

    // The holds of the facts attempts expect, by fact, until a plugin reports it.
    private static final Map<String, List<PlayerWork>> EXPECTED = new ConcurrentHashMap<>();

    private final WorkLedger.Entry entry;

    private PlayerWork(WorkLedger.Entry entry) {
        this.entry = entry;
    }

    /** [player]'s work [name] begins now and counts until {@link #end}. */
    public static PlayerWork begin(Player player, String name) {
        return new PlayerWork(LEDGER.begin(Set.of(player.getUniqueId()), name));
    }

    /**
     * The work [name] of the players of [players], online or away, begins now and counts until
     * {@link #end} or {@link #failed}.
     */
    public static PlayerWork begin(Collection<UUID> players, String name) {
        return new PlayerWork(LEDGER.begin(Set.copyOf(players), name));
    }

    /**
     * Work [name] for no player in particular begins now: it counts for every claimed player until
     * {@link #end} or {@link #failed}.
     */
    public static PlayerWork server(String name) {
        return new PlayerWork(LEDGER.begin(null, name));
    }

    /** [player]'s work [name] counts until [work] completes, either way; returns [work]. */
    public static <T, S extends CompletionStage<T>> S around(Player player, String name, S work) {
        PlayerWork counted = begin(player, name);
        work.whenComplete((result, failure) -> counted.end());
        return work;
    }

    /**
     * [player]'s work [name] counts from now until [task] returns or throws; hand the returned task to
     * Bukkit's async scheduler, which starts it at the next tick's heartbeat.
     */
    public static Runnable task(Player player, String name, Runnable task) {
        return task(Set.of(player.getUniqueId()), name, task);
    }

    /**
     * The work [name] of the players of [players], online or away, counts from now until [task] returns
     * or throws; hand the returned task to Bukkit's async scheduler, which starts it at the next tick's
     * heartbeat.
     */
    public static Runnable task(Collection<UUID> players, String name, Runnable task) {
        PlayerWork counted = new PlayerWork(LEDGER.schedule(Set.copyOf(players), name));
        return () -> {
            try {
                task.run();
            } finally {
                counted.end();
            }
        };
    }

    /**
     * The attempt of [players] is about to cause a change outside Paper whose effect reaches Paper as
     * [fact]: their ticks wait from now until a plugin reports it with {@link #factHappened}. A fact no
     * plugin reports 1 s later is hung work named "expected fact" and the fact.
     */
    static void expect(Collection<UUID> players, String fact) {
        PlayerWork hold = begin(players, "expected fact " + fact);
        EXPECTED.compute(fact, (key, holds) -> {
            List<PlayerWork> waiting = holds != null ? holds : new ArrayList<>();
            waiting.add(hold);
            return waiting;
        });
    }

    /**
     * A change from outside Paper took effect here as [fact], such as content a plugin applied: every
     * attempt that expects it stops waiting for it. A fact no attempt expects changes nothing. Any thread.
     */
    public static void factHappened(String fact) {
        List<PlayerWork> waiting = EXPECTED.remove(fact);
        if (waiting != null) waiting.forEach(PlayerWork::end);
    }

    /** The work is done; ending it again does nothing. */
    public void end() {
        entry.end();
    }

    /**
     * The work ended without its effect because of [cause], such as an outbound operation that failed:
     * the attempt of each of its players fails naming it, unless it already hung. Ending it again does
     * nothing.
     */
    public void failed(Throwable cause) {
        String message = cause.getMessage();
        entry.failed(message != null ? message : cause.getClass().getSimpleName());
    }

    /** Ends the work, so a try with resources block counts what runs inside it. */
    @Override
    public void close() {
        end();
    }
}
