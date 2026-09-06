package com.typewritermc.visibility

import com.typewritermc.engine.paper.utils.PlayerHides
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin
import org.koin.core.context.startKoin
import org.koin.core.context.stopKoin
import org.koin.dsl.module
import org.mockbukkit.mockbukkit.MockBukkit
import org.mockbukkit.mockbukkit.ServerMock
import org.mockbukkit.mockbukkit.entity.PlayerMock
import java.util.UUID

private data class ValueOwner(val name: String)

class VisibilityHideRegistrySpec : FunSpec({
    lateinit var server: ServerMock
    lateinit var plugin: Plugin
    lateinit var hides: PlayerHides
    lateinit var registry: VisibilityHideRegistry

    beforeTest {
        server = MockBukkit.mock()
        plugin = mockk<Plugin>(relaxed = true)
        every { plugin.isEnabled } returns true
        startKoin {
            modules(module {
                single<Plugin> { plugin }
                single { PlayerHides() }
            })
        }
        hides = org.koin.java.KoinJavaComponent.get(PlayerHides::class.java)
        registry = VisibilityHideRegistry()
    }

    afterTest {
        stopKoin()
        MockBukkit.unmock()
    }

    /**
     * The visibility extension no longer forgets on quit itself and relies on this handler, which the
     * plugin registers rather than any extension.
     */
    test("a player that quits is forgotten on both sides of every hide naming them") {
        val first = server.addPlayer("First")
        val second = server.addPlayer("Second")
        val leaver = server.addPlayer("Leaver")
        val owner = Any()

        hides.hide(owner, first, leaver)
        hides.hide(owner, leaver, second)
        hides.hide(owner, first, second)

        hides.onQuit(PlayerQuitEvent(leaver, null as String?, PlayerQuitEvent.QuitReason.DISCONNECTED))

        hides.ownerCount(first.uniqueId, leaver.uniqueId) shouldBe 0
        hides.ownerCount(leaver.uniqueId, second.uniqueId) shouldBe 0
        // A pair the leaver is not part of is left alone.
        hides.ownerCount(first.uniqueId, second.uniqueId) shouldBe 1
    }

    test("an owner that compares itself by value cannot release another owner's hide") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        // Two distinct owners that equals based bookkeeping would treat as one.
        val cinematic = ValueOwner("camera")
        val bound = ValueOwner("camera")

        hides.hide(cinematic, viewer, target)
        hides.hide(bound, viewer, target)
        hides.ownerCount(viewer.uniqueId, target.uniqueId) shouldBe 2

        hides.show(cinematic, viewer.uniqueId, target.uniqueId)
        viewer.canSee(target) shouldBe false

        hides.show(bound, viewer.uniqueId, target.uniqueId)
        viewer.canSee(target) shouldBe true
    }

    test("releasing an owner gives back every pair it held and leaves the others alone") {
        val viewer = server.addPlayer("Viewer")
        val first = server.addPlayer("First")
        val second = server.addPlayer("Second")
        val cinematic = Any()
        val rule = Any()

        hides.hide(cinematic, viewer, first)
        hides.hide(cinematic, viewer, second)
        hides.hide(rule, viewer, second)

        hides.release(cinematic)

        viewer.canSee(first) shouldBe true
        viewer.canSee(second) shouldBe false
        hides.ownerCount(viewer.uniqueId, second.uniqueId) shouldBe 1
    }

    test("a hide is undone right away while both players are online") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")

        registry.hide(viewer, target)
        viewer.canSee(target) shouldBe false

        registry.show(viewer.uniqueId, target.uniqueId)
        viewer.canSee(target) shouldBe true
        hides.ownerCount(viewer.uniqueId, target.uniqueId) shouldBe 0
    }

    test("a hide of a target that left is forgotten instead of kept") {
        val viewer = server.addPlayer("Viewer")
        val targetId = UUID.randomUUID()
        val target = PlayerMock(server, "Target", targetId)
        server.addPlayer(target)

        registry.hide(viewer, target)
        target.disconnect()

        registry.show(viewer.uniqueId, targetId)

        hides.ownerCount(viewer.uniqueId, targetId) shouldBe 0
    }

    test("releasing the rule's hide keeps the target hidden while a cinematic still wants it") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        val cinematic = Any()

        hides.hide(cinematic, viewer, target)
        registry.hide(viewer, target)

        registry.show(viewer.uniqueId, target.uniqueId)

        hides.ownerCount(viewer.uniqueId, target.uniqueId) shouldBe 1
        viewer.canSee(target) shouldBe false

        hides.show(cinematic, viewer.uniqueId, target.uniqueId)
        viewer.canSee(target) shouldBe true
    }

    test("a cinematic releasing its own hide keeps the rule's hide in place") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")
        val cinematic = Any()

        hides.hide(cinematic, viewer, target)
        registry.hide(viewer, target)

        hides.release(cinematic)

        viewer.canSee(target) shouldBe false
        hides.ownerCount(viewer.uniqueId, target.uniqueId) shouldBe 1
    }

    test("hiding the same pair twice for one owner still only needs one release") {
        val viewer = server.addPlayer("Viewer")
        val target = server.addPlayer("Target")

        registry.hide(viewer, target)
        registry.hide(viewer, target)
        hides.ownerCount(viewer.uniqueId, target.uniqueId) shouldBe 1

        registry.show(viewer.uniqueId, target.uniqueId)
        viewer.canSee(target) shouldBe true
    }

    test("hiding a player from themselves is a no op") {
        val player = server.addPlayer("Player")

        registry.hide(player, player)

        hides.ownerCount(player.uniqueId, player.uniqueId) shouldBe 0
        player.canSee(player) shouldBe true
    }
})
