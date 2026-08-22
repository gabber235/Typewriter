package com.typewritermc.basic.entries.audience

import com.github.retrooper.packetevents.protocol.world.waypoint.EmptyWaypointInfo
import com.github.retrooper.packetevents.protocol.world.waypoint.Vec3iWaypointInfo
import com.github.retrooper.packetevents.util.Vector3i
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.utils.Color
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import java.util.UUID

class LocatorBarAudienceEntryTest : FunSpec({
    val testWorld = World("world")
    val otherWorld = World("other")
    val identifier = UUID.fromString("c192f308-b26a-41e5-8955-8e77f1a742de")

    fun position(world: World = testWorld, x: Double = 1.0) = Position(world, x, 2.0, 3.0)

    test("a target in the player's world starts tracking") {
        val change = nextLocatorBarChange(null, testWorld, position(), createIdentifier = { identifier })

        change shouldBe LocatorBarChange.Track(LocatorBar(identifier, position()))
    }

    test("an unchanged block position sends no update") {
        val current = LocatorBar(identifier, position())

        nextLocatorBarChange(current, testWorld, position()) shouldBe null
    }

    test("a changed block position updates the existing locator") {
        val current = LocatorBar(identifier, position())
        val change = nextLocatorBarChange(current, testWorld, position(x = 5.0))

        change shouldBe LocatorBarChange.Update(LocatorBar(identifier, position(x = 5.0)))
    }

    test("positions in the same block do not send redundant updates") {
        val current = LocatorBar(identifier, position(x = 1.0))

        nextLocatorBarChange(current, testWorld, position(x = 1.9)) shouldBe null
    }

    test("a target in another world is not tracked") {
        nextLocatorBarChange(null, testWorld, position(otherWorld)) shouldBe null
    }

    test("a tracked target is removed after it moves to another world") {
        val current = LocatorBar(identifier, position())

        nextLocatorBarChange(current, testWorld, position(otherWorld)) shouldBe LocatorBarChange.Untrack(identifier)
    }

    test("a tracked waypoint contains the locator identifier, color and block position") {
        val waypoint = LocatorBar(identifier, position(x = 4.0)).toTrackedWaypoint(Color(0xFF123456.toInt()))
        val waypointPosition = waypoint.info as Vec3iWaypointInfo

        waypoint.identifier.left shouldBe identifier
        waypoint.icon.color?.asRGB() shouldBe 0x123456
        waypointPosition.position shouldBe Vector3i(4, 2, 3)
    }

    test("an untracked waypoint only carries its identifier") {
        val waypoint = identifier.toUntrackedWaypoint()

        waypoint.identifier.left shouldBe identifier
        waypoint.info shouldBe EmptyWaypointInfo.EMPTY
        waypoint.icon.color shouldBe null
    }
})
