package com.typewritermc.region.handler

import com.google.common.collect.Sets
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.DistanceMode
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerMoveEvent
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.abs

/**
 * The subscription kinds a region tracker supports. The attached handlers decide what the
 * tracker dispatches. A tracker with only [LazyInsideQueryHandler]s does no event work and
 * only resolves geometry on demand.
 *
 * Each handler owns its own membership state. Two handlers on the same region can use
 * different [boundaryInset][EnterExitHandler.boundaryInset] values without affecting each
 * other.
 *
 * A handler with a non null [tracked] only reacts to that one player. Audience filters use
 * this to keep per player state on a shared tracker. Event entry handlers pass `null` to
 * react to all players.
 */
sealed interface RegionHandler {
    val owner: Any

    /**
     * When non null, this handler only reacts to classifications of the player with this
     * UUID. Classifications of other players are ignored.
     */
    val tracked: UUID?

    /**
     * Called by the tracker for every player observed during a dispatch. [signedDistance]
     * is `null` when the player is in a different world than the tracker's resolved
     * transform or went offline.
     *
     * Returns `true` when a fired callback requests cancellation of the Bukkit event. The
     * engine only honors the request when [moveEvent] is non null. [CrossingCause.ENGULFED]
     * dispatches have no event to cancel and the result is ignored there.
     *
     * [CrossingCause.PLAYER_MOVED] and [CrossingCause.TELEPORTED] dispatches run on the
     * server main thread. [CrossingCause.ENGULFED] dispatches run on
     * `Dispatchers.UntickedAsync`. Callbacks that touch world state or entity velocity must
     * hop to `Dispatchers.Sync` unless already on the main thread.
     */
    fun onClassification(
        player: Player,
        signedDistance: Double?,
        cause: CrossingCause,
        moveEvent: PlayerMoveEvent?,
    ): Boolean

    /**
     * Updates membership without firing callbacks. The engine calls this after cancelling
     * a move, resyncing every touched handler against the player's pre move position so no
     * handler is left believing the movement happened.
     */
    fun resync(player: Player, signedDistance: Double?)

    /**
     * Records that the crossing just dispatched was refused, so the handler stops firing for
     * [player] until they settle on one side of the boundary again.
     *
     * The engine calls this on every handler it touched during a cancelled move, not only the
     * ones that asked to cancel. A cancelled move is rolled back for all of them, and without
     * this the rollback simply arms the same crossing again for the next move: a player leaning
     * on the boundary would fire the whole pipeline twenty times a second.
     *
     * A handler refused this way keeps answering what it answered before. Answering "cancel"
     * on behalf of a handler that never asked to would have every audience filter and every
     * uncancelled enter event start blocking movement.
     */
    fun refuse(player: Player)

    /**
     * Drops any refusal recorded for [player]. The engine calls this once a move of theirs
     * completes, since nothing is left rolled back at that point.
     */
    fun clearRefusal(player: Player)

    /**
     * `true` when this handler currently considers [player] a member of the region or
     * band.
     */
    fun tracks(player: Player): Boolean
}

/**
 * Reaction to a crossing. Return `true` to request cancellation of the Bukkit event that
 * caused the crossing. The request is only honored when a move event is present.
 */
typealias CrossingCallback = (player: Player, cause: CrossingCause, moveEvent: PlayerMoveEvent?) -> Boolean

/**
 * Told the membership a [RegionHandler.resync] settled on, whenever that differs from what the
 * handler was holding.
 *
 * A cancelled move is rolled back for every handler it touched, the ones whose callback already ran
 * included. A subscriber that pushes state from its callback, like an audience filter, is left
 * holding the value of a crossing that is being taken away and has no other way to hear about it:
 * the player is put back where they came from, so no later crossing corrects it either.
 *
 * Enter and exit event entries pass nothing here. A crossing that was refused fires no triggers.
 */
typealias MembershipCallback = (player: Player, member: Boolean) -> Unit

/**
 * Fires enter and leave callbacks for one region. The enter fires the moment the boundary
 * is crossed, matching what the visualize command and the debug command report as inside.
 * A member must then move more than [boundaryInset] blocks clear of the region before the
 * leave fires, which prevents repeat fires from a player walking along the boundary. A
 * value of `0.0` fires the leave on the exact boundary.
 */
class EnterExitHandler(
    override val owner: Any,
    override val tracked: UUID? = null,
    val boundaryInset: Var<Double> = ConstVar(0.0),
    private val onEnter: CrossingCallback = NOOP,
    private val onLeave: CrossingCallback = NOOP,
    private val onResync: MembershipCallback = NO_MEMBERSHIP,
) : RegionHandler {
    private val members: MutableSet<UUID> = Sets.newConcurrentHashSet()
    private val refused = RefusedCrossings()

    override fun onClassification(
        player: Player,
        signedDistance: Double?,
        cause: CrossingCause,
        moveEvent: PlayerMoveEvent?,
    ): Boolean {
        if (tracked != null && player.uniqueId != tracked) return false
        val uuid = player.uniqueId
        // Only a dispatch that can be rolled back records a crossing, so only one may forget the
        // last. An engulf landing between a move's dispatch and its resync would otherwise erase
        // the crossing the resync is about to refuse, and the crossing fires again next tick.
        if (rollsBack(cause, moveEvent)) refused.forgetCrossing(uuid)
        if (signedDistance == null) {
            refused.clear(uuid)
            return members.remove(uuid) && onLeave(player, cause, moveEvent)
        }
        val wasInside = uuid in members
        val nowInside = isInside(player, signedDistance, wasInside)
        // The verdict is asked for before the no change test. A cancelled move puts the player back
        // where they crossed from, and a body wide enough to overlap the region already stands
        // there, so the attempt they are repeating does not read as a change at all. Without
        // this the refusal holds once and the next step through is let past.
        refused.verdictFor(uuid, cause, nowInside)?.let { return it }
        if (nowInside == wasInside) return false
        // A crossing nothing can undo settles the question a held refusal was keeping open: the
        // region reached the player, so they are on the side they were being kept from whatever
        // the handler answered. Leaving the refusal in place there cancels every move they make
        // from inside it, the one that would carry them back out included.
        val stands = !rollsBack(cause, moveEvent)
        if (stands) refused.clear(uuid) else refused.crossed(uuid, nowInside)

        // The membership sets decide who fires: the move listener and the async reconcile can
        // classify the same player at once, and only one of them may call the callback.
        //
        // A refused crossing puts the membership back where it was, because the crossing itself
        // is about to be undone. Only a crossing the engine can actually undo is taken back, and
        // only that one is remembered, so a crossing that stood does not answer for the next move.
        if (nowInside) {
            if (!members.add(uuid)) return false
            if (!onEnter(player, cause, moveEvent)) return false
            if (stands) return true
            members.remove(uuid)
            refused.recordCancelled(uuid, attempted = true)
            return true
        }
        if (!members.remove(uuid)) return false
        if (!onLeave(player, cause, moveEvent)) return false
        if (stands) return true
        members.add(uuid)
        refused.recordCancelled(uuid, attempted = false)
        return true
    }

    override fun resync(player: Player, signedDistance: Double?) {
        if (tracked != null && player.uniqueId != tracked) return
        val uuid = player.uniqueId
        if (signedDistance == null) {
            if (members.remove(uuid)) onResync(player, false)
            return
        }
        // A held refusal decides the side, not the geometry. The player is left standing where
        // their body still overlaps the region, and deriving again membership from that would put
        // them straight back on the side they were just refused from.
        val refusedSide = refused.attemptedSide(uuid)
        val wasInside = uuid in members
        val nowInside = refusedSide?.not() ?: isInside(player, signedDistance, wasInside)
        val changed = if (nowInside) members.add(uuid) else members.remove(uuid)
        if (changed) onResync(player, nowInside)
    }

    override fun refuse(player: Player) {
        if (tracked != null && player.uniqueId != tracked) return
        refused.recordRolledBack(player.uniqueId)
    }

    override fun clearRefusal(player: Player) {
        refused.clear(player.uniqueId)
    }

    private fun isInside(player: Player, signedDistance: Double, wasInside: Boolean): Boolean {
        if (!wasInside) return signedDistance <= 0.0
        return signedDistance <= boundaryInset.get(player).coerceAtLeast(0.0)
    }

    override fun tracks(player: Player): Boolean = player.uniqueId in members
}

/**
 * Fires callbacks when a player enters or leaves the band around the region's boundary.
 * The band is `|signedDistance| <= distance`. Entering the band fires the moment that
 * threshold is crossed. [boundaryInset] widens the threshold to leave the band, so a
 * player walking along the band edge does not retrigger.
 *
 * [distanceMode] selects how the distance to the boundary is measured. A horizontal band
 * has no vertical bound, and neither it nor a non const [distance] can contribute to the
 * tracker's AABB margin (see [RegionTracker.marginUnbounded][com.typewritermc.region.tracker.RegionTracker]).
 */
class ProximityHandler(
    override val owner: Any,
    override val tracked: UUID? = null,
    val distance: Var<Double>,
    val distanceMode: DistanceMode = DistanceMode.FULL,
    val boundaryInset: Var<Double> = ConstVar(0.0),
    private val onEnterBand: CrossingCallback = NOOP,
    private val onLeaveBand: CrossingCallback = NOOP,
    private val onResync: MembershipCallback = NO_MEMBERSHIP,
) : RegionHandler {
    private val members: MutableSet<UUID> = Sets.newConcurrentHashSet()
    private val refused = RefusedCrossings()

    override fun onClassification(
        player: Player,
        signedDistance: Double?,
        cause: CrossingCause,
        moveEvent: PlayerMoveEvent?,
    ): Boolean {
        if (tracked != null && player.uniqueId != tracked) return false
        val uuid = player.uniqueId
        // See EnterExitHandler: an engulf never recorded a crossing, so it must not forget one.
        if (rollsBack(cause, moveEvent)) refused.forgetCrossing(uuid)
        if (signedDistance == null) {
            refused.clear(uuid)
            return members.remove(uuid) && onLeaveBand(player, cause, moveEvent)
        }
        val wasInBand = uuid in members
        val nowInBand = inBand(player, signedDistance, wasInBand)
        // See EnterExitHandler: the position a cancelled move is rolled back to can still be one
        // this band covers, so the attempt has to be recognised by the side it was heading for
        // rather than by looking like a change.
        refused.verdictFor(uuid, cause, nowInBand)?.let { return it }
        if (nowInBand == wasInBand) return false
        // See EnterExitHandler: a band the region moved onto the player settles the refusal it
        // finds there, rather than holding them to a crossing that already happened to them.
        val stands = !rollsBack(cause, moveEvent)
        if (stands) refused.clear(uuid) else refused.crossed(uuid, nowInBand)

        if (nowInBand) {
            if (!members.add(uuid)) return false
            if (!onEnterBand(player, cause, moveEvent)) return false
            if (stands) return true
            members.remove(uuid)
            refused.recordCancelled(uuid, attempted = true)
            return true
        }
        if (!members.remove(uuid)) return false
        if (!onLeaveBand(player, cause, moveEvent)) return false
        if (stands) return true
        members.add(uuid)
        refused.recordCancelled(uuid, attempted = false)
        return true
    }

    override fun resync(player: Player, signedDistance: Double?) {
        if (tracked != null && player.uniqueId != tracked) return
        val uuid = player.uniqueId
        if (signedDistance == null) {
            if (members.remove(uuid)) onResync(player, false)
            return
        }
        val refusedSide = refused.attemptedSide(uuid)
        val wasInBand = uuid in members
        val nowInBand = refusedSide?.not() ?: inBand(player, signedDistance, wasInBand)
        val changed = if (nowInBand) members.add(uuid) else members.remove(uuid)
        if (changed) onResync(player, nowInBand)
    }

    override fun refuse(player: Player) {
        if (tracked != null && player.uniqueId != tracked) return
        refused.recordRolledBack(player.uniqueId)
    }

    override fun clearRefusal(player: Player) {
        refused.clear(player.uniqueId)
    }

    private fun inBand(player: Player, signedDistance: Double, wasInBand: Boolean): Boolean {
        val band = distance.get(player).coerceAtLeast(0.0)
        if (!wasInBand) return abs(signedDistance) <= band
        val inset = boundaryInset.get(player).coerceAtLeast(0.0)
        return abs(signedDistance) <= band + inset
    }

    override fun tracks(player: Player): Boolean = player.uniqueId in members
}

/**
 * A handler that fires no events and tracks no membership. It only keeps the tracker alive
 * so the holder can query the resolved shape and transform on demand.
 */
class LazyInsideQueryHandler(
    override val owner: Any,
    override val tracked: UUID? = null,
) : RegionHandler {
    override fun onClassification(
        player: Player,
        signedDistance: Double?,
        cause: CrossingCause,
        moveEvent: PlayerMoveEvent?,
    ): Boolean = false

    override fun resync(player: Player, signedDistance: Double?) = Unit

    override fun refuse(player: Player) = Unit

    override fun clearRefusal(player: Player) = Unit

    override fun tracks(player: Player): Boolean = false
}

/**
 * The players whose last crossing of one handler's boundary was rolled back: which side they
 * were trying to reach, and what this handler answered at the time.
 *
 * The verdict is kept rather than assumed, because the engine refuses every handler it
 * touched during a cancelled move and most of those never asked to cancel anything.
 *
 * The side matters as much as the answer. A cancelled move leaves the player standing where
 * they crossed from, which for a body sized membership test is often a spot the region still
 * counts as inside, so the refused crossing does not look like a change when they push again.
 * Holding the side lets the handler recognise the attempt for what it is, and lets go the
 * moment the player settles on the side they were sent back to.
 */
private class RefusedCrossings {
    private val verdicts = ConcurrentHashMap<UUID, Refusal>()
    private val crossings = ConcurrentHashMap<UUID, Boolean>()

    /**
     * What this handler should answer for a player now classified [nowInside], or `null` when
     * it should classify afresh.
     */
    fun verdictFor(uuid: UUID, cause: CrossingCause, nowInside: Boolean): Boolean? {
        // Nothing to roll back, so the crossing stands and answers for itself. The refusal
        // stays: it belongs to the move the player is still pushing against, and the side test
        // below decides when it is spent. Dropped here, an engulf landing mid dispatch would
        // release the refusal with it. An engulf that does carry the player across drops it from
        // the crossing itself, the only place the difference between the two is visible.
        if (!cause.revocable) return null
        val refusal = verdicts[uuid] ?: return null
        // The player settled on the side the rollback sent them to, so the attempt is over.
        if (nowInside != refusal.attempted) {
            verdicts.remove(uuid)
            return null
        }
        return refusal.cancel
    }

    /** The side a held refusal was trying to reach, or `null` when none is held. */
    fun attemptedSide(uuid: UUID): Boolean? = verdicts[uuid]?.attempted

    /** Remembers that this handler classified a crossing towards [nowInside] on this dispatch. */
    fun crossed(uuid: UUID, nowInside: Boolean) {
        crossings[uuid] = nowInside
    }

    /** Forgets the crossing of the previous dispatch, before this one classifies. */
    fun forgetCrossing(uuid: UUID) {
        crossings.remove(uuid)
    }

    /** This handler asked for the crossing to be cancelled, and stands by that answer. */
    fun recordCancelled(uuid: UUID, attempted: Boolean) {
        verdicts[uuid] = Refusal(attempted, cancel = true)
    }

    /**
     * Another handler had the crossing cancelled, so this one's own reaction was rolled back
     * with it. It must not fire again, and must not start cancelling moves either.
     *
     * Only a handler that actually crossed on this dispatch is refused. The engine refuses every
     * handler on every tracker it touched, and a handler that saw no change has nothing to be
     * held to: answering for its next crossing would drop a leave it never made.
     */
    fun recordRolledBack(uuid: UUID) {
        val attempted = crossings[uuid] ?: return
        verdicts.putIfAbsent(uuid, Refusal(attempted, cancel = false))
    }

    fun clear(uuid: UUID) {
        verdicts.remove(uuid)
        crossings.remove(uuid)
    }

    private data class Refusal(val attempted: Boolean, val cancel: Boolean)
}

/**
 * Whether a refused crossing of [cause] will actually be undone.
 *
 * The cause has to be one the engine can revoke, and there has to be a Bukkit event to revoke it
 * with. A player riding across the boundary is a [CrossingCause.PLAYER_MOVED] with no event: a
 * vehicle's movement cannot be refused, so that crossing stands however the handler answered, and
 * taking the membership back would leave the region believing they never came in.
 */
private fun rollsBack(cause: CrossingCause, moveEvent: PlayerMoveEvent?): Boolean =
    cause.revocable && moveEvent != null

private val NOOP: CrossingCallback = { _, _, _ -> false }

private val NO_MEMBERSHIP: MembershipCallback = { _, _ -> }
