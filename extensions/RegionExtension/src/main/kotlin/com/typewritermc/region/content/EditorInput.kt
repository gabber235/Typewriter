package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import org.bukkit.GameMode
import org.bukkit.Location
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerGameModeChangeEvent
import org.bukkit.event.player.PlayerInputEvent
import org.bukkit.event.player.PlayerItemHeldEvent
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.event.player.PlayerRespawnEvent
import org.bukkit.event.player.PlayerTeleportEvent
import kotlin.math.abs
import kotlin.math.floor

/**
 * Turns hotbar scrolling into tool input. Minecraft has no scroll packet, so the held slot
 * change is the signal. The handler returns `true` to consume the scroll, which cancels
 * the slot switch and keeps the tool in hand; returning `false` lets the player switch
 * items normally.
 *
 * A consumed scroll also resends the held slot, because the client has already switched by
 * the time the cancelled packet arrives and can be left showing the wrong slot. And for
 * [CONSUME_GRACE_MILLIS] after a consumed scroll every further notch is swallowed even when
 * the handler declines it, so releasing sneak a moment before the wheel stops cannot switch
 * the hotbar away from the tool mid gesture.
 */
internal class ScrollListener(
    private val player: Player,
    private val onScroll: (heldSlot: Int, steps: Int) -> Boolean,
) : Listener {
    private var lastConsumedAt = 0L

    @EventHandler
    fun onHeldItemChange(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val steps = scrollSteps(event.previousSlot, event.newSlot)
        if (steps == 0) return
        val now = System.currentTimeMillis()
        val withinGrace = now - lastConsumedAt <= CONSUME_GRACE_MILLIS
        // A hotbar key arrives as the same packet as a wheel notch, and the two cannot be told
        // apart. The wheel only ever sends one notch per packet, so a wider jump is a builder
        // reaching for a tool, and answering it as a gesture would edit the geometry and refuse
        // the tool change at once. Inside the grace window it is the client catching up on
        // notches already answered, and letting those through would switch the hotbar away from
        // the tool mid gesture. A key press onto the neighbouring slot stays ambiguous either way.
        if (steps > 1 || steps < -1) {
            if (!withinGrace) return
            event.isCancelled = true
            player.inventory.heldItemSlot = event.previousSlot
            return
        }
        val consumed = onScroll(event.previousSlot, steps)
        if (!consumed && !withinGrace) return
        if (consumed) lastConsumedAt = now
        event.isCancelled = true
        player.inventory.heldItemSlot = event.previousSlot
    }

    private companion object {
        const val CONSUME_GRACE_MILLIS = 250L
    }
}

/** A key command from the locked spectator editing state. */
internal enum class SpectatorKey { FORWARD, BACKWARD, LEFT, RIGHT, UP, DOWN, MARK }

/** A recognized spectator gesture: the lock toggle chord, the free flight secondary chord, or a locked key. */
internal sealed interface SpectatorSignal {
    data object LockChord : SpectatorSignal
    data object SecondaryChord : SpectatorSignal
    data class Key(val key: SpectatorKey) : SpectatorSignal
}

/**
 * Interprets the raw spectator key states. A spectator client sends no left click, drop,
 * swap or hotbar packets (the vanilla client gates them out), but right clicks do arrive,
 * so those carry the click duties while the key states drive everything else.
 *
 * Jump plus sneak is the lock toggle in both states. Unlocked, sprint plus sneak is the
 * secondary gesture. Locked, WASD fire on press and sprint is [SpectatorKey.MARK]; jump
 * and sneak fire [SpectatorKey.UP] and [SpectatorKey.DOWN] on RELEASE, so a hold that
 * turns into the lock chord never also counts as a nudge.
 */
internal class SpectatorInputTracker {
    private var forward = false
    private var backward = false
    private var left = false
    private var right = false
    private var jump = false
    private var sneak = false
    private var sprint = false
    private var jumpConsumed = false
    private var sneakConsumed = false
    private var lockChordHeld = false
    private var secondaryChordHeld = false

    fun update(
        locked: Boolean,
        forward: Boolean,
        backward: Boolean,
        left: Boolean,
        right: Boolean,
        jump: Boolean,
        sneak: Boolean,
        sprint: Boolean,
    ): List<SpectatorSignal> {
        val signals = mutableListOf<SpectatorSignal>()

        val lockChord = jump && sneak
        if (lockChord && !lockChordHeld) {
            signals += SpectatorSignal.LockChord
            jumpConsumed = true
            sneakConsumed = true
        }
        val secondaryChord = sneak && sprint
        if (!locked && secondaryChord && !secondaryChordHeld && !lockChord && !lockChordHeld) {
            signals += SpectatorSignal.SecondaryChord
            sneakConsumed = true
        }

        if (locked && signals.isEmpty()) {
            if (forward && !this.forward) signals += SpectatorSignal.Key(SpectatorKey.FORWARD)
            if (backward && !this.backward) signals += SpectatorSignal.Key(SpectatorKey.BACKWARD)
            if (left && !this.left) signals += SpectatorSignal.Key(SpectatorKey.LEFT)
            if (right && !this.right) signals += SpectatorSignal.Key(SpectatorKey.RIGHT)
            if (sprint && !this.sprint) {
                signals += SpectatorSignal.Key(SpectatorKey.MARK)
                // A jump or sneak held through a mark reads as a modifier, not a pending nudge.
                if (jump) jumpConsumed = true
                if (sneak) sneakConsumed = true
            }
            if (!jump && this.jump && !jumpConsumed) signals += SpectatorSignal.Key(SpectatorKey.UP)
            if (!sneak && this.sneak && !sneakConsumed) signals += SpectatorSignal.Key(SpectatorKey.DOWN)
        }

        if (!jump) jumpConsumed = false
        if (!sneak) sneakConsumed = false
        this.forward = forward
        this.backward = backward
        this.left = left
        this.right = right
        this.jump = jump
        this.sneak = sneak
        this.sprint = sprint
        lockChordHeld = lockChord
        secondaryChordHeld = secondaryChord
        return signals
    }
}

/**
 * The spectator control scheme of the region editor.
 *
 * Free flight: jump + sneak locks the player in place, sprint + sneak is the secondary
 * gesture. Locked: the mode freezes movement with fly speed zero while [anchor] pins the
 * position against the client side scroll speed override, the camera stays free so the
 * player can still aim, and every key state change arrives here as a tool command. A
 * teleport, a game mode change or a quit while locked forces a release, so the frozen fly
 * speed can never leak out of the editing state.
 */
internal class SpectatorInputListener(
    private val player: Player,
    private val anchor: () -> Location?,
    private val onLockChord: () -> Unit,
    private val onSecondaryChord: () -> Unit,
    private val onKey: (SpectatorKey) -> Unit,
    private val onForcedRelease: () -> Unit,
) : Listener {
    private val tracker = SpectatorInputTracker()

    @EventHandler
    fun onInput(event: PlayerInputEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (event.player.gameMode != GameMode.SPECTATOR) return
        val input = event.input
        val signals = tracker.update(
            locked = anchor() != null,
            forward = input.isForward,
            backward = input.isBackward,
            left = input.isLeft,
            right = input.isRight,
            jump = input.isJump,
            sneak = input.isSneak,
            sprint = input.isSprint,
        )
        for (signal in signals) {
            when (signal) {
                SpectatorSignal.LockChord -> onLockChord()
                SpectatorSignal.SecondaryChord -> onSecondaryChord()
                is SpectatorSignal.Key -> onKey(signal.key)
            }
        }
    }

    @EventHandler(ignoreCancelled = true)
    fun onMove(event: PlayerMoveEvent) {
        if (event is PlayerTeleportEvent) return
        if (event.player.uniqueId != player.uniqueId) return
        val anchor = anchor() ?: return
        val to = event.to
        if (to.x == anchor.x && to.y == anchor.y && to.z == anchor.z) return
        event.to = anchor.clone().apply {
            yaw = to.yaw
            pitch = to.pitch
        }
    }

    @EventHandler
    fun onTeleport(event: PlayerTeleportEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val anchor = anchor() ?: return
        if (!leavesAnchor(event.to, anchor)) return
        onForcedRelease()
    }

    @EventHandler
    fun onGameModeChange(event: PlayerGameModeChangeEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (event.newGameMode == GameMode.SPECTATOR) return
        if (anchor() != null) onForcedRelease()
    }

    // Fly speed is written to the player file, and the content mode's teardown restores it
    // several suspend hops after the quit, past the save in this tick. Without a synchronous
    // release here the player reconnects with fly speed zero.
    @EventHandler(priority = EventPriority.LOWEST)
    fun onQuit(event: PlayerQuitEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        if (anchor() != null) onForcedRelease()
    }
}

/**
 * Whether a teleport destination actually leaves the lock [anchor]. The position pin
 * rewrites drifting moves back onto the anchor, and Paper delivers a modified move
 * destination as a PLUGIN teleport to that exact spot, so releasing on every teleport
 * would unlock in the same instant the lock engages.
 */
internal fun leavesAnchor(to: Location, anchor: Location): Boolean =
    to.world != anchor.world ||
            abs(to.x - anchor.x) > PIN_EPSILON ||
            abs(to.y - anchor.y) > PIN_EPSILON ||
            abs(to.z - anchor.z) > PIN_EPSILON

private const val PIN_EPSILON = 1e-6

/** The world axis cardinal the yaw looks along. Minecraft yaw: 0 = +Z, 90 = -X, 180 = -Z, 270 = +X. */
internal fun cardinalFromYaw(yaw: Float): Vector = when (Math.floorMod(Math.round(yaw / 90f), 4)) {
    0 -> Vector(0.0, 0.0, 1.0)
    1 -> Vector(-1.0, 0.0, 0.0)
    2 -> Vector(0.0, 0.0, -1.0)
    else -> Vector(1.0, 0.0, 0.0)
}

/** The world direction a locked spectator key nudges toward, relative to the [yaw] facing. */
internal fun spectatorKeyDirection(key: SpectatorKey, yaw: Float): Vector? {
    val facing = cardinalFromYaw(yaw)
    return when (key) {
        SpectatorKey.FORWARD -> facing
        SpectatorKey.BACKWARD -> facing * -1.0
        SpectatorKey.LEFT -> Vector(facing.z, 0.0, -facing.x)
        SpectatorKey.RIGHT -> Vector(-facing.z, 0.0, facing.x)
        SpectatorKey.UP -> Vector(0.0, 1.0, 0.0)
        SpectatorKey.DOWN -> Vector(0.0, -1.0, 0.0)
        SpectatorKey.MARK -> null
    }
}

/**
 * Ends a gesture when the player is moved by something the editor did not do.
 *
 * A carried region, a grabbed face and a carried polygon corner are all measured from the eye and
 * followed every tick, so a teleport, a portal or a respawn drags them along to wherever the
 * player lands. The editor's own teleport tool refuses to run mid gesture; nothing else asks
 * permission first.
 *
 * The spectator lock pins the player by rewriting their movement, which the server delivers as a
 * teleport of its own, so a destination that does not leave [anchor] is the lock holding them
 * still rather than anything moving them.
 */
internal class DisplacementListener(
    private val player: Player,
    private val anchor: () -> Location?,
    private val onDisplaced: () -> Unit,
) : Listener {
    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    fun onTeleport(event: PlayerTeleportEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val anchor = anchor()
        if (anchor != null && !leavesAnchor(event.to, anchor)) return
        onDisplaced()
    }

    @EventHandler
    fun onRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        onDisplaced()
    }
}

/**
 * Scroll notches between two hotbar slots, positive when the wheel scrolls up. The hotbar
 * wraps around, so the shortest way around is the scrolled amount.
 */
internal fun scrollSteps(previousSlot: Int, newSlot: Int): Int {
    var delta = newSlot - previousSlot
    if (delta > 4) delta -= 9
    if (delta < -4) delta += 9
    return -delta
}

/** Rounds to the half block grid carried regions snap onto. */
internal fun snapToHalfGrid(value: Double): Double = floor(value * 2.0 + 0.5) / 2.0

/** Rounds to the quarter block grid face drags snap onto. */
internal fun snapToQuarterGrid(value: Double): Double = floor(value * 4.0 + 0.5) / 4.0
