package com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost

import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.shouldBeGreaterThan
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.Material
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock

class SpaceAwareCostProcessorSpec : FunSpec() {
    private lateinit var server: ServerMock
    private lateinit var world: WorldMock

    private val processor = SpaceAwareCostProcessor(entityHeight = 1.8)

    private fun contextAt(x: Int, y: Int, z: Int): EvaluationContext {
        val context = mockk<EvaluationContext>()
        every { context.currentPathPosition } returns PathPosition(x.toDouble(), y.toDouble(), z.toDouble())
        every { context.environmentContext } returns BukkitEnvironmentContext(world)
        return context
    }

    private fun placeWall(x: Int, z: Int, baseY: Int = 64, height: Int = 3) {
        repeat(height) { offset ->
            world.getBlockAt(x, baseY + offset, z).type = Material.STONE
        }
    }

    private fun costAt(x: Int, y: Int, z: Int): Double =
        processor.calculateCostContribution(contextAt(x, y, z)).value()

    init {
        beforeTest {
            server = MockBukkit.mock()
            world = server.addSimpleWorld("space-aware-world")
        }

        afterTest {
            MockBukkit.unmock()
        }

        test("open space with no walls costs nothing") {
            costAt(0, 64, 0) shouldBe 0.0
        }

        test("a wall on only one side does not pull the path off its line") {
            for (z in -10..10) placeWall(2, z)

            costAt(0, 64, 0) shouldBe 0.0
            costAt(1, 64, 0) shouldBe 0.0
        }

        test("off-center positions in a corridor cost more than centered ones") {
            for (z in -10..10) {
                placeWall(-1, z)
                placeWall(7, z)
            }

            val centered = costAt(3, 64, 0)
            val offCenter = costAt(1, 64, 0)

            offCenter shouldBeGreaterThan centered
            offCenter shouldBeGreaterThan 0.0
        }

        test("tight corridors are not penalized so they stay navigable") {
            for (z in -10..10) {
                placeWall(-1, z)
                placeWall(1, z)
            }

            costAt(0, 64, 0) shouldBe 0.0
        }
    }
}
