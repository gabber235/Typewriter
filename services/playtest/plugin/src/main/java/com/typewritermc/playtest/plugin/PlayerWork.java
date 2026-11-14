package com.typewritermc.playtest.plugin;

import java.util.concurrent.CompletionStage;
import org.bukkit.entity.Player;

/**
 * Work a plugin does for a player that the game's ticks wait for: a lookup, a save, anything that runs
 * off the main thread and later changes what the player perceives. On a Paper the game pool steps, the
 * tick after the next one waits until the player's counted work ended, so the work takes no ticks from
 * a requirement's windows. Work that still runs 1 s after it began fails the player's attempt with its
 * name; it is never cancelled, and it holds no tick from then on.
 *
 * <p>Count work with {@link #begin} and {@link #end}, or around a future with {@link #around}, or
 * around a task handed to a scheduler with {@link #task}. Any thread may count work. Every piece of
 * work a plugin starts for a player must be counted, or a check may run before its effect.
 */
public final class PlayerWork implements AutoCloseable {
    static final WorkLedger LEDGER = new WorkLedger(System::nanoTime);

    private final WorkLedger.Entry entry;

    private PlayerWork(WorkLedger.Entry entry) {
        this.entry = entry;
    }

    /** [player]'s work [name] begins now and counts until {@link #end}. */
    public static PlayerWork begin(Player player, String name) {
        return new PlayerWork(LEDGER.begin(player.getUniqueId(), player.getName(), name));
    }

    /** [player]'s work [name] counts until [work] completes, either way; returns [work]. */
    public static <T, S extends CompletionStage<T>> S around(Player player, String name, S work) {
        PlayerWork counted = begin(player, name);
        work.whenComplete((result, failure) -> counted.end());
        return work;
    }

    /**
     * [player]'s work [name] counts from now until [task] returns or throws; hand the returned task to
     * any scheduler, such as Bukkit's async scheduler.
     */
    public static Runnable task(Player player, String name, Runnable task) {
        PlayerWork counted = begin(player, name);
        return () -> {
            try {
                task.run();
            } finally {
                counted.end();
            }
        };
    }

    /** The work is done; ending it again does nothing. */
    public void end() {
        entry.end();
    }

    /** Ends the work, so a try with resources block counts what runs inside it. */
    @Override
    public void close() {
        end();
    }
}
