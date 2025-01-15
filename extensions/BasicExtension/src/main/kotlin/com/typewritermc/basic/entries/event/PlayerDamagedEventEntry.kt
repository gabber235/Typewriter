package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.withContext
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.entry.triggerEntriesFor
import org.bukkit.entity.Player
import org.bukkit.event.entity.EntityDamageEvent
import java.util.Optional
import kotlin.reflect.KClass

@Entry("player_damaged_event", "When a player gets damaged", Colors.YELLOW, "material-symbols:heart-broken")
@ContextKeys(PlayerDamagedEventContextKeys::class)
/**
 * The `Player Damaged Event` is triggered when a player gets damaged.
 * If the player gets damaged by another player, different triggers may activate.
 *
 * ## How could this be used?
 * This could be used for combat mechanics, where if you hit a player they get flown in the air.
 */
class PlayerDamagedEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val cause: Optional<EntityDamageEvent.DamageCause> = Optional.empty(),
    val damagerTriggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

enum class PlayerDamagedEventContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Double::class)
    DAMAGE(Double::class),
}

@EntryListener(PlayerDamagedEventEntry::class)
fun onPlayerDamaged(event: EntityDamageEvent, query: Query<PlayerDamagedEventEntry>) {
    val player = event.entity as? Player ?: return

    val entries = query.findWhere { !it.cause.isPresent || it.cause.get() == event.cause }.toList()
    val context = entries.withContext {
        PlayerDamagedEventContextKeys.DAMAGE withValue event.finalDamage
    }
    entries.triggerAllFor(player, context)

    val damager = event.damageSource.causingEntity as? Player
    if (damager != null) {
        entries.flatMap { it.damagerTriggers }.triggerEntriesFor(damager, context)
        return
    }
}