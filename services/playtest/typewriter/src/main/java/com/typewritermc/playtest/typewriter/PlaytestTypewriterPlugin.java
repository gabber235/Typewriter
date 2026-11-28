package com.typewritermc.playtest.typewriter;

import com.typewritermc.loader.api.work.InFlightWork;
import com.typewritermc.loader.api.work.WorkItem;
import com.typewritermc.loader.api.work.WorkObserver;
import com.typewritermc.playtest.plugin.PlayerWork;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * Counts every item of the work in flight in Typewriter's engines on this Paper as {@link PlayerWork} of
 * the players it is for, so a tick waits until the work a tick caused ended, and failed work fails the
 * attempts of its players. Work for no subject in particular counts for every claimed player; work only
 * for subjects that are no Minecraft player counts for none.
 */
public final class PlaytestTypewriterPlugin extends JavaPlugin {
    private AutoCloseable observing;

    @Override
    public void onEnable() {
        InFlightWork work = getServer().getServicesManager().load(InFlightWork.class);
        if (work == null) throw new IllegalStateException("The Typewriter plugin registered no InFlightWork service.");
        observing = work.observe(new Counting());
    }

    @Override
    public void onDisable() {
        try {
            if (observing != null) observing.close();
        } catch (Exception failure) {
            throw new IllegalStateException("Typewriter's in flight work could not stop being observed.", failure);
        }
    }

    /** Begins and ends the counted work of each item, on the thread that begins or ends the item. */
    private static final class Counting implements WorkObserver {
        private final Map<WorkItem, PlayerWork> counted = new ConcurrentHashMap<>();

        @Override
        public void began(WorkItem item) {
            Set<UUID> players = WorkPlayers.of(item.getSubjects());
            if (players == null) counted.put(item, PlayerWork.server(item.getName()));
            else if (!players.isEmpty()) counted.put(item, PlayerWork.begin(players, item.getName()));
        }

        @Override
        public void ended(WorkItem item, Throwable failure) {
            PlayerWork work = counted.remove(item);
            if (work == null) return;
            if (failure == null) work.end();
            else work.failed(failure);
        }
    }
}
