package com.typewritermc.engine.paper.events

import com.typewritermc.core.utils.server
import org.bukkit.event.Event
import org.bukkit.event.HandlerList

class TypewriterUnloadEvent : Event(!server.isPrimaryThread) {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()

        @JvmStatic
        fun getHandlerList(): HandlerList = HANDLER_LIST
    }
}