package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.pathing.processing.context.SearchContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.mockk.every
import io.mockk.mockk
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.util.BoundingBox
import org.mockbukkit.mockbukkit.MockBukkit
import java.util.UUID

class ReachabilityProcessorSpec : FunSpec({
    val fullBlock = BoundingBox(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)

    fun worldWithStone(stone: Set<Triple<Int, Int, Int>>): World {
        val world = mockk<World>(relaxed = true)
        every { world.uid } returns UUID.randomUUID()

        fun blockAt(x: Int, y: Int, z: Int): Block {
            val isStone = Triple(x, y, z) in stone
            return mockk<Block>(relaxed = true) {
                every { this@mockk.x } returns x
                every { this@mockk.y } returns y
                every { this@mockk.z } returns z
                every { type } returns if (isStone) Material.STONE else Material.AIR
                every { isSolid } returns isStone
                every { isLiquid } returns false
                every { collisionShape.boundingBoxes } returns if (isStone) listOf(fullBlock) else emptyList()
            }
        }

        every { world.getBlockAt(any<Int>(), any<Int>(), any<Int>()) } answers {
            blockAt(firstArg(), secondArg(), thirdArg())
        }
        every { world.getBlockAt(any<Location>()) } answers {
            val location = firstArg<Location>()
            blockAt(location.blockX, location.blockY, location.blockZ)
        }
        return world
    }

    fun floorAndBlocks(vararg blocks: Triple<Int, Int, Int>): Set<Triple<Int, Int, Int>> {
        val floor = (-3..3).flatMap { x -> (-3..3).map { z -> Triple(x, 63, z) } }
        return (floor + blocks).toSet()
    }

    fun isReachable(world: World, from: PathPosition, to: PathPosition): Boolean {
        val sharedData = mutableMapOf<String, Any>()
        val searchContext = mockk<SearchContext> { every { this@mockk.sharedData } returns sharedData }
        val nodeTypeProcessor = NodeTypeProcessor()
        val obstructionProcessor = ObstructionProcessor()
        val reachabilityProcessor = ReachabilityProcessor()
        nodeTypeProcessor.initializeSearch(searchContext)
        obstructionProcessor.initializeSearch(searchContext)

        fun contextFor(position: PathPosition, previous: PathPosition?) = mockk<EvaluationContext> {
            every { currentPathPosition } returns position
            every { previousPathPosition } returns previous
            every { environmentContext } returns BukkitEnvironmentContext(world)
            every { this@mockk.sharedData } returns sharedData
        }

        listOf(contextFor(from, null), contextFor(to, from)).forEach { context ->
            nodeTypeProcessor.isValid(context)
            obstructionProcessor.isValid(context)
        }
        return reachabilityProcessor.isValid(contextFor(to, from))
    }

    beforeTest { MockBukkit.mock() }
    afterTest { MockBukkit.unmock() }

    test("a straight jump onto a block is reachable") {
        val world = worldWithStone(floorAndBlocks(Triple(1, 64, 0)))

        isReachable(world, PathPosition(0.0, 64.0, 0.0), PathPosition(1.0, 65.0, 0.0)).shouldBeTrue()
    }

    test("a diagonal jump over a block corner is reachable") {
        val world = worldWithStone(floorAndBlocks(Triple(1, 64, 1), Triple(1, 64, 0)))

        isReachable(world, PathPosition(0.0, 64.0, 0.0), PathPosition(1.0, 65.0, 1.0)).shouldBeTrue()
    }

    test("a diagonal jump past the corner of a wall is not reachable") {
        val world = worldWithStone(floorAndBlocks(Triple(1, 64, 1), Triple(1, 64, 0), Triple(1, 65, 0)))

        isReachable(world, PathPosition(0.0, 64.0, 0.0), PathPosition(1.0, 65.0, 1.0)).shouldBeFalse()
    }
})
