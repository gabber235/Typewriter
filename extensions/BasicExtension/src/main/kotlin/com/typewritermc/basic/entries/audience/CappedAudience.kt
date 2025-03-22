package com.typewritermc.basic.entries.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.entries.Var
import org.bukkit.entity.Player
import java.util.*

abstract class CappedAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    val capacity: Var<Int>,
) : AudienceFilter(ref), TickableDisplay {
    protected var candidates = listOf<UUID>()

    override fun filter(player: Player): Boolean = candidates.contains(player.uniqueId)


    override fun onPlayerAdd(player: Player) {
        refreshCandidates()
        super.onPlayerAdd(player)
    }

    override fun tick() {
        val players = consideredPlayers
        val targetCapacity = capacity.get(players.random())
        if (targetCapacity < candidates.size) {
            refreshCandidates()
        }
        // If there are more people, but we haven't considered them yet, we should update the candidates
        if (targetCapacity > candidates.size && players.size > candidates.size) {
            refreshCandidates()
        }
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        refreshCandidates()
    }

    protected fun refreshCandidates() {
        updateCandidates()
        consideredPlayers.forEach { it.refresh() }
    }

    protected abstract fun updateCandidates()
}