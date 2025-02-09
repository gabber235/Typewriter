package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.toBlockPosition
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CancelableEventEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.shouldCancel
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.toPosition
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.event.player.PlayerMoveEvent
import java.util.*
import kotlin.jvm.optionals.getOrNull
import kotlin.reflect.KClass

@Entry(
    "stand_on_block_event",
    "Triggered when a player stands on a block",
    Colors.YELLOW,
    "material-symbols:lightning-stand"
)
@ContextKeys(StandOnBlockContextKeys::class)
/**
 * The `Stand On Block Event` is triggered when a player stands on a block.
 *
 * ## How could this be used?
 * This could be used to send a player flying when the stand on a netherite block.
 */
class StandOnBlockEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val block: Optional<Var<Material>> = Optional.empty(),
    val position: Optional<Var<Position>> = Optional.empty(),
    override val cancel: Var<Boolean> = ConstVar(false),
) : CancelableEventEntry

enum class StandOnBlockContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Position::class)
    PLAYER_POSITION(Position::class),

    @KeyType(Position::class)
    BLOCK_POSITION(Position::class),

    @KeyType(Material::class)
    BLOCK_MATERIAL(Material::class),
}

fun hasBlock(location: Location, block: Material): Boolean {
    return blockLocation(location, block) != null
}

fun blockLocation(location: Location, block: Material): Location? {
    val loc = location.clone()
    if (loc.block.type == block) return location
    loc.add(0.0, 1.0, 0.0)
    if (loc.block.type == block) return loc
    // We want the block below the player, as we are now at the head of the player, 2 down
    loc.add(0.0, -2.0, 0.0)
    if (loc.block.type == block) return loc
    return null
}

@EntryListener(StandOnBlockEventEntry::class)
fun onStandOnBlock(event: PlayerMoveEvent, query: Query<StandOnBlockEventEntry>) {
    if (!event.hasChangedBlock()) return
    val player = event.player
    val from = event.from
    val to = event.to
    val entries = query.findWhere {
        if (it.block.isPresent) {
            val block = it.block.get().get(player, context())
            if (!(!hasBlock(from, block) && hasBlock(to, block))) return@findWhere false
        }
        if (it.position.isPresent) {
            val position = it.position.get().get(player, context())
            if (!(!position.sameBlock(from.toPosition()) && position.sameBlock(to.toPosition()))) return@findWhere false
        }
        true
    }.toList()

    entries.triggerAllFor(event.player) {
        StandOnBlockContextKeys.PLAYER_POSITION += to.toPosition()

        val blockType = entry.block.getOrNull()?.get(player, context())
        if (blockType != null) {
            StandOnBlockContextKeys.BLOCK_MATERIAL += blockType
            StandOnBlockContextKeys.BLOCK_POSITION += blockLocation(
                to,
                blockType
            )?.toPosition()?.toBlockPosition() ?: to.toPosition().toBlockPosition()
        } else if (to.block.type != Material.AIR) {
            StandOnBlockContextKeys.BLOCK_MATERIAL += to.block.type
            StandOnBlockContextKeys.BLOCK_POSITION += to.toPosition().toBlockPosition()
        } else {
            val blockBelow = to.clone().add(0.0, -1.0, 0.0)
            StandOnBlockContextKeys.BLOCK_MATERIAL += blockBelow.block.type
            StandOnBlockContextKeys.BLOCK_POSITION += blockBelow.toPosition().toBlockPosition()
        }
    }

    if (entries.shouldCancel(player)) event.isCancelled = true
}