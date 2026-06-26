package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.utils.BlockCollision
import com.typewritermc.engine.paper.utils.BukkitBlockGetter
import com.typewritermc.engine.paper.utils.PhysicsResult
import com.typewritermc.roadnetwork.content.debug.DebugRecorderSupplier
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugEvent
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugRecorder
import com.typewritermc.roadnetwork.pathfinding.pathetic.properties.PathNodeProperty
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import org.bukkit.Location
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.block.data.Openable
import org.bukkit.util.BoundingBox
import kotlin.math.ceil
import kotlin.math.floor

/**
 * A stateless and thread-safe node processor.
 *
 * Validates if an entity can physically move from a parent node to the current node.
 * Takes into account sidestep information calculated by the ObstructionProcessor.
 *
 * This processor must run after the `NodeTypeProcessor` and `ObstructionProcessor`.
 */
class ReachabilityProcessor(
    private val capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT
) : ValidationProcessor {

    private val blockCollision = BlockCollision(capabilities.maxStepHeight)

    companion object {
        private const val MIN_VELOCITY_THRESHOLD = 0.0001
        private const val STEP_DETECTION_THRESHOLD = 0.05
    }

    override fun isValid(context: EvaluationContext): Boolean {
        val parentPos = context.previousPathPosition ?: return true

        val parentGroundY = ObstructionProcessor.cachedGroundY(context, parentPos)
        val currentGroundY = ObstructionProcessor.cachedGroundY(context, context.currentPathPosition)

        if (parentGroundY.isNaN() || currentGroundY.isNaN()) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.recordEvent(
                position = context.currentPathPosition,
                parentPosition = context.previousPathPosition,
                event = PathfindingDebugEvent.NodeRejected(
                    position = context.currentPathPosition,
                    reason = "Cannot determine ground levels for movement",
                    processorName = "ReachabilityProcessor"
                )
            )
            return false
        }

        val verticalMovementValid = isVerticalMovementValid(parentGroundY, currentGroundY, context, parentPos)
        val trajectoryClear = if (verticalMovementValid) {
            // Avoid calling block physics checks if the validator already failed
            isTrajectoryClear(context, parentPos, parentGroundY, currentGroundY)
        } else false

        if (!verticalMovementValid) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.let {
                val deltaY = currentGroundY - parentGroundY
                val reason = when {
                    deltaY < 0 -> "Fall distance too great: ${
                        String.format(
                            "%.1f",
                            -deltaY
                        )
                    }m (max: ${capabilities.maxFallDistance}m)"

                    deltaY > capabilities.maxJumpHeight -> "Jump height too high: ${
                        String.format(
                            "%.1f",
                            deltaY
                        )
                    }m (max: ${capabilities.maxJumpHeight}m)"

                    deltaY > capabilities.maxStepHeight && !capabilities.canJump -> "Cannot jump (jump disabled)"
                    else -> "Vertical movement not possible (${String.format("%.1f", deltaY)}m change)"
                }
                it.recordEvent(
                    position = context.currentPathPosition,
                    parentPosition = context.previousPathPosition,
                    event = PathfindingDebugEvent.NodeRejected(
                        position = context.currentPathPosition,
                        reason = reason,
                        processorName = "ReachabilityProcessor"
                    )
                )
            }
        } else if (!trajectoryClear) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.recordEvent(
                position = context.currentPathPosition,
                parentPosition = context.previousPathPosition,
                event = PathfindingDebugEvent.NodeRejected(
                    position = context.currentPathPosition,
                    reason = "Path trajectory blocked by obstacles",
                    processorName = "ReachabilityProcessor"
                )
            )
        }

        return verticalMovementValid && trajectoryClear
    }

    private fun isVerticalMovementValid(
        parentGroundY: Double,
        currentGroundY: Double,
        context: EvaluationContext,
        parentPos: PathPosition
    ): Boolean {
        val deltaY = currentGroundY - parentGroundY

        return when {
            deltaY < 0 -> -deltaY <= capabilities.maxFallDistance
            deltaY > 0 -> isValidRise(deltaY, context, parentPos, parentGroundY)
            else -> true
        }
    }

    private fun isValidRise(
        deltaY: Double,
        context: EvaluationContext,
        parentPos: PathPosition,
        parentGroundY: Double
    ): Boolean = when {
        deltaY <= capabilities.maxStepHeight -> true
        !capabilities.canJump || deltaY > capabilities.maxJumpHeight -> false
        else -> hasSufficientHeadroomForJump(context, parentPos, parentGroundY, deltaY)
    }

    private fun hasSufficientHeadroomForJump(
        context: EvaluationContext,
        startPos: PathPosition,
        startGroundY: Double,
        jumpHeight: Double
    ): Boolean {
        val requiredClearance = capabilities.height + (jumpHeight - capabilities.maxStepHeight)
        // Subtract 1 because we don't check the ground block
        val blocksToClear = ceil(requiredClearance).toInt() - 1
        val startBlockY = floor(startGroundY).toInt()

        return (1..blocksToClear).all { offset ->
            val checkPos = PathPosition(startPos.x, (startBlockY + offset).toDouble(), startPos.z)
            isBlockPassableAtPosition(context, checkPos)
        }
    }

    private fun isTrajectoryClear(
        context: EvaluationContext,
        parentPos: PathPosition,
        parentGroundY: Double,
        currentGroundY: Double
    ): Boolean {
        val world = (context.environmentContext as? BukkitEnvironmentContext)?.world ?: return false

        val deltaY = currentGroundY - parentGroundY
        val isJump = deltaY > capabilities.maxStepHeight

        val startY = if (isJump) {
            parentGroundY + capabilities.maxStepHeight
        } else {
            parentGroundY
        }

        val startPosition = Location(
            world,
            parentPos.x + 0.5,
            startY,
            parentPos.z + 0.5
        ).toProperty()

        val baseEndPoint = Vector(
            context.currentPathPosition.x + 0.5,
            currentGroundY,
            context.currentPathPosition.z + 0.5
        )

        val sidestepInfo = ObstructionProcessor.cachedSidestepInfo(context, context.currentPathPosition)
        val adjustedEndPoint = sidestepInfo?.let {
            baseEndPoint.add(
                Vector(
                    it.direction.x * it.distance,
                    0.0,
                    it.direction.z * it.distance
                )
            )
        } ?: baseEndPoint

        val velocity = adjustedEndPoint.sub(startPosition)

        if (velocity.lengthSquared < MIN_VELOCITY_THRESHOLD) return true

        return performCollisionCheck(velocity, startPosition, world, currentGroundY, isJump, sidestepInfo)
    }

    private fun performCollisionCheck(
        velocity: Vector,
        startPosition: PositionProperty,
        world: World,
        currentGroundY: Double,
        isJump: Boolean,
        sidestepInfo: SidestepInfo? = null
    ): Boolean {
        val relativeEntityBox = createRelativeEntityBoundingBox()
        val blockGetter = BukkitBlockGetter(world)
        val result = blockCollision.handlePhysics(relativeEntityBox, velocity, startPosition, blockGetter, null, false)

        return when {
            velocity.y < 0 -> handleFallCollision(result)
            isJump -> handleJumpCollision(result)
            else -> handleStepOrFlatMovement(result, velocity, startPosition, currentGroundY, world, sidestepInfo)
        }
    }

    private fun handleFallCollision(result: PhysicsResult): Boolean =
        result.collisionY && !result.collisionX && !result.collisionZ

    private fun handleJumpCollision(result: PhysicsResult): Boolean = !result.collisionY

    private fun handleStepOrFlatMovement(
        result: PhysicsResult,
        velocity: Vector,
        startPosition: PositionProperty,
        currentGroundY: Double,
        world: World,
        sidestepInfo: SidestepInfo? = null
    ): Boolean {
        val yDifference = result.newPosition.y - startPosition.y
        val wasStep =
            yDifference > STEP_DETECTION_THRESHOLD && yDifference <= capabilities.maxStepHeight

        return if (wasStep) {
            val startVector = Vector(startPosition.x, startPosition.y, startPosition.z)
            val baseEndPosition = Vector(startPosition.x + velocity.x, currentGroundY, startPosition.z + velocity.z)

            val adjustedEndPosition = sidestepInfo?.let {
                baseEndPosition.add(
                    Vector(
                        it.direction.x * it.distance,
                        0.0,
                        it.direction.z * it.distance
                    )
                )
            } ?: baseEndPosition

            isHeadspaceClearAlongPath(startVector, adjustedEndPosition, BukkitBlockGetter(world))
        } else {
            !result.collisionX && !result.collisionZ && !result.collisionY
        }
    }

    private fun isHeadspaceClearAlongPath(
        startBase: Vector,
        endBase: Vector,
        blockGetter: BukkitBlockGetter
    ): Boolean {
        val halfWidth = capabilities.width / 2.0
        val height = capabilities.height

        val rayOffsets = listOf(
            Vector(0.0, height, 0.0),
            Vector(halfWidth, height, 0.0),
            Vector(-halfWidth, height, 0.0)
        )

        val isBlockPassablePredicate: (Block) -> Boolean = { block ->
            isBlockPassable(block)
        }

        return rayOffsets.all { offset ->
            val rayStart = startBase.add(offset)
            val rayEnd = endBase.add(offset)
            blockCollision.isRayPathClear(rayStart, rayEnd, blockGetter, isBlockPassablePredicate)
        }
    }

    private fun isBlockPassableAtPosition(context: EvaluationContext, pos: PathPosition): Boolean {
        val properties = NodeTypeProcessor.cachedProperties(context, pos)
        if (properties?.let { isPassable(it) } == true) return true

        val world = (context.environmentContext as? BukkitEnvironmentContext)?.world ?: return false
        val block = world.getBlockAt(pos.x.toInt(), pos.y.toInt(), pos.z.toInt())
        return isEntityCenterFreeOfCollision(block)
    }

    private fun isEntityCenterFreeOfCollision(block: Block): Boolean {
        val halfWidth = capabilities.width / 2.0
        val entityMin = 0.5 - halfWidth
        val entityMax = 0.5 + halfWidth

        return block.collisionShape.boundingBoxes.none { box ->
            box.minX < entityMax && box.maxX > entityMin &&
            box.minZ < entityMax && box.maxZ > entityMin
        }
    }

    private fun isPassable(properties: Set<PathNodeProperty>): Boolean =
        !properties.contains(PathNodeProperty.SOLID) ||
                (properties.contains(PathNodeProperty.OPENABLE) && capabilities.canInteract) ||
                properties.contains(PathNodeProperty.OPEN)

    private fun isBlockPassable(block: Block): Boolean =
        !block.type.isSolid || (block.blockData is Openable && capabilities.canInteract) || (block.blockData is Openable && (block.blockData as Openable).isOpen)

    private fun createRelativeEntityBoundingBox(): BoundingBox {
        val halfWidth = capabilities.width / 2.0
        return BoundingBox(-halfWidth, 0.0, -halfWidth, halfWidth, capabilities.height, halfWidth)
    }
}