/**
 * Thanks to Minestom for the original implementation of this file.
 *
 * I have made some modifications to the original file to change the types.
 */
package com.typewritermc.engine.paper.utils

import com.typewritermc.core.utils.point.Point
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.toVector
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.util.BoundingBox
import kotlin.math.abs
import kotlin.math.ceil
import kotlin.math.min
import kotlin.math.sign


object BlockCollision {
    private const val STEP_HEIGHT = 0.5

    /**
     * Moves an entity with physics applied (ie checking against blocks)
     *
     *
     * Works by getting all the full blocks that an entity could interact with.
     * All bounding boxes inside the full blocks are checked for collisions with the entity.
     */
    fun handlePhysics(
        boundingBox: BoundingBox,
        velocity: Vector, entityPosition: PositionProperty,
        getter: BukkitBlockGetter,
        singleCollision: Boolean
    ): PhysicsResult {
        // Expensive AABB computation
        return stepPhysics(boundingBox, velocity, entityPosition, getter, singleCollision)
    }

    private fun stepPhysics(
        boundingBox: BoundingBox,
        velocity: Vector, entityPosition: PositionProperty,
        getter: BukkitBlockGetter, singleCollision: Boolean
    ): PhysicsResult {
        // Allocate once and update values
        val finalResult = SweepResult(1 - Vector.EPSILON, 0.0, 0.0, 0.0, 0.0, null, null)

        var foundCollisionX = false
        var foundCollisionY = false
        var foundCollisionZ = false

        val collidedPoints: Array<Point<*>?> = arrayOfNulls(3)
        val collisionShapes: Array<Shape?> = arrayOfNulls(3)

        var hasCollided = false

        // Query faces to get the points needed for collision
        val allFaces: Array<Vector?> = calculateFaces(velocity, boundingBox)
        var result: PhysicsResult = computePhysics(boundingBox, velocity, entityPosition, getter, allFaces, finalResult)
        // Loop until no collisions are found.
        // When collisions are found, the collision axis is set to 0
        // Looping until there are no collisions will allow the entity to move in axis other than the collision axis after a collision.
        while (result.collisionX || result.collisionY || result.collisionZ) {
            // Reset final result
            finalResult.normalX = 0.0
            finalResult.normalY = 0.0
            finalResult.normalZ = 0.0
            finalResult.collidedHeightDiff = 0.0

            if (result.collisionX) {
                foundCollisionX = true
                collisionShapes[0] = finalResult.collidedShape
                collidedPoints[0] = finalResult.collidedPos
                hasCollided = true
                if (singleCollision) break
            } else if (result.collisionZ) {
                foundCollisionZ = true
                collisionShapes[2] = finalResult.collidedShape
                collidedPoints[2] = finalResult.collidedPos
                hasCollided = true
                if (singleCollision) break
            } else if (result.collisionY) {
                foundCollisionY = true
                collisionShapes[1] = finalResult.collidedShape
                collidedPoints[1] = finalResult.collidedPos
                hasCollided = true
                if (singleCollision) break
            }

            // If all axis have had collisions, break
            if (foundCollisionX && foundCollisionY && foundCollisionZ) break
            // If the entity isn't moving, break
            if (result.newVelocity.isZero) break

            finalResult.res = 1 - Vector.EPSILON
            result =
                computePhysics(boundingBox, result.newVelocity, result.newPosition, getter, allFaces, finalResult)
        }

        finalResult.res = result.res.res

        val newDeltaX: Double = if (foundCollisionX) 0.0 else velocity.x
        val newDeltaY: Double = if (foundCollisionY) 0.0 else velocity.y
        val newDeltaZ: Double = if (foundCollisionZ) 0.0 else velocity.z

        return PhysicsResult(
            result.newPosition,
            Vector(newDeltaX, newDeltaY, newDeltaZ),
            newDeltaY == 0.0 && velocity.y < 0,
            foundCollisionX,
            foundCollisionY,
            foundCollisionZ,
            velocity,
            collidedPoints,
            collisionShapes,
            hasCollided,
            finalResult
        )
    }

    private fun computePhysics(
        boundingBox: BoundingBox,
        velocity: Vector,
        entityPosition: PositionProperty,
        getter: BukkitBlockGetter,
        allFaces: Array<Vector?>,
        finalResult: SweepResult
    ): PhysicsResult {
        // If the movement is small, we don't need to run the expensive ray casting.
        // Positions move less than one can have hardcoded blocks to check for every direction
        if (velocity.length < 1) {
            fastPhysics(boundingBox, velocity, entityPosition, getter, allFaces, finalResult)
        } else {
            slowPhysics(boundingBox, velocity, entityPosition, getter, allFaces, finalResult)
        }

        val collisionX = finalResult.normalX != 0.0
        val collisionY = finalResult.normalY != 0.0
        val collisionZ = finalResult.normalZ != 0.0

        var deltaX: Double = finalResult.res * velocity.x
        var deltaY: Double = finalResult.res * velocity.y
        var deltaZ: Double = finalResult.res * velocity.z

        if (abs(deltaX) < Vector.EPSILON) deltaX = 0.0
        if (abs(deltaY) < Vector.EPSILON) deltaY = 0.0
        if (abs(deltaZ) < Vector.EPSILON) deltaZ = 0.0

        var finalPos: PositionProperty = entityPosition.add(deltaX, deltaY, deltaZ)

        val hasHorizontalOnlyCollision = (collisionX || collisionZ) && !collisionY
        var step =
            hasHorizontalOnlyCollision && finalResult.collidedHeightDiff > 0 && finalResult.collidedHeightDiff <= STEP_HEIGHT
        // If the entity is colliding with x or z and the block is below step height, we move the entity up to the block
        if (step) {
            finalPos = finalPos.add(0.0, finalResult.collidedHeightDiff + Vector.EPSILON, 0.0)
        }

        val remainingX: Double = if (collisionX) 0.0 else velocity.x - deltaX
        val remainingY: Double = if (collisionY || step) 0.0 else velocity.y - deltaY
        val remainingZ: Double = if (collisionZ) 0.0 else velocity.z - deltaZ


        return PhysicsResult(
            finalPos, Vector(remainingX, remainingY, remainingZ),
            collisionY, collisionX, collisionY, collisionZ,
            Vector.ZERO, null, null, false, finalResult
        )
    }

    private fun slowPhysics(
        boundingBox: BoundingBox,
        velocity: Vector,
        entityPosition: PositionProperty,
        getter: BukkitBlockGetter,
        allFaces: Array<Vector?>,
        finalResult: SweepResult
    ) {
        // When large moves are done we need to ray-cast to find all blocks that could intersect with the movement
        for (point in allFaces) {
            if (point == null) continue
            val iterator =
                BlockIterator(point.add(entityPosition).toVector(), velocity, 0.0, velocity.length)
            var timer = -1

            while (iterator.hasNext() && timer != 0) {
                val p: Point<*> = iterator.next()

                // If we hit a block, there are at most 3 other blocks that could be closer
                if (checkBoundingBox(
                        p.blockX,
                        p.blockY,
                        p.blockZ,
                        velocity,
                        entityPosition,
                        boundingBox,
                        getter,
                        finalResult
                    )
                ) timer = 3

                timer--
            }
        }
    }

    private fun fastPhysics(
        boundingBox: BoundingBox,
        velocity: Vector,
        entityPosition: PositionProperty,
        getter: BukkitBlockGetter,
        allFaces: Array<Vector?>,
        finalResult: SweepResult
    ) {
        for (point in allFaces) {
            if (point == null) continue
            val pointBefore: Vector = point.add(entityPosition)
            val pointAfter: Vector = point.add(entityPosition).add(velocity)

            // Entity can pass through up to 4 blocks. Starting block, Two intermediate blocks, and a final block.
            // This means we must check every combination of block movements when an entity moves over an axis.
            // 000, 001, 010, 011, etc.
            // There are 8 of these combinations
            // Checks can be limited by checking if we moved across an axis line
            val needsX = pointBefore.x != pointAfter.x
            val needsY = pointBefore.y != pointAfter.y
            val needsZ = pointBefore.z != pointAfter.z

            checkBoundingBox(
                pointBefore.blockX,
                pointBefore.blockY,
                pointBefore.blockZ,
                velocity,
                entityPosition,
                boundingBox,
                getter,
                finalResult
            )

            if (needsX && needsY && needsZ) {
                checkBoundingBox(
                    pointAfter.blockX,
                    pointAfter.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )

                checkBoundingBox(
                    pointAfter.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )

                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsX && needsY) {
                checkBoundingBox(
                    pointAfter.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )

                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsX && needsZ) {
                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )

                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsY && needsZ) {
                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )

                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
                checkBoundingBox(
                    pointBefore.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsX) {
                checkBoundingBox(
                    pointAfter.blockX,
                    pointBefore.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsY) {
                checkBoundingBox(
                    pointBefore.blockX,
                    pointAfter.blockY,
                    pointBefore.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            } else if (needsZ) {
                checkBoundingBox(
                    pointBefore.blockX,
                    pointBefore.blockY,
                    pointAfter.blockZ,
                    velocity,
                    entityPosition,
                    boundingBox,
                    getter,
                    finalResult
                )
            }
        }
    }

    /**
     * Check if a moving entity will collide with a block. Updates finalResult
     *
     * @param blockX         block x position
     * @param blockY         block y position
     * @param blockZ         block z position
     * @param entityVelocity entity movement Vectortor
     * @param entityPosition entity position
     * @param boundingBox    entity bounding box
     * @param getter         block getter
     * @param finalResult    place to store final result of collision
     * @return true if entity finds collision, other false
     */
    fun checkBoundingBox(
        blockX: Int, blockY: Int, blockZ: Int,
        entityVelocity: Vector, entityPosition: PositionProperty, boundingBox: BoundingBox,
        getter: BukkitBlockGetter, finalResult: SweepResult,
    ): Boolean {
        val currentBlock: Block = getter.getBlock(blockX, blockY, blockZ)
        val currentShape: Shape = currentBlock.collisionShape()

        val currentCollidable: Boolean = !currentShape.relativeEnd().isZero
        val currentShort: Boolean = currentShape.relativeEnd().y < 0.5

        // only consider the block below if our current shape is sufficiently short
        if (currentShort && shouldCheckLower(entityVelocity, entityPosition, blockX, blockY, blockZ)) {
            // we need to check below for a tall block (fence, wall, ...)
            val belowPos = Vector(blockX, blockY - 1, blockZ)
            val belowBlock: Block = getter.getBlock(belowPos)
            val belowShape: Shape = belowBlock.collisionShape()

            val currentPos = Vector(blockX, blockY, blockZ)
            // don't fall out of if statement, we could end up redundantly grabbing a block, and we only need to
            // collision check against the current shape since the below shape isn't tall
            return if (belowShape.relativeEnd().y > 1) {
                // we should always check both shapes, so no short-circuit here, to handle cases where the bounding box
                // hits the current solid but misses the tall solid
                belowShape.intersectBoxSwept(entityPosition, entityVelocity, belowPos, boundingBox, finalResult) ||
                        currentCollidable && currentShape.intersectBoxSwept(
                    entityPosition,
                    entityVelocity,
                    currentPos,
                    boundingBox,
                    finalResult
                )
            } else {
                currentCollidable && currentShape.intersectBoxSwept(
                    entityPosition,
                    entityVelocity,
                    currentPos,
                    boundingBox,
                    finalResult
                )
            }
        }

        if (currentCollidable && currentShape.intersectBoxSwept(
                entityPosition, entityVelocity,
                Vector(blockX, blockY, blockZ), boundingBox, finalResult
            )
        ) {
            // if the current collision is sufficiently short, we might need to collide against the block below too
            if (currentShort) {
                val belowPos = Vector(blockX, blockY - 1, blockZ)
                val belowBlock: Block = getter.getBlock(belowPos)
                val belowShape: Shape = belowBlock.collisionShape()
                // only do sweep if the below block is big enough to possibly hit
                if (belowShape.relativeEnd().y > 1) belowShape.intersectBoxSwept(
                    entityPosition,
                    entityVelocity,
                    belowPos,
                    boundingBox,
                    finalResult
                )
            }
            return true
        }
        return false
    }

    private fun shouldCheckLower(
        entityVelocity: Vector,
        entityPosition: PositionProperty,
        blockX: Int,
        blockY: Int,
        blockZ: Int
    ): Boolean {
        val yVelocity: Double = entityVelocity.y
        // if moving horizontally, just check if the floor of the entity's position is the same as the blockY
        if (yVelocity == 0.0) return (entityPosition.y).toInt() == blockY
        val xVelocity: Double = entityVelocity.x
        val zVelocity: Double = entityVelocity.z
        // if moving straight up, don't bother checking for tall solids beneath anything
        // if moving straight down, only check for a tall solid underneath the last block
        if (xVelocity == 0.0 && zVelocity == 0.0) return yVelocity < 0 && blockY == (entityPosition.y + yVelocity).toInt()
        // default to true: if no x velocity, only consider YZ line, and vice-versa
        val underYX = xVelocity != 0.0 && computeHeight(
            yVelocity,
            xVelocity,
            entityPosition.y,
            entityPosition.x,
            blockX
        ) >= blockY
        val underYZ = zVelocity != 0.0 && computeHeight(
            yVelocity,
            zVelocity,
            entityPosition.y,
            entityPosition.z,
            blockZ
        ) >= blockY
        // true if the block is at or below the same height as a line drawn from the entity's position to its final
        // destination
        return underYX && underYZ
    }

    /*
    computes the height of the entity at the given block position along a projection of the line it's travelling along
    (YX or YZ). the returned value will be greater than or equal to the block height if the block is along the lower
    layer of intersections with this line.
     */
    private fun computeHeight(
        yVelocity: Double,
        velocity: Double,
        entityY: Double,
        pos: Double,
        blockPos: Int
    ): Double {
        val m = yVelocity / velocity
        /*
        offsetting by 1 is necessary with a positive slope, because we can clip the bottom-right corner of blocks
        without clipping the "bottom-left" (the smallest corner of the block on the YZ or YX plane). without the offset
        these would not be considered to be on the lowest layer, since our block position represents the bottom-left
        corner
         */
        return m * (blockPos - pos + (if (m > 0) 1 else 0)) + entityY
    }

    private fun calculateFaces(queryVector: Vector, boundingBox: BoundingBox): Array<Vector?> {
        val queryX = sign(queryVector.x).toInt()
        val queryY = sign(queryVector.y).toInt()
        val queryZ = sign(queryVector.z).toInt()

        val ceilWidth = ceil(boundingBox.widthX).toInt()
        val ceilHeight = ceil(boundingBox.height).toInt()
        val ceilDepth = ceil(boundingBox.widthZ).toInt()
        var facePoints: Array<Vector?>
        // Compute array length
        run {
            val ceilX = ceilWidth + 1
            val ceilY = ceilHeight + 1
            val ceilZ = ceilDepth + 1
            var pointCount = 0
            if (queryX != 0) pointCount += ceilY * ceilZ
            if (queryY != 0) pointCount += ceilX * ceilZ
            if (queryZ != 0) pointCount += ceilX * ceilY
            // Three edge reduction
            if (queryX != 0 && queryY != 0 && queryZ != 0) {
                pointCount -= ceilX + ceilY + ceilZ
                // inclusion exclusion principle
                pointCount++
            } else if (queryX != 0 && queryY != 0) { // Two edge reduction
                pointCount -= ceilZ
            } else if (queryY != 0 && queryZ != 0) { // Two edge reduction
                pointCount -= ceilX
            } else if (queryX != 0 && queryZ != 0) { // Two edge reduction
                pointCount -= ceilY
            }
            facePoints = arrayOfNulls(pointCount)
        }
        var insertIndex = 0
        // X -> Y x Z
        if (queryX != 0) {
            var startIOffset = 0
            var endIOffset = 0
            var startJOffset = 0
            var endJOffset = 0
            // Y handles XY edge
            if (queryY < 0) startJOffset = 1
            if (queryY > 0) endJOffset = 1
            // Z handles XZ edge
            if (queryZ < 0) startIOffset = 1
            if (queryZ > 0) endIOffset = 1

            for (i in startIOffset..ceilDepth - endIOffset) {
                for (j in startJOffset..ceilHeight - endJOffset) {
                    var cellI = i.toDouble()
                    var cellJ = j.toDouble()
                    var cellK: Double = if (queryX < 0) 0.0 else boundingBox.widthX

                    if (i >= boundingBox.widthZ) cellI = boundingBox.widthZ
                    if (j >= boundingBox.height) cellJ = boundingBox.height

                    cellI += boundingBox.minZ
                    cellJ += boundingBox.minY
                    cellK += boundingBox.minX

                    facePoints[insertIndex++] = Vector(cellK, cellJ, cellI)
                }
            }
        }
        // Y -> X x Z
        if (queryY != 0) {
            var startJOffset = 0
            var endJOffset = 0
            // Z handles YZ edge
            if (queryZ < 0) startJOffset = 1
            if (queryZ > 0) endJOffset = 1

            for (i in startJOffset..ceilDepth - endJOffset) {
                for (j in 0..ceilWidth) {
                    var cellI = i.toDouble()
                    var cellJ = j.toDouble()
                    var cellK: Double = if (queryY < 0) 0.0 else boundingBox.height

                    if (i >= boundingBox.widthZ) cellI = boundingBox.widthZ
                    if (j >= boundingBox.widthX) cellJ = boundingBox.widthX

                    cellI += boundingBox.minZ
                    cellJ += boundingBox.minX
                    cellK += boundingBox.minY

                    facePoints[insertIndex++] = Vector(cellJ, cellK, cellI)
                }
            }
        }
        // Z -> X x Y
        if (queryZ != 0) {
            for (i in 0..ceilHeight) {
                for (j in 0..ceilWidth) {
                    var cellI = i.toDouble()
                    var cellJ = j.toDouble()
                    var cellK: Double = if (queryZ < 0) 0.0 else boundingBox.widthZ

                    if (i >= boundingBox.height) cellI = boundingBox.height
                    if (j >= boundingBox.widthX) cellJ = boundingBox.widthX

                    cellI += boundingBox.minY
                    cellJ += boundingBox.minX
                    cellK += boundingBox.minZ

                    facePoints[insertIndex++] = Vector(cellJ, cellI, cellK)
                }
            }
        }

        return facePoints
    }
}

/**
 * The result of a physics simulation.
 * @param newPosition the new position of the entity
 * @param newVelocity the new velocity of the entity
 * @param isOnGround if the entity is on the ground
 * @param collisionX if the entity collided on the X axis
 * @param collisionY if the entity collided on the Y axis
 * @param collisionZ if the entity collided on the Z axis
 * @param originalDelta the velocity delta of the entity
 * @param collisionPoints the points where the entity collided
 * @param collisionShapes the shapes the entity collided with
 */
data class PhysicsResult(
    val newPosition: PositionProperty,
    val newVelocity: Vector,
    val isOnGround: Boolean,
    val collisionX: Boolean,
    val collisionY: Boolean,
    val collisionZ: Boolean,
    val originalDelta: Vector,
    val collisionPoints: Array<Point<*>?>?,
    val collisionShapes: Array<Shape?>?,
    val hasCollision: Boolean,
    val res: SweepResult
)

data class SweepResult(
    var res: Double,
    var normalX: Double,
    var normalY: Double,
    var normalZ: Double,
    var collidedHeightDiff: Double,
    var collidedShape: Shape?,
    var collidedPos: Point<*>?,
)

interface Shape {
    /**
     * Checks if a moving bounding box will hit this shape.
     *
     * @param rayStart     Position of the moving shape
     * @param rayDirection Movement vector
     * @param shapePos     Position of this shape
     * @param moving       Bounding Box of moving shape
     * @param finalResult  Stores final SweepResult
     * @return is an intersection found
     */
    fun intersectBoxSwept(
        rayStart: Point<*>, rayDirection: Point<*>,
        shapePos: Point<*>, moving: BoundingBox, finalResult: SweepResult
    ): Boolean

    /**
     * Get the bounding boxes of the shape
     *
     * @return the bounding boxes of the shape
     */
    fun boundingBoxes(): Collection<BoundingBox>

    /**
     * Relative End
     *
     * @return End of shape
     */
    fun relativeEnd(): Point<*>
}

class BukkitBlockShape(
    val block: Block
) : Shape {
    private val collidedShape by lazy(LazyThreadSafetyMode.NONE) { block.collisionShape }

    override fun intersectBoxSwept(
        rayStart: Point<*>,
        rayDirection: Point<*>,
        shapePos: Point<*>,
        moving: BoundingBox,
        finalResult: SweepResult
    ): Boolean {
        var hitBlock = false
        for (blockSection in collidedShape.boundingBoxes) {
            // Update final result if the temp result collision is sooner than the current final result
            if (boundingBoxIntersectionCheck(
                    moving,
                    rayStart,
                    rayDirection,
                    blockSection,
                    shapePos,
                    finalResult
                )
            ) {
                finalResult.collidedShape = this
                val collidedPos = rayStart.add(rayDirection.mul(finalResult.res))
                finalResult.collidedPos = collidedPos
                val relativePos = collidedPos.sub(shapePos)
                finalResult.collidedHeightDiff = blockSection.maxY - relativePos.y

                hitBlock = true
            }
        }
        return hitBlock
    }

    override fun boundingBoxes(): Collection<BoundingBox> = collidedShape.boundingBoxes

    override fun relativeEnd(): Point<*> {
        var maxX = 0.0
        var maxY = 0.0
        var maxZ = 0.0

        for (bounding in collidedShape.boundingBoxes) {
            maxX = maxOf(maxX, bounding.maxX)
            maxY = maxOf(maxY, bounding.maxY)
            maxZ = maxOf(maxZ, bounding.maxZ)
        }

        return Vector(maxX, maxY, maxZ)
    }

    /**
     * Check if a bounding box intersects a ray
     *
     * @param rayStart         Ray start position
     * @param rayDirection     Ray to check
     * @param collidableStatic Bounding box
     * @param finalResult
     * @return true if an intersection between the ray and the bounding box was found
     */
    fun boundingBoxIntersectionCheck(
        moving: BoundingBox,
        rayStart: Point<*>,
        rayDirection: Point<*>,
        collidableStatic: BoundingBox,
        staticCollidableOffset: Point<*>,
        finalResult: SweepResult
    ): Boolean {
        val bbCentre: Point<*> = Vector(
            moving.minX + moving.widthX / 2,
            moving.minY + moving.height / 2,
            moving.minZ + moving.widthZ / 2
        )
        val rayCentre = rayStart.add(bbCentre)

        // Translate bounding box
        val bbOffMin = Vector(
            collidableStatic.minX - rayCentre.x + staticCollidableOffset.x - moving.widthX / 2,
            collidableStatic.minY - rayCentre.y + staticCollidableOffset.y - moving.height / 2,
            collidableStatic.minZ - rayCentre.z + staticCollidableOffset.z - moving.widthZ / 2
        )
        val bbOffMax = Vector(
            collidableStatic.maxX - rayCentre.x + staticCollidableOffset.x + moving.widthX / 2,
            collidableStatic.maxY - rayCentre.y + staticCollidableOffset.y + moving.height / 2,
            collidableStatic.maxZ - rayCentre.z + staticCollidableOffset.z + moving.widthZ / 2
        )

        // This check is done in 2d. it can be visualised as a rectangle (the face we are checking), and a point.
        // If the point is within the rectangle, we know the vector intersects the face.
        val signumRayX = Math.signum(rayDirection.x)
        val signumRayY = Math.signum(rayDirection.y)
        val signumRayZ = Math.signum(rayDirection.z)

        var isHit = false
        var percentage = Double.MAX_VALUE
        var collisionFace = -1

        // Intersect X
        // Left side of bounding box
        if (rayDirection.x > 0) {
            val xFac = epsilon(bbOffMin.x / rayDirection.x)
            if (xFac < percentage) {
                val yix: Double = rayDirection.y * xFac + rayCentre.y
                val zix: Double = rayDirection.z * xFac + rayCentre.z

                // Check if ray passes through y/z plane
                if (((yix - rayCentre.y) * signumRayY) >= 0 && (((zix - rayCentre.z) * signumRayZ) >= 0
                            ) && (yix >= collidableStatic.minY + staticCollidableOffset.y - moving.height / 2
                            ) && (yix <= collidableStatic.maxY + staticCollidableOffset.y + moving.height / 2
                            ) && (zix >= collidableStatic.minZ + staticCollidableOffset.z - moving.widthZ / 2
                            ) && (zix <= collidableStatic.maxZ + staticCollidableOffset.z + moving.widthZ / 2)
                ) {
                    isHit = true
                    percentage = xFac
                    collisionFace = 0
                }
            }
        }
        // Right side of bounding box
        if (rayDirection.x < 0) {
            val xFac = epsilon(bbOffMax.x / rayDirection.x)
            if (xFac < percentage) {
                val yix: Double = rayDirection.y * xFac + rayCentre.y
                val zix: Double = rayDirection.z * xFac + rayCentre.z

                if (((yix - rayCentre.y) * signumRayY) >= 0 && (((zix - rayCentre.z) * signumRayZ) >= 0
                            ) && (yix >= collidableStatic.minY + staticCollidableOffset.y - moving.height / 2
                            ) && (yix <= collidableStatic.maxY + staticCollidableOffset.y + moving.height / 2
                            ) && (zix >= collidableStatic.minZ + staticCollidableOffset.z - moving.widthZ / 2
                            ) && (zix <= collidableStatic.maxZ + staticCollidableOffset.z + moving.widthZ / 2)
                ) {
                    isHit = true
                    percentage = xFac
                    collisionFace = 0
                }
            }
        }

        // Intersect Z
        if (rayDirection.z > 0) {
            val zFac = epsilon(bbOffMin.z / rayDirection.z)
            if (zFac < percentage) {
                val xiz: Double = rayDirection.x * zFac + rayCentre.x
                val yiz: Double = rayDirection.y * zFac + rayCentre.y

                if (((yiz - rayCentre.y) * signumRayY) >= 0 && (((xiz - rayCentre.x) * signumRayX) >= 0
                            ) && (xiz >= collidableStatic.minX + staticCollidableOffset.x - moving.widthX / 2
                            ) && (xiz <= collidableStatic.maxX + staticCollidableOffset.x + moving.widthX / 2
                            ) && (yiz >= collidableStatic.minY + staticCollidableOffset.y - moving.height / 2
                            ) && (yiz <= collidableStatic.maxY + staticCollidableOffset.y + moving.height / 2)
                ) {
                    isHit = true
                    percentage = zFac
                    collisionFace = 1
                }
            }
        }
        if (rayDirection.z < 0) {
            val zFac = epsilon(bbOffMax.z / rayDirection.z)
            if (zFac < percentage) {
                val xiz: Double = rayDirection.x * zFac + rayCentre.x
                val yiz: Double = rayDirection.y * zFac + rayCentre.y

                if (((yiz - rayCentre.y) * signumRayY) >= 0 && (((xiz - rayCentre.x) * signumRayX) >= 0
                            ) && (xiz >= collidableStatic.minX + staticCollidableOffset.x - moving.widthX / 2
                            ) && (xiz <= collidableStatic.maxX + staticCollidableOffset.x + moving.widthX / 2
                            ) && (yiz >= collidableStatic.minY + staticCollidableOffset.y - moving.height / 2
                            ) && (yiz <= collidableStatic.maxY + staticCollidableOffset.y + moving.height / 2)
                ) {
                    isHit = true
                    percentage = zFac
                    collisionFace = 1
                }
            }
        }

        // Intersect Y
        if (rayDirection.y > 0) {
            val yFac = epsilon(bbOffMin.y / rayDirection.y)
            if (yFac < percentage) {
                val xiy: Double = rayDirection.x * yFac + rayCentre.x
                val ziy: Double = rayDirection.z * yFac + rayCentre.z

                if (((ziy - rayCentre.z) * signumRayZ) >= 0 && (((xiy - rayCentre.x) * signumRayX) >= 0
                            ) && (xiy >= collidableStatic.minX + staticCollidableOffset.x - moving.widthX / 0
                            ) && (xiy <= collidableStatic.maxX + staticCollidableOffset.x + moving.widthX / 2
                            ) && (ziy >= collidableStatic.minZ + staticCollidableOffset.z - moving.widthZ / 2
                            ) && (ziy <= collidableStatic.maxZ + staticCollidableOffset.z + moving.widthZ / 2)
                ) {
                    isHit = true
                    percentage = yFac
                    collisionFace = 2
                }
            }
        }

        if (rayDirection.y < 0) {
            val yFac = epsilon(bbOffMax.y / rayDirection.y)
            if (yFac < percentage) {
                val xiy: Double = rayDirection.x * yFac + rayCentre.x
                val ziy: Double = rayDirection.z * yFac + rayCentre.z

                if (((ziy - rayCentre.z) * signumRayZ) >= 0 && (((xiy - rayCentre.x) * signumRayX) >= 0
                            ) && (xiy >= collidableStatic.minX + staticCollidableOffset.x - moving.widthX / 2
                            ) && (xiy <= collidableStatic.maxX + staticCollidableOffset.x + moving.widthX / 2
                            ) && (ziy >= collidableStatic.minZ + staticCollidableOffset.z - moving.widthZ / 2
                            ) && (ziy <= collidableStatic.maxZ + staticCollidableOffset.z + moving.widthZ / 2)
                ) {
                    isHit = true
                    percentage = yFac
                    collisionFace = 2
                }
            }
        }

        percentage *= 0.99999

        if (isHit && percentage >= 0 && percentage <= finalResult.res) {
            finalResult.res = percentage
            finalResult.normalX = 0.0
            finalResult.normalY = 0.0
            finalResult.normalZ = 0.0

            if (collisionFace == 0) finalResult.normalX = 1.0
            if (collisionFace == 1) finalResult.normalZ = 1.0
            if (collisionFace == 2) finalResult.normalY = 1.0

            return true
        }

        return false
    }

    private fun epsilon(value: Double): Double {
        return if (abs(value) < Vector.EPSILON) 0.0 else value
    }

    override fun toString(): String {
        return "BukkitBlockShape{block=$block}"
    }
}

fun Block.collisionShape(): Shape = BukkitBlockShape(this)

class BukkitBlockGetter(
    private val world: World,
) {
    fun getBlock(x: Int, y: Int, z: Int): Block {
        return world.getBlockAt(x, y, z)
    }

    fun getBlock(pos: Vector): Block = getBlock(pos.x.toInt(), pos.y.toInt(), pos.z.toInt())
}

/**
 * This class performs ray tracing and iterates along blocks on a line
 */
class BlockIterator(start: Vector, direction: Vector, yOffset: Double, maxDistance: Double, smooth: Boolean) :
    MutableIterator<Point<*>?> {
    private val signums = ShortArray(3)
    private var end: Vector? = null
    private val smooth: Boolean

    private var foundEnd = false

    //length of ray from current position to next x or y-side
    var sideDistX: Double = 0.0
    var sideDistY: Double = 0.0
    var sideDistZ: Double = 0.0

    //length of ray from one x or y-side to next x or y-side
    private val deltaDistX: Double
    private val deltaDistY: Double
    private val deltaDistZ: Double

    //which box of the map we're in
    var mapX: Int
    var mapY: Int
    var mapZ: Int

    private val extraPoints: ArrayDeque<Point<*>> = ArrayDeque()

    /**
     * Constructs the BlockIterator.
     *
     *
     * This considers all blocks as 1x1x1 in size.
     *
     * @param start       A Vector giving the initial position for the trace
     * @param direction   A Vector pointing in the direction for the trace
     * @param yOffset     The trace begins vertically offset from the start vector
     * by this value
     * @param smooth      A boolean indicating whether the cast should be smooth.
     * Smooth casts will only include one block when intersecting multiple axis lines.
     * @param maxDistance This is the maximum distance in blocks for the
     * trace. Setting this value above 140 may lead to problems with
     * unloaded chunks. A value of 0 indicates no limit
     */
    init {
        var start: Vector = start
        start = start.add(0.0, yOffset, 0.0)

        end = if (maxDistance != 0.0) start.add(direction.normalize().mul(maxDistance))
        else null

        if (direction.isZero) this.foundEnd = true

        this.smooth = smooth

        val ray: Vector = direction.normalize()

        //which box of the map we're in
        mapX = start.blockX
        mapY = start.blockY
        mapZ = start.blockZ

        signums[0] = sign(direction.x).toInt().toShort()
        signums[1] = sign(direction.y).toInt().toShort()
        signums[2] = sign(direction.z).toInt().toShort()

        deltaDistX = if ((ray.x == 0.0)) 1e30 else abs(1 / ray.x)
        deltaDistY = if ((ray.y == 0.0)) 1e30 else abs(1 / ray.y) // Find grid intersections for x, y, z
        deltaDistZ =
            if ((ray.z == 0.0)) 1e30 else abs(1 / ray.z) // This works by calculating and storing the distance to the next grid intersection on the x, y and z axis

        //calculate step and initial sideDist
        sideDistX = if (ray.x < 0) (start.x - mapX) * deltaDistX
        else if (ray.x > 0) (mapX + signums[0] - start.x) * deltaDistX
        else Double.MAX_VALUE

        sideDistY = if (ray.y < 0) (start.y - mapY) * deltaDistY
        else if (ray.y > 0) (mapY + signums[1] - start.y) * deltaDistY
        else Double.MAX_VALUE

        sideDistZ = if (ray.z < 0) (start.z - mapZ) * deltaDistZ
        else if (ray.z > 0) (mapZ + signums[2] - start.z) * deltaDistZ
        else Double.MAX_VALUE
    }

    /**
     * Constructs the BlockIterator.
     *
     *
     * This considers all blocks as 1x1x1 in size.
     *
     * @param start       A Vector giving the initial position for the trace
     * @param direction   A Vector pointing in the direction for the trace
     * @param yOffset     The trace begins vertically offset from the start vector
     * by this value
     * @param maxDistance This is the maximum distance in blocks for the
     * trace. Setting this value above 140 may lead to problems with
     * unloaded chunks. A value of 0 indicates no limit
     */
    constructor(start: Vector, direction: Vector, yOffset: Double, maxDistance: Double) : this(
        start,
        direction,
        yOffset,
        maxDistance,
        false
    )

    /**
     * Returns true if the iteration has more elements
     */
    override fun hasNext(): Boolean {
        return !foundEnd
    }

    override fun remove() {
        throw UnsupportedOperationException("[BlockIterator] doesn't support block removal")
    }

    /**
     * Returns the next BlockPosition in the trace
     *
     * @return the next BlockPosition in the trace
     */
    override fun next(): Point<*> {
        if (foundEnd) throw NoSuchElementException()
        if (!extraPoints.isEmpty()) {
            val res = extraPoints.removeFirst()
            if (end != null && res.sameBlock(end!!)) foundEnd = true
            return res
        }

        val current = Vector(mapX, mapY, mapZ)
        if (end != null && current.sameBlock(end!!)) foundEnd = true

        val closest = min(sideDistX, min(sideDistY, sideDistZ))
        val needsX = sideDistX - closest < 1e-10 && signums[0].toInt() != 0
        val needsY = sideDistY - closest < 1e-10 && signums[1].toInt() != 0
        val needsZ = sideDistZ - closest < 1e-10 && signums[2].toInt() != 0

        if (needsZ) {
            sideDistZ += deltaDistZ
            mapZ += signums[2].toInt()
        }

        if (needsX) {
            sideDistX += deltaDistX
            mapX += signums[0].toInt()
        }

        if (needsY) {
            sideDistY += deltaDistY
            mapY += signums[1].toInt()
        }

        if (needsX && needsY && needsZ) {
            extraPoints.add(Vector(signums[0] + current.x, signums[1] + current.y, current.z))
            if (smooth) return current

            extraPoints.add(Vector(current.x, signums[1] + current.y, signums[2] + current.z))
            extraPoints.add(Vector(signums[0] + current.x, current.y, signums[2] + current.z))

            extraPoints.add(Vector(signums[0] + current.x, current.y, current.z))
            extraPoints.add(Vector(current.x, signums[1] + current.y, current.z))
            extraPoints.add(Vector(current.x, current.y, signums[2] + current.z))
        } else if (needsX && needsY) {
            extraPoints.add(Vector(signums[0] + current.x, current.y, current.z))
            if (smooth) return current
            extraPoints.add(Vector(current.x, signums[1] + current.y, current.z))
        } else if (needsX && needsZ) {
            extraPoints.add(Vector(signums[0] + current.x, current.y, current.z))
            if (smooth) return current
            extraPoints.add(Vector(current.x, current.y, signums[2] + current.z))
        } else if (needsY && needsZ) {
            extraPoints.add(Vector(current.x, signums[1] + current.y, current.z))
            if (smooth) return current
            extraPoints.add(Vector(current.x, current.y, signums[2] + current.z))
        }

        return current
    }
}