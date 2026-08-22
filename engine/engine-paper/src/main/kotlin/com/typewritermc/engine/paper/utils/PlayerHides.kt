package com.typewritermc.engine.paper.utils

import lirand.api.extensions.server.registerEvents
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.java.KoinJavaComponent
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap

/**
 * Hides players from each other, counting the features that asked for it.
 *
 * Bukkit records a hide against the plugin that asked for it rather than against the caller, so two
 * Typewriter features hiding the same player from the same viewer share one flag: whichever finishes
 * first reveals the player while the other still wants them hidden.
 *
 * Every hide taken here carries an owner, and a pair becomes visible again only once the last owner
 * released it. Owners are compared by identity, so anything whose lifetime matches the feature's can
 * serve as one, usually the display or bound that took the hide.
 *
 * Hiding and revealing both call Bukkit, so both have to happen on the server thread. The
 * bookkeeping itself is concurrent, because once the plugin is disabled the dispatcher stops
 * scheduling onto the server thread and teardown runs on whichever thread triggered it.
 */
class PlayerHides : Listener, KoinComponent {
    private val plugin: Plugin by inject()
    private val ownersByPair = ConcurrentHashMap<HidePair, MutableSet<OwnerRef>>()

    /** Registers the quit handler. Call once while the plugin enables. */
    fun initialize() {
        plugin.registerEvents(this)
    }

    /**
     * Runs at MONITOR so every feature still holding a hide on this player has already had its
     * chance to release. What is left is dropped rather than released, for the reason [forget] gives.
     */
    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) {
        forget(event.player.uniqueId)
    }

    /**
     * Hides the target from the viewer on behalf of the owner.
     * Hiding an already hidden pair changes nothing for the client, so this is also how a hide is
     * reasserted.
     */
    fun hide(owner: Any, viewer: Player, target: Player) {
        if (viewer.uniqueId == target.uniqueId) return
        // Bukkit refuses to hide anything once the plugin is disabled. Calling it first means a
        // refusal leaves no record, which would otherwise keep the pair hidden for an owner whose
        // hide never reached the client.
        viewer.hidePlayer(plugin, target)
        ownersByPair.compute(HidePair(viewer.uniqueId, target.uniqueId)) { _, existing ->
            (existing ?: identityOwners()).apply { add(OwnerRef(owner)) }
        }
    }

    /**
     * Releases the owner's claim on hiding the target from the viewer.
     * The target only becomes visible again when no other owner still wants them hidden.
     */
    fun show(owner: Any, viewer: UUID, target: UUID) {
        val pair = HidePair(viewer, target)
        if (dropOwner(pair, OwnerRef(owner))) reveal(pair)
    }

    /** Releases every hide an owner still holds, for a feature that hid many players at once. */
    fun release(owner: Any) {
        val ref = OwnerRef(owner)
        val revealed = ArrayList<HidePair>()
        ownersByPair.keys.forEach { pair -> if (dropOwner(pair, ref)) revealed.add(pair) }
        revealed.forEach(::reveal)
    }

    /** @return true when that was the last owner, so the pair has to be revealed. */
    private fun dropOwner(pair: HidePair, owner: OwnerRef): Boolean {
        var emptied = false
        ownersByPair.computeIfPresent(pair) { _, owners ->
            if (!owners.remove(owner)) return@computeIfPresent owners
            if (owners.isNotEmpty()) return@computeIfPresent owners
            emptied = true
            null
        }
        return emptied
    }

    /**
     * Drops every record naming the player, on either side.
     *
     * A disconnect clears the hides on the connection itself, so nothing has to be sent. This is a
     * safety net for an owner that never released, not the normal way a hide ends.
     */
    fun forget(playerId: UUID) {
        ownersByPair.keys.removeIf { it.viewer == playerId || it.target == playerId }
    }

    /** How many owners currently want the target hidden from the viewer. */
    fun ownerCount(viewer: UUID, target: UUID): Int = ownersByPair[HidePair(viewer, target)]?.size ?: 0

    private fun reveal(pair: HidePair) {
        val viewer = server.getPlayer(pair.viewer) ?: return
        val target = server.getPlayer(pair.target) ?: return
        viewer.showPlayer(plugin, target)
    }

    private fun identityOwners(): MutableSet<OwnerRef> = ConcurrentHashMap.newKeySet()

    /**
     * An owner as a map key, compared by identity.
     * Owners are arbitrary objects from anywhere in the codebase, and one implementing equality by
     * value could otherwise release a hide another instance took.
     */
    private class OwnerRef(private val owner: Any) {
        override fun equals(other: Any?): Boolean = other is OwnerRef && other.owner === owner
        override fun hashCode(): Int = System.identityHashCode(owner)
    }

    private data class HidePair(val viewer: UUID, val target: UUID)
}

/** The [PlayerHides] of the running plugin. */
val playerHides: PlayerHides get() = KoinJavaComponent.get(PlayerHides::class.java)
