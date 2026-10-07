package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerItemHeldEvent
import org.bukkit.inventory.PlayerInventory
import java.util.UUID

class EditorInputSpec : FunSpec({
    test("scrolling up by one is a positive step") {
        scrollSteps(previousSlot = 3, newSlot = 2) shouldBe 1
        scrollSteps(previousSlot = 3, newSlot = 4) shouldBe -1
    }

    test("scrolling across the hotbar wrap takes the short way") {
        scrollSteps(previousSlot = 0, newSlot = 8) shouldBe 1
        scrollSteps(previousSlot = 8, newSlot = 0) shouldBe -1
        scrollSteps(previousSlot = 1, newSlot = 7) shouldBe 3
    }

    test("no slot change is zero steps") {
        scrollSteps(previousSlot = 4, newSlot = 4) shouldBe 0
    }

    fun SpectatorInputTracker.press(
        locked: Boolean,
        forward: Boolean = false,
        backward: Boolean = false,
        left: Boolean = false,
        right: Boolean = false,
        jump: Boolean = false,
        sneak: Boolean = false,
        sprint: Boolean = false,
    ): List<SpectatorSignal> = update(locked, forward, backward, left, right, jump, sneak, sprint)

    test("jump and sneak together fire the lock chord once and re-arm on release") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = false, sneak = true) shouldBe emptyList()
        tracker.press(locked = false, sneak = true, jump = true) shouldBe listOf(SpectatorSignal.LockChord)
        tracker.press(locked = false, sneak = true, jump = true) shouldBe emptyList()
        tracker.press(locked = false) shouldBe emptyList()
        tracker.press(locked = false, sneak = true, jump = true) shouldBe listOf(SpectatorSignal.LockChord)
    }

    test("the keys forming the lock chord never nudge on release") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = false, sneak = true, jump = true) shouldBe listOf(SpectatorSignal.LockChord)
        tracker.press(locked = true) shouldBe emptyList()
    }

    test("locked movement keys fire on press, not on hold") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = true, forward = true) shouldBe listOf(SpectatorSignal.Key(SpectatorKey.FORWARD))
        tracker.press(locked = true, forward = true) shouldBe emptyList()
        tracker.press(locked = true, forward = true, left = true) shouldBe listOf(SpectatorSignal.Key(SpectatorKey.LEFT))
    }

    test("a locked jump or sneak tap nudges on release") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = true, jump = true) shouldBe emptyList()
        tracker.press(locked = true) shouldBe listOf(SpectatorSignal.Key(SpectatorKey.UP))
        tracker.press(locked = true, sneak = true) shouldBe emptyList()
        tracker.press(locked = true) shouldBe listOf(SpectatorSignal.Key(SpectatorKey.DOWN))
    }

    test("sprint marks while locked and consumes a held sneak") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = true, sneak = true) shouldBe emptyList()
        tracker.press(locked = true, sneak = true, sprint = true) shouldBe listOf(SpectatorSignal.Key(SpectatorKey.MARK))
        tracker.press(locked = true) shouldBe emptyList()
    }

    test("sprint and sneak fire the secondary chord only in free flight") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = false, sneak = true) shouldBe emptyList()
        tracker.press(locked = false, sneak = true, sprint = true) shouldBe listOf(SpectatorSignal.SecondaryChord)
        tracker.press(locked = false, sneak = true, sprint = true) shouldBe emptyList()
    }

    test("unlocking with the chord while sneak stays held does not fire the secondary chord") {
        val tracker = SpectatorInputTracker()
        tracker.press(locked = true, sneak = true, jump = true) shouldBe listOf(SpectatorSignal.LockChord)
        tracker.press(locked = false, sneak = true) shouldBe emptyList()
        tracker.press(locked = false, sneak = true, sprint = true) shouldBe listOf(SpectatorSignal.SecondaryChord)
    }

    test("cardinal directions follow the yaw quadrants") {
        cardinalFromYaw(0f) shouldBe Vector(0.0, 0.0, 1.0)
        cardinalFromYaw(90f) shouldBe Vector(-1.0, 0.0, 0.0)
        cardinalFromYaw(180f) shouldBe Vector(0.0, 0.0, -1.0)
        cardinalFromYaw(-90f) shouldBe Vector(1.0, 0.0, 0.0)
        cardinalFromYaw(44f) shouldBe Vector(0.0, 0.0, 1.0)
        cardinalFromYaw(46f) shouldBe Vector(-1.0, 0.0, 0.0)
    }

    test("locked key directions are view relative") {
        spectatorKeyDirection(SpectatorKey.FORWARD, 0f) shouldBe Vector(0.0, 0.0, 1.0)
        spectatorKeyDirection(SpectatorKey.BACKWARD, 0f) shouldBe Vector(0.0, 0.0, -1.0)
        spectatorKeyDirection(SpectatorKey.LEFT, 0f) shouldBe Vector(1.0, 0.0, 0.0)
        spectatorKeyDirection(SpectatorKey.RIGHT, 0f) shouldBe Vector(-1.0, 0.0, 0.0)
        spectatorKeyDirection(SpectatorKey.UP, 0f) shouldBe Vector(0.0, 1.0, 0.0)
        spectatorKeyDirection(SpectatorKey.DOWN, 0f) shouldBe Vector(0.0, -1.0, 0.0)
        spectatorKeyDirection(SpectatorKey.MARK, 0f) shouldBe null
    }

    test("half grid snapping rounds to the nearest half block") {
        snapToHalfGrid(10.2) shouldBe 10.0
        snapToHalfGrid(10.3) shouldBe 10.5
        snapToHalfGrid(10.75) shouldBe 11.0
        snapToHalfGrid(-3.2) shouldBe -3.0
        snapToHalfGrid(-3.3) shouldBe -3.5
    }

    fun scrollingPlayer(): Pair<Player, PlayerInventory> {
        val inventory = mockk<PlayerInventory>(relaxed = true)
        val player = mockk<Player>(relaxed = true) {
            every { uniqueId } returns UUID.randomUUID()
            every { getInventory() } returns inventory
        }
        return player to inventory
    }

    test("a consumed scroll cancels the switch and resyncs the client's slot") {
        val (player, inventory) = scrollingPlayer()
        val listener = ScrollListener(player) { _, _ -> true }

        val event = PlayerItemHeldEvent(player, 1, 2)
        listener.onHeldItemChange(event)

        event.isCancelled shouldBe true
        verify { inventory.heldItemSlot = 1 }
    }

    test("a declined scroll right after a consumed one is swallowed, not switched") {
        val (player, _) = scrollingPlayer()
        var consume = true
        val listener = ScrollListener(player) { _, _ -> consume }

        listener.onHeldItemChange(PlayerItemHeldEvent(player, 1, 2))
        consume = false
        val burstTail = PlayerItemHeldEvent(player, 1, 2)
        listener.onHeldItemChange(burstTail)

        burstTail.isCancelled shouldBe true
    }

    test("a declined scroll with no gesture in flight switches items normally") {
        val (player, inventory) = scrollingPlayer()
        val listener = ScrollListener(player) { _, _ -> false }

        val event = PlayerItemHeldEvent(player, 1, 2)
        listener.onHeldItemChange(event)

        event.isCancelled shouldBe false
        verify(exactly = 0) { inventory.heldItemSlot = any<Int>() }
    }

    test("another player's slot change is ignored") {
        val (player, _) = scrollingPlayer()
        val (other, _) = scrollingPlayer()
        var called = false
        val listener = ScrollListener(player) { _, _ ->
            called = true
            true
        }

        val event = PlayerItemHeldEvent(other, 1, 2)
        listener.onHeldItemChange(event)

        called shouldBe false
        event.isCancelled shouldBe false
    }

    test("a teleport onto the lock anchor does not count as leaving it") {
        val anchor = Location(null, 10.0, 64.0, -3.0, 90f, 20f)
        leavesAnchor(Location(null, 10.0, 64.0, -3.0, 0f, 0f), anchor) shouldBe false
    }

    test("a teleport anywhere else leaves the anchor") {
        val anchor = Location(null, 10.0, 64.0, -3.0)
        leavesAnchor(Location(null, 10.0, 64.0, -2.0), anchor) shouldBe true
        leavesAnchor(Location(null, 10.5, 64.0, -3.0), anchor) shouldBe true
        leavesAnchor(Location(null, 10.0, 70.0, -3.0), anchor) shouldBe true
    }
})
