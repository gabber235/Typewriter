package com.typewritermc.entity.entries.activity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.core.utils.point.distanceSquaredWeightedY
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.GPS
import com.typewritermc.roadnetwork.gps.GPSEdge
import com.typewritermc.roadnetwork.gps.findPathBetweenPosition
import com.typewritermc.roadnetwork.pathfinding.pathetic.PathCalculationResult
import de.bsommerfeld.pathetic.api.pathing.result.Path
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.util.BoundingBox
import kotlin.math.*


class NavigationActivity(
    private val gps: GPS,
    startPosition: PositionProperty,
) : GenericEntityActivity {
    private var path: List<GPSEdge>? = null
    private var state: NavigationActivityTaskState = NavigationActivityTaskState.Idle(startPosition)

    override val currentPosition: PositionProperty
        get() = state.position()

    override fun activate(context: ActivityContext, position: PositionProperty) {
        path = null
        state = NavigationActivityTaskState.Searching(gps, position)
    }

    override fun tick(context: ActivityContext): TickResult {
        val speed = context.entityState.speed
        state.tick(context)
        if (state.isComplete()) {
            val remaining = path?.drop(1)
                ?: (state as? NavigationActivityTaskState.Searching)?.path
                ?: return TickResult.CONSUMED
            path = remaining

            val currentEdge = remaining.firstOrNull() ?: return TickResult.IGNORED

            state = when {
                currentEdge.isFastTravel -> NavigationActivityTaskState.FastTravel(currentEdge)
                context.isViewed -> NavigationActivityTaskState.Walking(
                    gps.roadNetwork,
                    currentEdge,
                    currentPosition,
                    speed = speed
                )

                else -> NavigationActivityTaskState.FakeNavigation(currentEdge, speed = speed)
            }
        }

        val state = state
        // The fake navigation is used to improve the performance; it however, goes through buildings
        // So, we switch to walking when the entity is viewed
        if (state is NavigationActivityTaskState.FakeNavigation && context.isViewed) {
            this.state = NavigationActivityTaskState.Walking(gps.roadNetwork, state.edge, currentPosition, speed)
        }

        // And we switch back to fake navigation when the entity is not viewed
        if (state is NavigationActivityTaskState.Walking && !context.isViewed) {
            this.state = NavigationActivityTaskState.FakeNavigation(state.edge, currentPosition, speed = speed)
        }

        return TickResult.CONSUMED
    }

    override fun deactivate(context: ActivityContext) {
        state.dispose()
    }
}


sealed interface NavigationActivityTaskState {
    fun position(): PositionProperty
    fun isComplete(): Boolean
    fun tick(context: ActivityContext) {}
    fun dispose() {}

    class Idle(
        private val position: PositionProperty,
    ) : NavigationActivityTaskState {
        override fun position(): PositionProperty = position
        override fun isComplete(): Boolean = true
    }

    class Searching(
        private val gps: GPS,
        private val position: PositionProperty,
    ) : NavigationActivityTaskState {
        var path: List<GPSEdge>? = null
        private val job: Job = Dispatchers.UntickedAsync.launch {
            val result = gps.findPath()
            path = if (result.isFailure) {
                logger.severe("Failed to find path: ${result.exceptionOrNull()}")
                emptyList()
            } else {
                result.getOrThrow()
            }
        }

        override fun position(): PositionProperty = position

        override fun isComplete(): Boolean = path != null

        override fun dispose() {
            job.cancel()
            super.dispose()
        }
    }

    class FakeNavigation(
        val edge: GPSEdge,
        val startPosition: PositionProperty = edge.start.toProperty(),
        val speed: Float,
    ) : NavigationActivityTaskState {
        private var ticks: Int = 0

        private val distance: Double = run {
            val dx = edge.end.x - startPosition.x
            val dy = edge.end.y - startPosition.y
            val dz = edge.end.z - startPosition.z
            sqrt(dx * dx + dy * dy + dz * dz)
        }
        private val maxTicks = (distance * speed * 20).toInt().coerceAtLeast(1)

        override fun position(): PositionProperty {
            if (ticks >= maxTicks) return edge.end.copy(y = edge.end.y - 0.5).toProperty()
            return startPosition
        }

        override fun tick(context: ActivityContext) {
            super.tick(context)
            ticks++
        }

        override fun isComplete(): Boolean = ticks >= maxTicks
    }

    class FastTravel(
        val edge: GPSEdge,
    ) : NavigationActivityTaskState {
        override fun position(): PositionProperty = edge.end.toProperty()
        override fun isComplete(): Boolean = true
    }

    class Walking(
        private val roadNetwork: Ref<RoadNetworkEntry>,
        val edge: GPSEdge,
        startPosition: PositionProperty,
        val speed: Float,
        private val rotationLookAhead: Int = 3,
        private val stuckThreshold: Int = 60,
        private val stuckTolerance: Double = 0.01,
    ) : NavigationActivityTaskState {
        companion object {
            private const val MIN_DISTANCE_SQUARED = 0.001

            private const val PASS_NODE_RADIUS_SQUARED = 1.0

            private const val JUMP_DISTANCE_THRESHOLD = 2.4
            private const val JUMP_SPEED_DIVISOR = 0.2085
            private const val JUMP_HORIZONTAL_SPEED_FACTOR = 0.45

            private const val DIRECTION_CONFLICT_DOT_THRESHOLD = 0.5

            private val DEFAULT_PLAYER_BOUNDINGBOX_SIZE = 0.6 to 1.8
        }

        private var location: PositionProperty = startPosition
        private var velocity = Vector.ZERO

        private var yawVelocity = Velocity(0f)
        private var pitchVelocity = Velocity(0f)

        @Volatile
        private var patheticPath: Path? = null
        private var pathIndex: Int = 0
        private var pathCalculationJob: Job? = null

        @Volatile
        private var pathCalculationFailed: Boolean = false

        @Volatile
        private var pathIsFallback: Boolean = false

        // TODO: Should be synced with other activity, like locationActivityRange of the TargetLocationActivty
        private val nearNodeRadius = 0.5
        private lateinit var capabilities: EntityPathingCapabilities
        private lateinit var blockCollision: BlockCollision

        private var lastPosition: PositionProperty = startPosition
        private var stuckTicks: Int = 0

        private var lastPhysicsResult: PhysicsResult? = null

        private fun startPathCalculation() {
            // TODO: Pathing capabilities should be generated from the entity type
            //       but it would require the roadnetwork extension to have node with capabilities
            capabilities = EntityPathingCapabilities.DEFAULT
            blockCollision = BlockCollision(capabilities.maxStepHeight)

            pathCalculationJob = Dispatchers.UntickedAsync.launch {
                val entityPosition = location.toPosition()
                val result = findPathBetweenPosition(
                    startPosition = entityPosition.firstWalkableLocationBelow() ?: entityPosition,
                    endPosition = edge.end,
                    capabilities = capabilities,
                    roadNetworkRef = roadNetwork,
                    checkIntermediateNodes = false,
                    allowFallback = true,
                )

                when (result) {
                    is PathCalculationResult.Success -> {
                        patheticPath = result.path
                        pathIndex = 0
                        pathIsFallback = result.isFallback
                    }

                    is PathCalculationResult.Failure -> {
                        patheticPath = null
                        pathCalculationFailed = true
                        logger.warning("Failed to calculate path for edge ending at ${edge.end} starting from ${location.toPosition()}. Try to recalculate the road network edges.")
                    }
                }
            }
        }

        override fun position(): PositionProperty = location

        override fun tick(context: ActivityContext) {
            if (pathCalculationJob == null) {
                startPathCalculation()
            }

            val currentPath = patheticPath ?: return
            val world = location.world.toBukkitWorld()
            val edgeEndSurfaceY = computeSurfaceY(
                world, edge.end.blockX, edge.end.blockY, edge.end.blockZ
            )
            val actualEdgeEnd = edge.end.copy(y = edgeEndSurfaceY)

            val distanceToEdgeEnd = location.distanceSquaredWeightedY(actualEdgeEnd, 0.8) ?: Double.POSITIVE_INFINITY
            if (distanceToEdgeEnd <= nearNodeRadius && isOnGround()) {
                return
            }

            if (pathIndex < currentPath.length()) {
                checkStuckState()
                advancePastReachedNodes(currentPath, world)
            }

            if (pathIndex >= currentPath.length()) {
                val target = PositionProperty(
                    location.world,
                    edge.end.x,
                    edgeEndSurfaceY,
                    edge.end.z,
                    location.yaw,
                    location.pitch
                )
                if (pathIsFallback) {
                    location = target
                    velocity = Vector.ZERO
                    return
                }
                moveTo(target)
                super.tick(context)
                return
            }

            val targetNode = currentPath.elementAtOrNull(pathIndex) ?: return
            moveTo(nodeTarget(targetNode, world))
            super.tick(context)
        }

        private fun advancePastReachedNodes(currentPath: Path, world: World) {
            if (!isOnGround()) return
            while (pathIndex < currentPath.length()) {
                val node = currentPath.elementAtOrNull(pathIndex) ?: return
                val isLastNode = pathIndex == currentPath.length() - 1
                val canAdvance = canAdvancePastNode(
                    location,
                    nodeTarget(node, world),
                    isLastNode,
                    capabilities.maxStepHeight,
                    nearNodeRadius,
                    PASS_NODE_RADIUS_SQUARED,
                )
                if (!canAdvance) return

                pathIndex++
                resetStuckState()
            }
        }

        private fun nodeTarget(node: PathPosition, world: World): PositionProperty {
            val bukkitLocation = BukkitMapper.toLocation(node, world)
            val centered = bukkitLocation.toCenterLocation()
            val surfaceY = computeSurfaceY(
                world, bukkitLocation.blockX, bukkitLocation.blockY, bukkitLocation.blockZ
            )
            return PositionProperty(
                location.world,
                centered.x,
                surfaceY,
                centered.z,
                location.yaw,
                location.pitch
            )
        }

        private fun checkStuckState() {
            val distanceMoved = location.distanceSquared(lastPosition) ?: 0.0

            if (distanceMoved < stuckTolerance) {
                stuckTicks++
                if (stuckTicks >= stuckThreshold) {
                    handleStuckEntity()
                }
            } else {
                resetStuckState()
            }

            lastPosition = location.copy()
        }

        private fun handleStuckEntity() {
            val currentPath = patheticPath ?: run {
                logger.warning("Cannot handle stuck entity: no path available")
                return
            }

            if (pathIndex >= currentPath.length() - 1) {
                location = PositionProperty(
                    location.world,
                    edge.end.x,
                    edge.end.y,
                    edge.end.z,
                    location.yaw,
                    location.pitch
                )

                velocity = Vector.ZERO
                resetStuckState()

                logger.info("Entity was stuck at last node for $stuckThreshold ticks at $location, teleported to final destination at (${edge.end})")
                return
            }

            val currentNode = currentPath.elementAtOrNull(pathIndex) ?: run {
                logger.warning("Cannot retrieve current path node at index $pathIndex")
                return
            }

            pathIndex++
            val nextNode = currentPath.elementAtOrNull(pathIndex) ?: run {
                logger.warning("Cannot retrieve next path node at index $pathIndex")
                return
            }

            val nextLocation = BukkitMapper.toLocation(nextNode, location.world.toBukkitWorld())
            val nextSurfaceY = computeSurfaceY(
                location.world.toBukkitWorld(),
                nextLocation.blockX, nextLocation.blockY, nextLocation.blockZ
            )

            location = PositionProperty(
                world = location.world,
                x = nextLocation.toCenterLocation().x,
                y = nextSurfaceY,
                z = nextLocation.toCenterLocation().z,
                yaw = location.yaw,
                pitch = location.pitch
            )

            velocity = Vector.ZERO
            resetStuckState()

            logger.warning("Entity was stuck for $stuckThreshold ticks at $location for node $currentNode, teleported to next node at (${nextLocation.blockX}, ${nextLocation.blockY}, ${nextLocation.blockZ})")
        }

        private fun resetStuckState() {
            stuckTicks = 0
        }

        private fun moveTo(target: PositionProperty) {
            val currentSpeed = speed.toDouble()
            val velocity = calculateVelocity(target, currentSpeed)
            val result = calculateMovement(velocity)
            location = result.newPosition
            this.velocity = result.newVelocity

            val (yaw, pitch) = calculateRotation()
            location = location.copy(yaw = yaw, pitch = pitch)
        }

        private fun calculateVelocity(target: PositionProperty, speed: Double): Vector {
            var effectiveSpeed = speed
            val dx: Double = target.x - location.x
            val dy: Double = target.y - location.y
            val dz: Double = target.z - location.z
            val distSquared = dx * dx + dy * dy + dz * dz

            // Limit the speed to make sure not to overshoot the target
            if (effectiveSpeed * effectiveSpeed > distSquared && distSquared > 0) {
                effectiveSpeed = sqrt(distSquared)
            }

            if (distSquared < MIN_DISTANCE_SQUARED) return Vector.ZERO

            val dist = sqrt(distSquared)
            val dirX = dx / dist
            val dirY = dy / dist
            val dirZ = dz / dist

            if (capabilities.canJump && isOnGround()) {
                val stepHeight = stepHeightToTarget(target)
                if (stepHeight > capabilities.maxStepHeight) {
                    val distanceToTarget = location.distanceSquaredWeightedY(target) ?: Double.POSITIVE_INFINITY
                    if (distanceToTarget < (JUMP_DISTANCE_THRESHOLD * (speed / JUMP_SPEED_DIVISOR))) {
                        val world = location.world.toBukkitWorld()
                        if (blockCollision.hasHeadroom(boundingBox(), target, BukkitBlockGetter(world))) {
                            return calculateJumpVelocity(target, speed)
                        }
                    }
                }
            }

            val targetVelocity = Vector(dirX * effectiveSpeed, dirY * effectiveSpeed, dirZ * effectiveSpeed)

            val gravityVelocity = if (dy < 0) {
                Vector(0.0, -0.1, 0.0)
            } else Vector.ZERO

            var newVelocity = velocity + gravityVelocity
            newVelocity = Vector(targetVelocity.x, newVelocity.y, targetVelocity.z)

            return newVelocity
        }

        private fun stepHeightToTarget(target: PositionProperty): Double {
            val world = location.world.toBukkitWorld()
            val currentStandingBlock = currentStandingBlock(world)

            val targetBlockY = floor(target.y).toInt()

            var nextObstacleY = Double.NEGATIVE_INFINITY

            if (target.y != targetBlockY.toDouble()) {
                val blockAtTarget = world.getBlockAt(target.blockX, targetBlockY, target.blockZ)
                if (blockAtTarget.collisionShape.boundingBoxes.isNotEmpty()) {
                    nextObstacleY = max(nextObstacleY, worldObstacleHeightSwept(currentStandingBlock, blockAtTarget))
                }
            }

            val blockBelowTarget = world.getBlockAt(target.blockX, targetBlockY - 1, target.blockZ)
            if (blockBelowTarget.collisionShape.boundingBoxes.isNotEmpty()) {
                nextObstacleY = max(nextObstacleY, worldObstacleHeightSwept(currentStandingBlock, blockBelowTarget))
            }

            if (nextObstacleY == Double.NEGATIVE_INFINITY) return 0.0
            return nextObstacleY - location.y
        }

        private fun calculateJumpVelocity(target: PositionProperty, speed: Double): Vector {
            val dx = target.x - location.x
            val dz = target.z - location.z
            val distSqHorizontal = dx * dx + dz * dz

            val horizontalSpeedFactor = JUMP_HORIZONTAL_SPEED_FACTOR * speed

            val jumpVelX: Double
            val jumpVelZ: Double
            if (distSqHorizontal > 0) {
                val distHorizontal = sqrt(distSqHorizontal)
                jumpVelX = dx / distHorizontal * horizontalSpeedFactor
                jumpVelZ = dz / distHorizontal * horizontalSpeedFactor
            } else {
                jumpVelX = 0.0
                jumpVelZ = 0.0
            }

            return Vector(jumpVelX, capabilities.jumpStrength, jumpVelZ)
        }

        private fun isOnGround(): Boolean {
            val checkVelocity = Vector(0.0, -0.1, 0.0)
            val result = calculateMovement(checkVelocity)
            return result.collisionY
        }

        private fun calculateMovement(velocity: Vector): PhysicsResult {
            val world = location.toBukkitLocation().world
                ?: throw IllegalStateException("Trying to navigate in ${location.world} which is not loaded")

            val result = blockCollision.handlePhysics(
                boundingBox(),
                velocity,
                location,
                BukkitBlockGetter(world),
                lastPhysicsResult,
                false,
            )

            lastPhysicsResult = result
            return result
        }

        private fun calculateRotation(): Pair<Float, Float> {
            val lookTarget = lookTarget() ?: return Pair(location.yaw, location.pitch)
            return walkingLookRotation(location, lookTarget, yawVelocity, pitchVelocity)
        }

        private fun lookTarget(): Vector? {
            val currentPath = patheticPath ?: return null
            val world = location.world.toBukkitWorld()

            if (pathIndex >= currentPath.length()) {
                val surfaceY = computeSurfaceY(world, edge.end.blockX, edge.end.blockY, edge.end.blockZ)
                return Vector(edge.end.x, surfaceY, edge.end.z)
            }

            val lookAheadIndex = if (hasDirectionConflict()) {
                pathIndex
            } else {
                min(pathIndex + rotationLookAhead, currentPath.length() - 1)
            }

            val targetNode = currentPath.elementAtOrNull(lookAheadIndex) ?: return null
            val targetBukkitLoc = BukkitMapper.toLocation(targetNode, world)
            val targetLocation = targetBukkitLoc.toCenterLocation()
            val targetSurfaceY = computeSurfaceY(
                world,
                targetBukkitLoc.blockX, targetBukkitLoc.blockY, targetBukkitLoc.blockZ
            )

            return Vector(targetLocation.x, targetSurfaceY, targetLocation.z)
        }

        private fun hasDirectionConflict(): Boolean {
            val currentPath = patheticPath ?: return false
            if (pathIndex + rotationLookAhead >= currentPath.length()) return false

            // Don't trigger during jumps to avoid looking down at ground nodes
            if (!isOnGround()) return false

            val nextNode = currentPath.elementAtOrNull(pathIndex) ?: return false
            val lookAheadNode = currentPath.elementAtOrNull(pathIndex + rotationLookAhead) ?: return false

            val nextPos = BukkitMapper.toLocation(nextNode, location.world.toBukkitWorld())
            val lookAheadPos = BukkitMapper.toLocation(lookAheadNode, location.world.toBukkitWorld())

            val immediateDirection = Vector(
                nextPos.x - location.x,
                0.0,
                nextPos.z - location.z
            ).normalize()

            val lookAheadDirection = Vector(
                lookAheadPos.x - location.x,
                0.0,
                lookAheadPos.z - location.z
            ).normalize()

            val dotProduct = immediateDirection.dot(lookAheadDirection)
            return dotProduct < DIRECTION_CONFLICT_DOT_THRESHOLD
        }

        override fun isComplete(): Boolean {
            if (pathCalculationFailed) return true
            val edgeEndSurfaceY = computeSurfaceY(
                location.world.toBukkitWorld(),
                edge.end.blockX, edge.end.blockY, edge.end.blockZ
            )
            return (location.distanceSquaredWeightedY(edge.end.copy(y = edgeEndSurfaceY), 0.8)
                ?: Double.POSITIVE_INFINITY) <= nearNodeRadius && isOnGround()
        }

        private fun boundingBox(): BoundingBox {
            val (width, height) = if (::capabilities.isInitialized) {
                capabilities.width to capabilities.height
            } else {
                DEFAULT_PLAYER_BOUNDINGBOX_SIZE
            }

            val halfWidth = width / 2.0
            return BoundingBox(-halfWidth, 0.0, -halfWidth, halfWidth, height, halfWidth)
        }

        override fun dispose() {
            pathCalculationJob?.cancel()
            pathCalculationJob = null
            lastPhysicsResult = null
            super.dispose()
        }

        private fun currentStandingBlock(world: World): Block {
            val (x, y, z) = Triple(location.blockX, location.blockY, location.blockZ)

            world.getBlockAt(x, y, z).takeIf { it.isSolid }?.let { return it }

            val belowBlock = world.getBlockAt(x, y - 1, z)
            if (belowBlock.isSolid) return belowBlock

            // Search Y levels by proximity to entity
            val yLevels = listOf(y, y - 1).sortedBy { abs(location.y - (it + 0.5)) }

            return yLevels.firstNotNullOfOrNull { yLevel ->
                neighborPositions(x, z)
                    .map { (nx, nz) -> world.getBlockAt(nx, yLevel, nz) }
                    .filter { it.isSolid }
                    .minByOrNull { block -> distanceSquaredTo(block) }
            } ?: belowBlock // Fallback when no solid neighbors exist
        }

        private fun neighborPositions(x: Int, z: Int) = listOf(
            x + 1 to z, x - 1 to z, x to z + 1, x to z - 1
        )

        private fun distanceSquaredTo(block: Block): Double {
            val dx = location.x - (block.x + 0.5)
            val dz = location.z - (block.z + 0.5)
            return dx * dx + dz * dz
        }

        private fun worldObstacleHeightSwept(fromBlock: Block, toBlock: Block): Double {
            val movementVector = toBlock.location.toVector()
                .subtract(fromBlock.location.toVector())
                .apply { y = 0.0 }

            val halfWidth = capabilities.width / 2.0

            val startXInToBlock = (fromBlock.x + 0.5) - toBlock.x
            val startZInToBlock = (fromBlock.z + 0.5) - toBlock.z

            val entityFootprint = BoundingBox(
                startXInToBlock - halfWidth, 0.0, startZInToBlock - halfWidth,
                startXInToBlock + halfWidth, 1.0, startZInToBlock + halfWidth
            )

            val obstacleBoxes = toBlock.collisionShape.boundingBoxes
            if (obstacleBoxes.isEmpty()) return toBlock.y.toDouble()

            val (earliestTime, highestObstacle) = findEarliestCollision(entityFootprint, obstacleBoxes, movementVector)

            val finalObstacleHeight = if (earliestTime > 1.0) {
                findObstacleAtDestinationCenter(obstacleBoxes)
            } else {
                highestObstacle
            }

            return toBlock.y.toDouble() + finalObstacleHeight
        }

        private fun findEarliestCollision(
            entityFootprint: BoundingBox,
            obstacleBoxes: Collection<BoundingBox>,
            movementVector: org.bukkit.util.Vector
        ): Pair<Double, Double> {
            var earliestTime = 1.1
            var highestObstacle = 0.0

            for (obstacleBox in obstacleBoxes) {
                val collisionTime = calculateSweptCollisionTime(entityFootprint, obstacleBox, movementVector)

                when {
                    collisionTime < earliestTime -> {
                        earliestTime = collisionTime
                        highestObstacle = obstacleBox.maxY
                    }

                    collisionTime == earliestTime -> {
                        highestObstacle = max(highestObstacle, obstacleBox.maxY)
                    }
                }
            }

            return Pair(earliestTime, highestObstacle)
        }

        private fun findObstacleAtDestinationCenter(obstacleBoxes: Collection<BoundingBox>): Double =
            obstacleBoxes.filter { it.contains(0.5, it.minY + 0.1, 0.5) }
                .maxOfOrNull { it.maxY } ?: 0.0

        private fun calculateSweptCollisionTime(
            mover: BoundingBox,
            obstacle: BoundingBox,
            velocity: org.bukkit.util.Vector
        ): Double {
            val invVelX = if (velocity.x == 0.0) Double.POSITIVE_INFINITY else 1.0 / velocity.x
            val invVelZ = if (velocity.z == 0.0) Double.POSITIVE_INFINITY else 1.0 / velocity.z

            val (xEntry, xExit) = calculateAxisTimes(invVelX, obstacle.minX, obstacle.maxX, mover.minX, mover.maxX)
            val (zEntry, zExit) = calculateAxisTimes(invVelZ, obstacle.minZ, obstacle.maxZ, mover.minZ, mover.maxZ)

            val latestEntry = max(xEntry, zEntry)
            val earliestExit = min(xExit, zExit)

            return if (latestEntry in 0.0..<earliestExit && latestEntry < 1.0) latestEntry
            else Double.MAX_VALUE
        }

        private fun calculateAxisTimes(
            invVel: Double,
            obstacleMin: Double,
            obstacleMax: Double,
            moverMin: Double,
            moverMax: Double
        ): Pair<Double, Double> {
            return if (invVel > 0) {
                Pair((obstacleMin - moverMax) * invVel, (obstacleMax - moverMin) * invVel)
            } else {
                Pair((obstacleMax - moverMin) * invVel, (obstacleMin - moverMax) * invVel)
            }
        }

        private fun worldSurfaceHeightAtCenter(block: Block): Double {
            val boundingBoxes = block.collisionShape.boundingBoxes
            val entityCenter = 0.5
            val halfWidth = capabilities.width / 2.0

            val maxHeight = boundingBoxes.filter { box ->
                val entityLeft = entityCenter - halfWidth
                val entityRight = entityCenter + halfWidth

                entityRight > box.minX && entityLeft < box.maxX &&
                        entityRight > box.minZ && entityLeft < box.maxZ
            }.maxOfOrNull { it.maxY } ?: 0.0

            return block.y.toDouble() + maxHeight
        }

        private fun computeSurfaceY(world: World, blockX: Int, blockY: Int, blockZ: Int): Double {
            val groundBlock = world.getBlockAt(blockX, blockY - 1, blockZ)
            val groundSurfaceY = worldSurfaceHeightAtCenter(groundBlock)

            val nodeBlock = world.getBlockAt(blockX, blockY, blockZ)
            val nodeCollision = nodeBlock.collisionShape.boundingBoxes
            if (nodeCollision.isNotEmpty()) {
                val nodeSurfaceY = worldSurfaceHeightAtCenter(nodeBlock)
                return max(groundSurfaceY, nodeSurfaceY)
            }

            return groundSurfaceY
        }
    }
}