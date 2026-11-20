package com.typewritermc.visibility.rule

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.visibility.RecordingEffectEntry
import com.typewritermc.visibility.VisibilityEngine
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.selector.AudienceTargetSelector
import com.typewritermc.visibility.selector.AudienceViewerSelector
import com.typewritermc.visibility.selector.RadiusTargetSelector
import com.typewritermc.visibility.selector.SpecificPlayerTargetSelector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.nulls.shouldBeNull
import io.kotest.matchers.nulls.shouldNotBeNull
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.Location
import org.bukkit.entity.Player
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.world.WorldMock
import java.util.concurrent.CopyOnWriteArrayList
import java.util.logging.Logger

private suspend fun VisibilityRuler.tickOnce() {
    captureServerState()
    tick()
}

class StandardVisibilityRulerSpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var world: WorldMock
    lateinit var engine: VisibilityEngine
    lateinit var events: CopyOnWriteArrayList<String>
    lateinit var viewerMembers: MutableList<Player>
    lateinit var targetMembers: MutableList<Player>

    val viewersRef = Ref("viewers_audience", AudienceEntry::class)
    val targetsRef = Ref("targets_audience", AudienceEntry::class)

    beforeTest {
        server = MockBukkit.mock()
        world = server.addSimpleWorld("world")
        engine = VisibilityEngine()
        events = CopyOnWriteArrayList()
        viewerMembers = mutableListOf()
        targetMembers = mutableListOf()

        val viewersDisplay = mockk<AudienceDisplay>()
        every { viewersDisplay.playerIds } answers { viewerMembers.mapTo(HashSet()) { it.uniqueId } }
        val targetsDisplay = mockk<AudienceDisplay>()
        every { targetsDisplay.playerIds } answers { targetMembers.mapTo(HashSet()) { it.uniqueId } }
        val audienceManager = mockk<AudienceManager>()
        every { audienceManager[viewersRef] } returns viewersDisplay
        every { audienceManager[targetsRef] } returns targetsDisplay

        startKoin {
            modules(module {
                single { Logger.getLogger("StandardVisibilityRulerSpec") }
                single { engine }
                single { audienceManager }
                single { mockk<PlayerSessionManager>(relaxed = true) }
                single(named("isEnabled")) { true }
            })
        }
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    fun audienceRuler(effect: VisibilityEffectEntry) = StandardVisibilityRuler(
        viewers = AudienceViewerSelector(viewersRef),
        targets = AudienceTargetSelector(targetsRef),
        priority = 10,
        entryId = "audience_rule",
        effect = effect.ref(),
    )

    fun effect(id: String = "effect"): VisibilityEffectEntry = RecordingEffectEntry(id, events)

    test("creates rules for every viewer and target combination except self pairs") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += listOf(alice, bob)
        targetMembers += listOf(bob, carol)

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(alice.uniqueId, carol.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(bob.uniqueId, carol.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(bob.uniqueId, bob.uniqueId).shouldBeNull()
        events.count { it.endsWith(":initialize") } shouldBe 3
    }

    test("an unchanged selection does not touch the engine again") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        viewerMembers += alice
        targetMembers += bob

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        ruler.tickOnce()
        ruler.tickOnce()
        engine.awaitLifecycles()

        events shouldContainExactly listOf("effect:initialize")
    }

    test("a removed viewer loses only their own pairs") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += listOf(alice, bob)
        targetMembers += carol

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        viewerMembers.remove(alice)
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, carol.uniqueId).shouldBeNull()
        engine.activeRuleFor(bob.uniqueId, carol.uniqueId).shouldNotBeNull()
    }

    test("a player leaving the targets keeps the pairs where they are the viewer") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        viewerMembers += listOf(alice, bob)
        targetMembers += listOf(alice, bob)

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(bob.uniqueId, alice.uniqueId).shouldNotBeNull()

        targetMembers.remove(alice)
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(bob.uniqueId, alice.uniqueId).shouldBeNull()
        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
    }

    test("an added target creates pairs for all existing viewers") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += listOf(alice, bob)
        targetMembers += carol

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        val dave = server.addPlayer("Dave")
        targetMembers += dave
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, dave.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(bob.uniqueId, dave.uniqueId).shouldNotBeNull()
        events.count { it.endsWith(":initialize") } shouldBe 4
    }

    test("radius targets follow players moving in and out of range") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        alice.teleport(Location(world, 0.0, 64.0, 0.0))
        bob.teleport(Location(world, 5.0, 64.0, 0.0))
        viewerMembers += alice

        val ruler = StandardVisibilityRuler(
            viewers = AudienceViewerSelector(viewersRef),
            targets = RadiusTargetSelector(ConstVar(10.0)),
            priority = 10,
            entryId = "radius_rule",
            effect = effect().ref(),
        )

        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()

        bob.teleport(Location(world, 50.0, 64.0, 0.0))
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldBeNull()

        bob.teleport(Location(world, 3.0, 64.0, 0.0))
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
    }

    test("a viewer leaving the audience removes their radius pairs") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        alice.teleport(Location(world, 0.0, 64.0, 0.0))
        bob.teleport(Location(world, 5.0, 64.0, 0.0))
        viewerMembers += alice

        val ruler = StandardVisibilityRuler(
            viewers = AudienceViewerSelector(viewersRef),
            targets = RadiusTargetSelector(ConstVar(10.0)),
            priority = 10,
            entryId = "radius_rule",
            effect = effect().ref(),
        )

        ruler.tickOnce()
        viewerMembers.clear()
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldBeNull()
        events shouldContainExactly listOf("effect:initialize", "effect:dispose")
    }

    test("a specific player target only matches that player") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += alice

        val ruler = StandardVisibilityRuler(
            viewers = AudienceViewerSelector(viewersRef),
            targets = SpecificPlayerTargetSelector("Bob"),
            priority = 10,
            entryId = "specific_rule",
            effect = effect().ref(),
        )

        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(alice.uniqueId, carol.uniqueId).shouldBeNull()
    }

    test("disposing the ruler removes all of its rules") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        viewerMembers += alice
        targetMembers += bob

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        ruler.dispose()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldBeNull()
        events shouldContainExactly listOf("effect:initialize", "effect:dispose")
    }

    test("a disposed ruler that ticks again rebuilds the rules it dropped") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        viewerMembers += alice
        targetMembers += bob

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        ruler.dispose()
        engine.awaitLifecycles()

        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, bob.uniqueId).shouldNotBeNull()
        events shouldContainExactly listOf("effect:initialize", "effect:dispose", "effect:initialize")
    }

    test("a viewer joining after the first tick gets pairs with the targets already selected") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += alice
        targetMembers += carol

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        engine.awaitLifecycles()

        viewerMembers += bob
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(bob.uniqueId, carol.uniqueId).shouldNotBeNull()
        engine.viewerRuleCount(bob.uniqueId) shouldBe 1
    }

    test("a target leaving together with a viewer retracts the pair they shared") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        val carol = server.addPlayer("Carol")
        viewerMembers += listOf(alice, bob)
        targetMembers += carol

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        engine.awaitLifecycles()

        viewerMembers -= bob
        targetMembers -= carol
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(bob.uniqueId, carol.uniqueId).shouldBeNull()
        engine.activeRuleFor(alice.uniqueId, carol.uniqueId).shouldBeNull()
        engine.viewerRuleCount(alice.uniqueId) shouldBe 0
        engine.viewerRuleCount(bob.uniqueId) shouldBe 0
    }

    test("the ruler feeds last tick's selection back into the radius hysteresis") {
        val alice = server.addPlayer("Alice")
        val edge = server.addPlayer("Edge")
        viewerMembers += alice
        alice.teleport(Location(world, 0.0, 64.0, 0.0))
        edge.teleport(Location(world, 5.0, 64.0, 0.0))

        val ruler = StandardVisibilityRuler(
            viewers = AudienceViewerSelector(viewersRef),
            targets = RadiusTargetSelector(ConstVar(10.0)),
            priority = 10,
            entryId = "radius_rule",
            effect = effect().ref(),
        )
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, edge.uniqueId).shouldNotBeNull()

        // Past the radius but inside the exit margin, so a selected player is kept and only a ruler
        // that passes its previous selection to the selector can tell the difference.
        edge.teleport(Location(world, 10.5, 64.0, 0.0))
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, edge.uniqueId).shouldNotBeNull()

        edge.teleport(Location(world, 11.5, 64.0, 0.0))
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, edge.uniqueId).shouldBeNull()
    }

    test("creates a self pair for each target when the effect applies to self") {
        val alice = server.addPlayer("Alice")
        val bob = server.addPlayer("Bob")
        viewerMembers += alice
        targetMembers += listOf(alice, bob)

        val selfEffect = RecordingEffectEntry("self_effect", events, self = true, selfActive = true)
        val ruler = audienceRuler(selfEffect)
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldNotBeNull()
        engine.activeRuleFor(bob.uniqueId, bob.uniqueId).shouldNotBeNull()
    }

    test("does not create self pairs when the effect does not apply to self") {
        val alice = server.addPlayer("Alice")
        viewerMembers += alice
        targetMembers += alice

        val ruler = audienceRuler(effect())
        ruler.tickOnce()
        engine.awaitLifecycles()

        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldBeNull()
    }

    test("removes the self pair when the toggle turns off") {
        val alice = server.addPlayer("Alice")
        viewerMembers += alice
        targetMembers += alice

        val selfEffect = RecordingEffectEntry("self_effect", events, self = true, selfActive = true)
        val ruler = audienceRuler(selfEffect)
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldNotBeNull()

        selfEffect.selfActive = false
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldBeNull()
    }

    test("removes the self pair when the target leaves") {
        val alice = server.addPlayer("Alice")
        viewerMembers += alice
        targetMembers += alice

        val selfEffect = RecordingEffectEntry("self_effect", events, self = true, selfActive = true)
        val ruler = audienceRuler(selfEffect)
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldNotBeNull()

        targetMembers.clear()
        ruler.tickOnce()
        engine.awaitLifecycles()
        engine.activeRuleFor(alice.uniqueId, alice.uniqueId).shouldBeNull()
    }
})
