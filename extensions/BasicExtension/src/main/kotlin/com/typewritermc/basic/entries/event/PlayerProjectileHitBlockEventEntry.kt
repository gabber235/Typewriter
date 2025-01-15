package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.toBlockPosition
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.Material
import org.bukkit.entity.EntityType
import org.bukkit.entity.Player
import org.bukkit.event.entity.ProjectileHitEvent
import java.util.*

@Entry(
    "player_projectile_hit_block_event",
    "Triggers when a player's projectile hits a block",
    Colors.YELLOW,
    "tabler:target-arrow"
)
/**
 * The `Player Projectile Hit Block Event` is triggered when a player's projectile hits a block.
 *
 * ## How could this be used?
 * This could be used to make a quest where the player needs to hit all targets.
 */
class PlayerProjectileHitBlockEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val projectileType: Optional<EntityType> = Optional.empty(),
    val hitBlockType: Optional<Material> = Optional.empty(),
    val blockPosition: Optional<Position> = Optional.empty(),
    val itemInHand: Optional<Item> = Optional.empty(),
    val holdingHand: HoldingHand = HoldingHand.BOTH,
) : EventEntry

@EntryListener(PlayerProjectileHitBlockEventEntry::class)
fun onPlayerProjectileHitBlock(event: ProjectileHitEvent, query: Query<PlayerProjectileHitBlockEventEntry>) {
    val shooter = event.entity.shooter
    if (shooter !is Player) return
    val hitBlock = event.hitBlock ?: return

    query.findWhere { entry ->
        if (entry.projectileType.isPresent && entry.projectileType.get() != event.entityType) return@findWhere false

        if (entry.hitBlockType.isPresent && entry.hitBlockType.get() != hitBlock.type) return@findWhere false
        if (entry.blockPosition.isPresent && entry.blockPosition.get()
                .toBlockPosition() != hitBlock.location.toPosition().toBlockPosition()
        ) return@findWhere false

        if (entry.itemInHand.isPresent && !hasItemInHand(
                shooter,
                entry.holdingHand,
                entry.itemInHand.get()
            )
        ) return@findWhere false
        true
    }.triggerAllFor(shooter, context())
}