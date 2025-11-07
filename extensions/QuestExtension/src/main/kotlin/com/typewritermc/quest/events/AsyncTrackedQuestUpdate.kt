package com.typewritermc.quest.events

import com.typewritermc.core.entries.Ref
import com.typewritermc.quest.entries.QuestEntry
import org.bukkit.entity.Player
import org.bukkit.event.HandlerList
import org.bukkit.event.player.PlayerEvent


class AsyncTrackedQuestUpdate(
    player: Player,
    val from: Ref<QuestEntry>?,
    val to: Ref<QuestEntry>?,
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