package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import org.bukkit.Material
import org.bukkit.block.Block
import org.bukkit.block.BlockFace
import org.bukkit.block.data.Directional
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockDispenseEvent
import org.bukkit.event.player.PlayerBucketEmptyEvent
import org.bukkit.event.player.PlayerBucketEntityEvent
import org.bukkit.event.player.PlayerBucketFillEvent

@Entry("region_bucket_modifier", "Decide who may empty or fill buckets in a region", Colors.PURPLE, "mdi:bucket")
/**
 * Decides whether the players inside the region may empty or fill buckets: lava, water, milk and
 * powder snow alike.
 *
 * Emptying a bucket is not a block place, and filling one is not a block break, so those two flags
 * never see a bucket: a player denied Block Place could still flood a region with lava. This flag
 * closes that hole. A dispenser emptying a bucket is covered too, since a dispenser just outside
 * the boundary is the easy way around a flag that only watches players. The mob buckets count as
 * buckets here: each one leaves a water source behind. What comes out of them swimming is the mob
 * spawn flag's business, so a region that allows buckets and denies spawning gets the water and no
 * fish.
 *
 * The BLOCK's location decides, not the player's.
 *
 * ## How could this be used?
 *
 * Keep a lava bucket out of a protected build without having to also lock down every block a player
 * might otherwise place.
 */
class BucketModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the players inside the region may empty or fill buckets.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class BucketModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onEmpty(event: PlayerBucketEmptyEvent) {
        if (index.allows(BucketModifierEntry::class, event.block.centerPosition(), event.player)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFill(event: PlayerBucketFillEvent) {
        if (index.allows(BucketModifierEntry::class, event.block.centerPosition(), event.player)) return
        event.isCancelled = true
    }

    /**
     * Scooping a fish, an axolotl or a tadpole is a bucket fill that no block event sees, and
     * the entity is not damaged either, so without this the aquarium of a region that denies
     * every kind of damage can still be carried out one bucket at a time.
     *
     * The ENTITY's location decides, the same way the block does for the other two.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onBucketEntity(event: PlayerBucketEntityEvent) {
        if (index.allows(BucketModifierEntry::class, event.entity.location.toPosition(), event.player)) return
        event.isCancelled = true
    }

    /**
     * A dispenser empties a bucket without ever firing the player events, so a dispenser one
     * block outside a protected region could pour lava into it all day. The dispenser fires
     * with nobody behind it, so only a constant flag can decide.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onDispense(event: BlockDispenseEvent) {
        if (event.item.type !in BUCKETS) return
        // A dropper fires the same event and throws the bucket on the floor rather than emptying
        // it, so denying that is refusing a player the right to drop an item.
        if (event.block.type != Material.DISPENSER) return
        val target = event.block.getRelative(dispenseFace(event.block) ?: return)
        if (index.allows(BucketModifierEntry::class, target.centerPosition(), null)) return
        event.isCancelled = true
    }

    private fun dispenseFace(block: Block): BlockFace? = (block.blockData as? Directional)?.facing

    companion object {
        // The mob buckets belong here as much as the water bucket does: a dispenser empties one
        // the same way, leaving a water source block behind and a fish swimming in it.
        private val BUCKETS = setOf(
            Material.BUCKET,
            Material.WATER_BUCKET,
            Material.LAVA_BUCKET,
            Material.POWDER_SNOW_BUCKET,
            Material.COD_BUCKET,
            Material.SALMON_BUCKET,
            Material.PUFFERFISH_BUCKET,
            Material.TROPICAL_FISH_BUCKET,
            Material.AXOLOTL_BUCKET,
            Material.TADPOLE_BUCKET,
        )
    }
}
