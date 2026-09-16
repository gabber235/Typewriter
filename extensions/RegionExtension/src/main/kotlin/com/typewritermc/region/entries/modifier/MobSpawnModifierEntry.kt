package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.entity.CreatureSpawnEvent

@Entry("region_mob_spawn_modifier", "Decide whether mobs may spawn in a region", Colors.PURPLE, "mdi:spider-web")
/**
 * Decides whether mobs may spawn inside the region. Every spawn reason counts: natural spawns,
 * spawners, breeding, spawn eggs and the rest.
 *
 * A mob placed by a command is the one exception, since that is somebody with operator rights
 * asking for it on purpose.
 *
 * The spawn LOCATION decides, so a mob wandering in from outside is untouched. This stops them
 * appearing, not entering.
 *
 * No player is behind a natural spawn, so this flag cannot apply to a region whose placement follows
 * a variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Keep a hub free of monsters without lighting every corner of it.
 */
class MobSpawnModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether mobs may spawn inside the region. Only /summon is always allowed.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

/**
 * Spawns an operator asked for on purpose.
 *
 * Only the command. A spawn egg is obtainable from any creative player, a kit or a shop, so
 * exempting it hands every one of them a way through the flag. `CUSTOM` is what CraftBukkit
 * stamps on any plugin's `World.spawn`, which is a whole category, not a deliberate act by the
 * owner. Typewriter's own NPCs are packet entities and never reach this event at all.
 */
private val DELIBERATE_SPAWNS = setOf(
    CreatureSpawnEvent.SpawnReason.COMMAND,
)

class MobSpawnModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onSpawn(event: CreatureSpawnEvent) {
        if (event.spawnReason in DELIBERATE_SPAWNS) return
        val flag = index.resolve(
            MobSpawnModifierEntry::class,
            event.location.toPosition(),
            null,
        ) ?: return
        if (flag.allowed) return
        event.isCancelled = true
    }
}
