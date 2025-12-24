package com.typewritermc.quest.events

import com.typewritermc.core.entries.Ref
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.QuestStatus
import org.bukkit.entity.Player
import org.bukkit.event.HandlerList
import org.bukkit.event.player.PlayerEvent

class AsyncQuestStatusUpdate(
    player: Player,
    val quest: Ref<QuestEntry>,
    val from: QuestStatus,
    val to: QuestStatus,
) :
    PlayerEvent(player, true) {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()

        @JvmStatic
        fun getHandlerList(): HandlerList = HANDLER_LIST
    }
}