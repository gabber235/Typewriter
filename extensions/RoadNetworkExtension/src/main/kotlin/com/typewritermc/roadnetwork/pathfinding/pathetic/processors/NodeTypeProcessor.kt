package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.roadnetwork.content.debug.DebugRecorderSupplier
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugEvent
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugRecorder
import com.typewritermc.roadnetwork.pathfinding.pathetic.properties.PathNodeProperty
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.pathing.processing.context.SearchContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import it.unimi.dsi.fastutil.longs.Long2ObjectMap
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import it.unimi.dsi.fastutil.objects.ObjectSet
import org.bukkit.Material
import org.bukkit.Tag
import org.bukkit.block.Block
import org.bukkit.block.data.Openable
import org.bukkit.block.data.type.Door
import org.bukkit.block.data.type.Gate
import org.bukkit.block.data.type.TrapDoor

/**
 * A stateless and thread-safe node processor.
 *
 * Analyzes block properties and determines if nodes are passable based on
 * entity capabilities. Uses a per-request cache for performance.
 *
 * This validator must be placed first in the validation chain.
 */
class NodeTypeProcessor(private val capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT) :
    ValidationProcessor {

    companion object {
        private val CACHE_KEY = NodeTypeProcessor::class.java.packageName + ".propertyCache"

        /**
         * Gets the cached properties for a given node from the current search.
         *
         * @param context The active search context.
         * @param position The position of the node.
         * @return The cached properties, or `null` if the node has not been processed yet.
         */
        fun cachedProperties(context: EvaluationContext, position: PathPosition): ObjectSet<PathNodeProperty>? {
            val cache = cache(context)
            val packedPos = pack(position.flooredX, position.flooredY, position.flooredZ)
            return cache[packedPos]
        }

        @Suppress("UNCHECKED_CAST") // Cache is initialized with correct type in initializeSearch()
        private fun cache(context: EvaluationContext): Long2ObjectMap<ObjectSet<PathNodeProperty>> {
            return context.sharedData[CACHE_KEY] as Long2ObjectMap<ObjectSet<PathNodeProperty>>
        }

        /**
         * Packs X, Y, Z coordinates into a single long for use as a cache key.
         * Uses 26 bits for X, 12 bits for Y, 26 bits for Z.
         * This supports coordinates from -33,554,432 to 33,554,431 for X/Z and -2,048 to 2,047 for Y.
         * Minecraft world borders are at ±30,000,000, so this provides sufficient range.
         */
        private fun pack(x: Int, y: Int, z: Int): Long =
            (((x + 33554432L) and 0x3FFFFFF) shl 38) or          // 26 bits for X (33M range)
                    (((z + 33554432L) and 0x3FFFFFF) shl 12) or  // 26 bits for Z (33M range)
                    ((y + 2048L) and 0xFFF)                      // 12 bits for Y (2K range)
    }

    /**
     * Called once at the start of a pathfinding operation to prepare the cache.
     *
     * This sets up an empty map in the `SearchContext` for this specific request.
     */
    override fun initializeSearch(context: SearchContext) {
        context.sharedData[CACHE_KEY] = Long2ObjectOpenHashMap<ObjectSet<PathNodeProperty>>()
    }

    override fun isValid(context: EvaluationContext): Boolean {
        val currentProps = getOrCalculateProperties(context, context.currentPathPosition)
        if (context.previousPathPosition == null) return true
        val isPassable = isNodePassableByCapabilities(currentProps)

        if (!isPassable) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.let {
                val (detailedReason, isVerbose) = generateRejectionReason(currentProps)
                it.recordEvent(
                    position = context.currentPathPosition,
                    parentPosition = context.previousPathPosition,
                    event = PathfindingDebugEvent.NodeRejected(
                        position = context.currentPathPosition,
                        reason = detailedReason,
                        processorName = "NodeTypeProcessor",
                    ),
                    verbose = isVerbose
                )
            }
        }

        return isPassable
    }

    private fun getOrCalculateProperties(
        context: EvaluationContext,
        position: PathPosition
    ): Set<PathNodeProperty> {
        val cache = cache(context)
        val packedPos = pack(position.flooredX, position.flooredY, position.flooredZ)
        val environmentContext: BukkitEnvironmentContext = context.environmentContext as BukkitEnvironmentContext

        cache[packedPos]?.let { return it }

        return ObjectOpenHashSet<PathNodeProperty>().apply {
            val location = BukkitMapper.toLocation(position, environmentContext.world)
            val world = location.world ?: return@apply

            val block = location.block
            val blockData = block.blockData
            val blockType = block.type

            when {
                block.isLiquid -> {
                    add(PathNodeProperty.LIQUID)
                    when (blockType) {
                        Material.LAVA -> add(PathNodeProperty.FIRE_DAMAGE)
                        else -> add(PathNodeProperty.DROWNING_RISK)
                    }
                }

                blockData is Openable -> {}

                block.isSolid || block.collisionShape.boundingBoxes.isNotEmpty() -> add(PathNodeProperty.SOLID)
            }

            when {
                Tag.FIRE.isTagged(blockType) -> add(PathNodeProperty.FIRE_DAMAGE)
                blockType == Material.CACTUS || blockType == Material.SWEET_BERRY_BUSH -> add(PathNodeProperty.DAMAGING)
            }

            when (blockData) {
                is Door -> {
                    add(PathNodeProperty.DOOR)
                    if (blockType != Material.IRON_DOOR) {
                        add(PathNodeProperty.OPENABLE)
                    }
                    if (blockData.isOpen) {
                        add(PathNodeProperty.OPEN)
                    }
                }

                is TrapDoor -> {
                    add(PathNodeProperty.TRAPDOOR)
                    if (blockType != Material.IRON_TRAPDOOR) {
                        add(PathNodeProperty.OPENABLE)
                    }
                    if (blockData.isOpen) {
                        add(PathNodeProperty.OPEN)
                    }
                }

                is Gate -> {
                    add(PathNodeProperty.GATE)
                    add(PathNodeProperty.OPENABLE)
                    if (blockData.isOpen) {
                        add(PathNodeProperty.OPEN)
                    }
                }
            }

            when {
                Tag.PRESSURE_PLATES.isTagged(blockType) -> add(PathNodeProperty.PRESSURE_PLATE)
                Tag.WOOL_CARPETS.isTagged(blockType) -> add(PathNodeProperty.PRESSURE_PLATE)
            }

            when {
                Tag.FENCES.isTagged(blockType) || Tag.WALLS.isTagged(blockType) -> add(PathNodeProperty.FENCE)
            }

            val collisionBoxes = block.collisionShape.boundingBoxes
            if (collisionBoxes.isNotEmpty() && collisionBoxes.all { box ->
                    val boxHeight = box.maxY - box.minY
                    boxHeight < 0.25 && box.minY < 0.1
                }) {
                add(PathNodeProperty.SURFACE_FEATURE)
            }

            val blockBelow = world.getBlockAt(location.blockX, location.blockY - 1, location.blockZ)
            if (isSurfaceWalkable(blockBelow)) {
                add(PathNodeProperty.WALKABLE_SURFACE)
            }
        }.also { cache[packedPos] = it }
    }

    /**
     * A surface is considered walkable if the block is solid and provides
     * a horizontal surface that an entity can actually stand on.
     */
    private fun isSurfaceWalkable(surfaceBlock: Block): Boolean {
        val collisionBoxes = surfaceBlock.collisionShape.boundingBoxes
        if (!surfaceBlock.isSolid && collisionBoxes.isEmpty()) return false

        return collisionBoxes.any { box ->
            val width = box.maxX - box.minX
            val length = box.maxZ - box.minZ

            width >= 0.25 && length >= 0.25
        }
    }

    private fun isNodePassableByCapabilities(properties: Set<PathNodeProperty>): Boolean {
        return when {
            properties.isEmpty() -> false
            properties.contains(PathNodeProperty.SOLID) && !(properties.contains(PathNodeProperty.OPENABLE)
                    || properties.contains(PathNodeProperty.OPEN)
                    || properties.contains(PathNodeProperty.PRESSURE_PLATE)
                    || properties.contains(PathNodeProperty.SURFACE_FEATURE)) -> false

            properties.contains(PathNodeProperty.CLIMBABLE) && !capabilities.canClimb -> false
            properties.contains(PathNodeProperty.LIQUID) && !capabilities.canSwim -> false
            else -> true
        }
    }

    private fun generateRejectionReason(properties: Set<PathNodeProperty>): Pair<String, Boolean> {
        return when {
            properties.isEmpty() ->
                "Block is air" to true

            !properties.contains(PathNodeProperty.WALKABLE_SURFACE) ->
                "No walkable surface below this position" to true

            properties.contains(PathNodeProperty.SOLID) &&
                    !properties.contains(PathNodeProperty.OPENABLE) &&
                    !properties.contains(PathNodeProperty.OPEN) &&
                    !properties.contains(PathNodeProperty.SURFACE_FEATURE) ->
                "Block is solid and cannot be opened" to false

            properties.contains(PathNodeProperty.LIQUID) && !capabilities.canSwim -> {
                val liquidType = if (properties.contains(PathNodeProperty.FIRE_DAMAGE)) "lava" else "water"
                "Cannot swim through $liquidType" to false
            }

            properties.contains(PathNodeProperty.FIRE_DAMAGE) ->
                "Block causes fire damage" to true

            properties.contains(PathNodeProperty.DAMAGING) ->
                "Block causes contact damage" to true

            properties.contains(PathNodeProperty.CLIMBABLE) && !capabilities.canClimb ->
                "Cannot climb" to false

            properties.contains(PathNodeProperty.DROWNING_RISK) && !capabilities.canSwim ->
                "Risk of drowning in liquid" to true

            else ->
                "Block properties not suitable: ${properties.joinToString(", ")}" to true
        }
    }
}