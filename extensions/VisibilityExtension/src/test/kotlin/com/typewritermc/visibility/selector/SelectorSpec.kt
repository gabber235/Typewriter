package com.typewritermc.visibility.selector

import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.mockk.mockk
import org.bukkit.Location
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.UUID
import java.util.logging.Logger

class SelectorSpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var world: WorldMock

    beforeTest {
        server = MockBukkit.mock()
        world = server.addSimpleWorld("world")
        startKoin {
            modules(module {
                single { Logger.getLogger("SelectorSpec") }
                single { mockk<PlayerSessionManager>(relaxed = true) }
            })
        }
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    test("everyone selectors resolve to all online players") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")

        EveryoneViewerSelector().resolve() shouldContainExactlyInAnyOrder listOf(alice.uniqueId, bob.uniqueId)
        EveryoneTargetSelector().resolve() shouldContainExactlyInAnyOrder listOf(alice.uniqueId, bob.uniqueId)
    }

    test("specific player selector resolves by exact name") {
        val bob = server.addPlayer("Bob")
        server.addPlayer("Bobby")

        SpecificPlayerTargetSelector("Bob").resolve() shouldBe setOf(bob.uniqueId)
    }

    test("specific player selector resolves by uuid") {
        val bob = server.addPlayer("Bob")

        SpecificPlayerTargetSelector(bob.uniqueId.toString()).resolve() shouldBe setOf(bob.uniqueId)
    }

    test("specific player selector is empty for blank or unknown players") {
        server.addPlayer("Bob")

        SpecificPlayerTargetSelector("").resolve() shouldBe emptySet()
        SpecificPlayerTargetSelector("Unknown").resolve() shouldBe emptySet()
        SpecificPlayerTargetSelector(UUID.randomUUID().toString()).resolve() shouldBe emptySet()
    }

    test("radius selector only matches players within range in the same world") {
        val viewer = server.addPlayer("Viewer")
        val near = server.addPlayer("Near")
        val far = server.addPlayer("Far")
        val elsewhere = server.addPlayer("Elsewhere")
        val otherWorld = server.addSimpleWorld("other")

        viewer.teleport(Location(world, 0.0, 64.0, 0.0))
        near.teleport(Location(world, 3.0, 64.0, 4.0))
        far.teleport(Location(world, 100.0, 64.0, 0.0))
        elsewhere.teleport(Location(otherWorld, 0.0, 64.0, 0.0))

        val selector = RadiusTargetSelector(ConstVar(10.0))
        selector.viewerDependent shouldBe true
        selector.resolveFor(viewer, emptySet()) shouldBe setOf(viewer.uniqueId, near.uniqueId)
    }

    test("the viewer is within their own radius, which is what gives them a self pair") {
        val viewer = server.addPlayer("Viewer")
        viewer.teleport(Location(world, 0.0, 64.0, 0.0))

        // The ruler excludes a pair of a player with themselves from the normal rules, not the
        // selector. Dropping the viewer here would leave a radius rule unable to apply an effect to
        // the viewer's own view of themselves, which every other selector can.
        RadiusTargetSelector(ConstVar(10.0)).resolveFor(viewer, emptySet()) shouldBe setOf(viewer.uniqueId)
    }

    test("a player just outside the radius is kept while they were already selected") {
        val viewer = server.addPlayer("Viewer")
        val edge = server.addPlayer("Edge")
        viewer.teleport(Location(world, 0.0, 64.0, 0.0))
        edge.teleport(Location(world, 10.5, 64.0, 0.0))

        val selector = RadiusTargetSelector(ConstVar(10.0))
        val alone = setOf(viewer.uniqueId)

        selector.resolveFor(viewer, emptySet()) shouldBe alone
        selector.resolveFor(viewer, setOf(edge.uniqueId)) shouldBe alone + edge.uniqueId

        edge.teleport(Location(world, 11.5, 64.0, 0.0))
        selector.resolveFor(viewer, setOf(edge.uniqueId)) shouldBe alone
    }

    test("a non positive radius resolves to nothing") {
        val viewer = server.addPlayer("Viewer")
        val near = server.addPlayer("Near")
        viewer.teleport(Location(world, 0.0, 64.0, 0.0))
        near.teleport(Location(world, 1.0, 64.0, 0.0))

        RadiusTargetSelector(ConstVar(0.0)).resolveFor(viewer, emptySet()) shouldBe emptySet()
    }

    test("a radius that drops to zero also drops the players it had selected") {
        val viewer = server.addPlayer("Viewer")
        val near = server.addPlayer("Near")
        viewer.teleport(Location(world, 0.0, 64.0, 0.0))
        near.teleport(Location(world, 1.0, 64.0, 0.0))

        RadiusTargetSelector(ConstVar(0.0)).resolveFor(viewer, setOf(near.uniqueId)) shouldBe emptySet()
    }

})
