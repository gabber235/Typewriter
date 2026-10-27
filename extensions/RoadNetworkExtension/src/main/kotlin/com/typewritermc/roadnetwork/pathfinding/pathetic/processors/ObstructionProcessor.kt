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
import it.unimi.dsi.fastutil.longs.Long2DoubleMap
import it.unimi.dsi.fastutil.longs.Long2DoubleOpenHashMap
import it.unimi.dsi.fastutil.longs.Long2ObjectMap
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap
import org.bukkit.util.Vector

/**
 * A stateless and thread-safe node processor.
 *
 * Checks if an entity can physically fit at a node by testing for collision with
 * solid blocks using the entity bounding boxes. When direct placement isn't possible,
 * calculates and caches sidestep information for use by other processors.
 *
 * This processor must run after the `NodeTypeProcessor`
 */
class ObstructionProcessor(private val capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT) :
    ValidationProcessor {

    companion object {
        private val GROUND_Y_CACHE_KEY = ObstructionProcessor::class.java.packageName + ".groundYCache"
        private val SIDESTEP_CACHE_KEY = ObstructionProcessor::class.java.packageName + ".sidestepCache"
        private val CLEARANCE_KEY = ObstructionProcessor::class.java.packageName + ".clearance"

        /**
         * Gets the cached ground Y-coordinate for a given node from the current search.
         *
         * @param context The active search context.
         * @param position The position of the node.
         * @return The cached ground Y-coordinate, or `Double.NaN` if the node has not been processed yet.
         */
        fun cachedGroundY(context: EvaluationContext, position: PathPosition): Double {
            val cache = groundYCache(context)
            val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)
            return cache.get(packedXYZ)
        }

        /**
         * Gets the cached sidestep information for a given node from the current search.
         *
         * @param context The active search context.
         * @param position The position of the node.
         * @return The cached sidestep information, or null if no sidestep is required or the node hasn't been processed.
         */
        fun cachedSidestepInfo(context: EvaluationContext, position: PathPosition): SidestepInfo? {
            val cache = sidestepCache(context)
            val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)
            return cache.get(packedXYZ)
        }

        @Suppress("UNCHECKED_CAST") // Cache is initialized with correct type in initializeSearch()
        private fun groundYCache(context: EvaluationContext): Long2DoubleMap {
            return context.sharedData[GROUND_Y_CACHE_KEY] as Long2DoubleMap
        }

        @Suppress("UNCHECKED_CAST") // Cache is initialized with correct type in initializeSearch()
        private fun sidestepCache(context: EvaluationContext): Long2ObjectMap<SidestepInfo> {
            return context.sharedData[SIDESTEP_CACHE_KEY] as Long2ObjectMap<SidestepInfo>
        }

        /**
         * Packs X, Y, Z coordinates into a single long for use as a cache key.
         * Uses 26 bits for X, 12 bits for Y, 26 bits for Z.
         * This supports coordinates from -33,554,432 to 33,554,431 for X/Z and -2,048 to 2,047 for Y.
         * Minecraft world borders are at ±30,000,000, so this provides sufficient range.
         */
        private fun packXYZ(x: Int, y: Int, z: Int): Long =
            (((x + 33554432L) and 0x3FFFFFF) shl 38) or          // 26 bits for X (33M range)
                    (((z + 33554432L) and 0x3FFFFFF) shl 12) or  // 26 bits for Z (33M range)
                    ((y + 2048L) and 0xFFF)                      // 12 bits for Y (2K range)
    }

    /**
     * Called once at the start of a pathfinding operation to prepare the caches.
     */
    override fun initializeSearch(context: SearchContext) {
        context.sharedData[GROUND_Y_CACHE_KEY] = Long2DoubleOpenHashMap().apply {
            defaultReturnValue(Double.NaN)
        }
        context.sharedData[SIDESTEP_CACHE_KEY] = Long2ObjectOpenHashMap<SidestepInfo>()
        context.sharedData.remove(CLEARANCE_KEY)
    }

    override fun isValid(context: EvaluationContext): Boolean {
        val currentPos = context.currentPathPosition
        val properties = NodeTypeProcessor.cachedProperties(context, currentPos) ?: return false

        // A node is a valid standing position only if it has a walkable surface directly below it.
        if (!properties.contains(PathNodeProperty.WALKABLE_SURFACE)) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.recordEvent(
                position = currentPos,
                parentPosition = context.previousPathPosition,
                event = PathfindingDebugEvent.NodeRejected(
                    position = currentPos,
                    reason = "No walkable surface below this position",
                    processorName = "ObstructionProcessor"
                ),
                verbose = true
            )
            return false
        }

        val clearance = clearance(context)
        val groundY = findAndCacheGroundY(context, currentPos, clearance)
        val entityCenter = clearance.entityCenter(currentPos, groundY)

        if (!clearance.isObstructed(entityCenter)) {
            return true
        }

        val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
        debugRecorder?.recordEvent(
            position = currentPos,
            parentPosition = context.previousPathPosition,
            event = PathfindingDebugEvent.NodeRejected(
                position = currentPos,
                reason = "Entity bounding box is too big to fit in",
                processorName = "ObstructionProcessor"
            ),
            verbose = true
        )

        val previousPos = context.previousPathPosition ?: return true
        val movement = Vector(currentPos.x - previousPos.x, 0.0, currentPos.z - previousPos.z)
        val sidestepInfo = clearance.sidestep(entityCenter, movement)
        if (sidestepInfo != null) {
            val packedXYZ = packXYZ(currentPos.flooredX, currentPos.flooredY, currentPos.flooredZ)
            sidestepCache(context).put(packedXYZ, sidestepInfo)
            return true
        }

        debugRecorder?.recordEvent(
            position = currentPos,
            parentPosition = previousPos,
            event = PathfindingDebugEvent.NodeRejected(
                position = currentPos,
                reason = "Entity collision with no valid sidestep possible",
                processorName = "ObstructionProcessor"
            )
        )
        return false
    }

    private fun findAndCacheGroundY(
        context: EvaluationContext,
        position: PathPosition,
        clearance: NodeClearance,
    ): Double {
        val cache = groundYCache(context)
        val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)

        val cachedY = cache.get(packedXYZ)
        if (!cachedY.isNaN()) {
            return cachedY
        }

        val calculatedY = clearance.groundY(position)
        cache.put(packedXYZ, calculatedY)
        return calculatedY
    }

    private fun clearance(context: EvaluationContext): NodeClearance =
        context.sharedData.getOrPut(CLEARANCE_KEY) {
            NodeClearance((context.environmentContext as BukkitEnvironmentContext).world, capabilities)
        } as NodeClearance
}
