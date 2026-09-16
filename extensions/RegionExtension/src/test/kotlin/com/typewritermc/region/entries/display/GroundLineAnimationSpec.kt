package com.typewritermc.region.entries.display

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.doubles.plusOrMinus
import io.kotest.matchers.floats.plusOrMinus
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import java.time.Duration

/**
 * A bare [Var.get] call resolves an interaction context through Koin (see
 * [com.typewritermc.engine.paper.interaction.interactionContext]), even for a [ConstVar] whose
 * value never depends on it, so this spec needs the same minimal Koin bootstrap
 * `RegionEngineSpec` uses, not MockBukkit.
 */
class GroundLineAnimationSpec : FunSpec({
    val player = mockk<Player>(relaxed = true)

    beforeSpec {
        startKoin {
            modules(module { single { mockk<PlayerSessionManager>(relaxed = true) } })
        }
    }

    afterSpec {
        stopKoin()
    }

    fun point(x: Double, z: Double) = GroundOutlinePoint(Vector(x, 64.0, z), Vector.ZERO)

    /** A square walked east, south, west, north: clockwise seen from above. */
    fun square(): List<GroundOutlinePoint> {
        val points = mutableListOf<GroundOutlinePoint>()
        for (x in 0 until 10) points += point(x.toDouble(), 0.0)
        for (z in 0 until 10) points += point(10.0, z.toDouble())
        for (x in 10 downTo 1) points += point(x.toDouble(), 10.0)
        for (z in 10 downTo 1) points += point(0.0, z.toDouble())
        return points
    }

    val path = GroundLinePath(square())

    test("a static line does not flow") {
        val animation = StaticGroundLine()
        animation.blocksPerSecond(player) shouldBe 0.0
        groundLinePhase(animation, path, player, Duration.ofSeconds(5)) shouldBe 0.0
    }

    test("a clockwise line flows along a clockwise loop") {
        ClockwiseGroundLine(ConstVar(2.0)).direction(path) shouldBe 1
        CounterClockwiseGroundLine(ConstVar(2.0)).direction(path) shouldBe -1
    }

    test("a clockwise line flows against a counter clockwise loop") {
        val reversed = GroundLinePath(square().reversed())
        ClockwiseGroundLine(ConstVar(2.0)).direction(reversed) shouldBe -1
    }

    test("the phase advances at the configured speed") {
        val animation = ClockwiseGroundLine(ConstVar(2.0))
        groundLinePhase(animation, path, player, Duration.ofSeconds(3)) shouldBe (6.0 plusOrMinus 1e-6)
        groundLinePhase(CounterClockwiseGroundLine(ConstVar(2.0)), path, player, Duration.ofSeconds(3)) shouldBe
                (-6.0 plusOrMinus 1e-6)
    }

    test("outward and inward face opposite ways") {
        val point = PathPoint(Vector(10.0, 64.0, 0.0), Vector(1.0, 0.0, 0.0), Vector(0.0, 0.0, 1.0))
        FaceOutward().yaw(point, 1) shouldBe (-90f plusOrMinus 0.01f)
        FaceInward().yaw(point, 1) shouldBe (90f plusOrMinus 0.01f)
    }

    test("along the line follows the way the entities travel") {
        val point = PathPoint(Vector(10.0, 64.0, 0.0), Vector(1.0, 0.0, 0.0), Vector(0.0, 0.0, 1.0))
        // A tangent pointing south is yaw 0 in Minecraft.
        FaceAlongLine().yaw(point, 1) shouldBe (0f plusOrMinus 0.01f)
        FaceAlongLine().yaw(point, -1) shouldBe (180f plusOrMinus 0.01f)
        FaceAgainstLine().yaw(point, 1) shouldBe (180f plusOrMinus 0.01f)
    }
})
