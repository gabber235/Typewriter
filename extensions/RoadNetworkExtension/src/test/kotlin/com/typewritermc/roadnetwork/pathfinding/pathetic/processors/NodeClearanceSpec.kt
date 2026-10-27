package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.Material
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.util.BoundingBox

class NodeClearanceSpec : FunSpec({
    val fullBlock = BoundingBox(0.0, 0.0, 0.0, 1.0, 1.0, 1.0)
    val node = PathPosition(0.0, 64.0, 0.0)
    val previousAlongZ = PathPosition(0.0, 64.0, -1.0)

    fun worldWith(shapes: Map<Triple<Int, Int, Int>, List<BoundingBox>>): World {
        val world = mockk<World>()
        every { world.getBlockAt(any<Int>(), any<Int>(), any<Int>()) } answers {
            val x = firstArg<Int>()
            val y = secondArg<Int>()
            val z = thirdArg<Int>()
            mockk<Block>(relaxed = true) {
                every { this@mockk.x } returns x
                every { this@mockk.y } returns y
                every { this@mockk.z } returns z
                every { type } returns Material.STONE
                every { collisionShape.boundingBoxes } returns shapes[Triple(x, y, z)].orEmpty()
            }
        }
        return world
    }

    fun clearanceWith(vararg shapes: Pair<Triple<Int, Int, Int>, List<BoundingBox>>) =
        NodeClearance(worldWith(mapOf(Triple(0, 63, 0) to listOf(fullBlock)) + shapes), EntityPathingCapabilities())

    test("an entity on open ground fits without a sidestep") {
        val clearance = clearanceWith()

        clearance.isObstructed(clearance.entityCenter(node)).shouldBeFalse()
        clearance.sidestep(node, previousAlongZ).shouldBeNull()
    }

    test("a thin obstacle on one side of the node is avoided by stepping away from it") {
        val post = BoundingBox(0.6, 0.0, 0.0, 0.75, 1.5, 1.0)
        val clearance = clearanceWith(Triple(0, 64, 0) to listOf(post))

        clearance.isObstructed(clearance.entityCenter(node)).shouldBeTrue()
        val sidestep = clearance.sidestep(node, previousAlongZ).shouldNotBeNull()
        sidestep.direction.x shouldBe -1.0
        sidestep.direction.z shouldBe (0.0 plusOrMinus 1e-9)
        sidestep.distance shouldBe (0.3 plusOrMinus 1e-9)
    }

    test("an obstacle too wide to step around has no sidestep") {
        val gate = BoundingBox(0.0, 0.0, 0.375, 1.0, 1.5, 0.625)
        val clearance = clearanceWith(Triple(0, 64, 0) to listOf(gate))

        clearance.sidestep(node, PathPosition(-1.0, 64.0, 0.0)).shouldBeNull()
    }

    test("a closed bottom trapdoor on the floor of the node does not obstruct it") {
        val trapdoor = BoundingBox(0.0, 0.0, 0.0, 1.0, 0.1875, 1.0)
        val clearance = clearanceWith(Triple(0, 64, 0) to listOf(trapdoor))

        clearance.isObstructed(clearance.entityCenter(node)).shouldBeFalse()
    }
})
