package com.typewritermc.worldguard

import com.sk89q.worldedit.util.Location
import com.sk89q.worldguard.LocalPlayer
import com.sk89q.worldguard.protection.ApplicableRegionSet
import com.sk89q.worldguard.protection.regions.ProtectedRegion
import com.sk89q.worldguard.session.MoveType
import com.sk89q.worldguard.session.Session
import com.sk89q.worldguard.session.handler.Handler
import com.typewritermc.worldguard.events.RegionsEnterEvent
import com.typewritermc.worldguard.events.RegionsExitEvent
import lirand.api.extensions.server.server

class WorldGuardHandler(session: Session?) : Handler(session) {
    object Factory : Handler.Factory<WorldGuardHandler>() {
        override fun create(session: Session?): WorldGuardHandler {
            return WorldGuardHandler(session)
        }
    }

    override fun onCrossBoundary(
        player: LocalPlayer?,
        from: Location?,
        to: Location?,
        toSet: ApplicableRegionSet?,
        entered: MutableSet<ProtectedRegion>?,
        exited: MutableSet<ProtectedRegion>?,
        moveType: MoveType?
    ): Boolean {
        if (player == null) return false
        val bukkitPlayer = server.getPlayer(player.uniqueId) ?: return false

        if (!entered.isNullOrEmpty()) entered.let {
            RegionsEnterEvent(bukkitPlayer, it).callEvent()
        }
        if (!exited.isNullOrEmpty()) exited.let {
            RegionsExitEvent(bukkitPlayer, it).callEvent()
        }

        return super.onCrossBoundary(player, from, to, toSet, entered, exited, moveType)
    }
}