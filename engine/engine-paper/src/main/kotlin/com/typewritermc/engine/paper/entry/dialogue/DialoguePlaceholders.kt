package com.typewritermc.engine.paper.entry.dialogue

import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderHandler
import org.bukkit.entity.Player

class DialoguePlaceholders : PlaceholderHandler {
    private val keys = listOf("in_dialogue", "in_conversation")

    override fun onPlaceholderRequest(player: Player?, params: String): String? {
        if (player == null) return null
        if (params !in keys) return null
        return if (player.isInDialogue) "1" else "0"
    }
}