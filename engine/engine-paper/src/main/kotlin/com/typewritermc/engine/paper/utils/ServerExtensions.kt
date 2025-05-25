package com.typewritermc.engine.paper.utils

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.manager.server.ServerVersion
import org.bukkit.Bukkit

val TICK_MS get() = (1000 / Bukkit.getServer().serverTickManager.tickRate).toLong()

// This is the most magic value I have ever seen.
internal const val AVERAGE_SCHEDULING_DELAY_MS = 5L

val server get() = Bukkit.getServer()

val serverVersion: ServerVersion get() = PacketEvents.getAPI().serverManager.version