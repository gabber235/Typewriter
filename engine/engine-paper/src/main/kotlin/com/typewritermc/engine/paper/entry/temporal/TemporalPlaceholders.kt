package com.typewritermc.engine.paper.entry.temporal

import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderHandler
import org.bukkit.entity.Player

class TemporalPlaceholders : PlaceholderHandler {
    private val keys = listOf("in_temporal", "in_cinematic", "in_cutscene")
    override fun onPlaceholderRequest(player: Player?, params: String): String? {
        if (player == null) return null
        if (params !in keys) return null
        return if (player.isPlayingTemporal()) "1" else "0"
    }
}