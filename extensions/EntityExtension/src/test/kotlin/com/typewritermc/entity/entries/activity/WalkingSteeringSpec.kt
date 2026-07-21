package com.typewritermc.entity.entries.activity

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.floats.plusOrMinus
import io.kotest.matchers.shouldBe

class WalkingSteeringSpec : FunSpec({
    val world = World("walking-world")

    fun positionAt(x: Double, y: Double, z: Double, yaw: Float = 0f, pitch: Float = 0f) =
        PositionProperty(world, x, y, z, yaw, pitch)

    context("walkingLookRotation") {
        test("a target ahead on flat ground keeps the head level") {
            val location = positionAt(0.5, 65.0, 0.5)
            val (_, pitch) = walkingLookRotation(location, Vector(3.5, 65.0, 0.5), Velocity(0f), Velocity(0f))

            pitch shouldBe (0f plusOrMinus 1f)
        }

        test("a target ahead turns the yaw towards it") {
            val location = positionAt(0.5, 65.0, 0.5, yaw = 0f)
            var yaw = location.yaw
            val yawVelocity = Velocity(0f)
            repeat(40) {
                yaw = walkingLookRotation(
                    positionAt(0.5, 65.0, 0.5, yaw = yaw),
                    Vector(3.5, 65.0, 0.5),
                    yawVelocity,
                    Velocity(0f),
                ).first
            }

            yaw shouldBe (-90f plusOrMinus 2f)
        }

        test("a node underneath the entity does not pitch the head down") {
            val location = positionAt(0.5, 65.0, 0.5)
            val (_, pitch) = walkingLookRotation(location, Vector(0.6, 64.0, 0.5), Velocity(0f), Velocity(0f))

            pitch shouldBe (0f plusOrMinus 1f)
        }

        test("a head already pitched down levels back out over a node underneath") {
            var pitch = 60f
            val pitchVelocity = Velocity(0f)
            repeat(40) {
                pitch = walkingLookRotation(
                    positionAt(0.5, 65.0, 0.5, pitch = pitch),
                    Vector(0.6, 64.0, 0.5),
                    Velocity(0f),
                    pitchVelocity,
                ).second
            }

            pitch shouldBe (0f plusOrMinus 2f)
        }

        test("a node underneath keeps the current yaw instead of spinning") {
            val location = positionAt(0.5, 65.0, 0.5, yaw = 42f)
            val (yaw, _) = walkingLookRotation(location, Vector(0.6, 64.0, 0.5), Velocity(0f), Velocity(0f))

            yaw shouldBe 42f
        }

        test("descending terrain still pitches the head down towards the slope") {
            val location = positionAt(0.5, 65.0, 0.5)
            var pitch = location.pitch
            val pitchVelocity = Velocity(0f)
            repeat(40) {
                pitch = walkingLookRotation(
                    positionAt(0.5, 65.0, 0.5, pitch = pitch),
                    Vector(3.5, 62.0, 0.5),
                    Velocity(0f),
                    pitchVelocity,
                ).second
            }

            pitch shouldBe (45f plusOrMinus 2f)
        }
    }
})
