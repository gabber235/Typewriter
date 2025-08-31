package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.entry.triggerEntriesFor
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.entity.EntityType
import org.bukkit.entity.Player
import org.bukkit.event.entity.ProjectileHitEvent
import java.util.*
import kotlin.reflect.KClass

@Entry(
    "player_projectile_hit_entity_event",
    "Triggers when a player's projectile hits an entity",
    Colors.YELLOW,
    "mdi:target-account"
)
@ContextKeys(PlayerProjectileHitEntityContextKeys::class)
/**
 * The `Player Projectile Hit Entity Event` is triggered when a player's projectile hits an entity.
 *
 * ## How could this be used?
 * This could be used to make a hit sound play when the player hits an entity.
 */
class PlayerProjectileHitEntityEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Triggers to run on a player getting hit by the projectile")
    val targetTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    val projectileType: Optional<EntityType> = Optional.empty(),
    val hitEntityType: Optional<EntityType> = Optional.empty(),
    val itemInHand: Optional<Item> = Optional.empty(),
    val holdingHand: HoldingHand = HoldingHand.BOTH,
) : EventEntry

enum class PlayerProjectileHitEntityContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(EntityType::class)
    PROJECTILE_TYPE(EntityType::class),

    @KeyType(EntityType::class)
    HIT_ENTITY_TYPE(EntityType::class),

    @KeyType(Position::class)
    ENTITY_POSITION(Position::class),

    @KeyType(Position::class)
    PROJECTILE_POSITION(Position::class)
}

@EntryListener(PlayerProjectileHitEntityEventEntry::class)
fun onPlayerProjectileHitEntity(event: ProjectileHitEvent, query: Query<PlayerProjectileHitEntityEventEntry>) {
    val shooter = event.entity.shooter
    if (shooter !is Player) return
    val hitEntity = event.hitEntity ?: return

    val entries = query.findWhere { entry ->
        if (entry.projectileType.isPresent && entry.projectileType.get() != event.entityType) return@findWhere false
        if (entry.hitEntityType.isPresent && entry.hitEntityType.get() != hitEntity.type) return@findWhere false
        if (entry.itemInHand.isPresent && hasItemInHand(
                shooter,
                entry.holdingHand,
                entry.itemInHand.get()
            )
        ) return@findWhere false
        true
    }.toList()

    entries.triggerAllFor(shooter) {
        PlayerProjectileHitEntityContextKeys.PROJECTILE_TYPE += event.entityType
        PlayerProjectileHitEntityContextKeys.HIT_ENTITY_TYPE += hitEntity.type
        PlayerProjectileHitEntityContextKeys.ENTITY_POSITION += hitEntity.location.toPosition()
        PlayerProjectileHitEntityContextKeys.PROJECTILE_POSITION += event.entity.location.toPosition()
    }
    if (hitEntity !is Player) return
    entries.flatMap { it.targetTriggers }.triggerEntriesFor(hitEntity) {
        PlayerProjectileHitEntityContextKeys.PROJECTILE_TYPE += event.entityType
        PlayerProjectileHitEntityContextKeys.HIT_ENTITY_TYPE += hitEntity.type
        PlayerProjectileHitEntityContextKeys.ENTITY_POSITION += hitEntity.location.toPosition()
        PlayerProjectileHitEntityContextKeys.PROJECTILE_POSITION += event.entity.location.toPosition()
    }
}