package com.typewritermc.core.utils

import com.github.retrooper.packetevents.PacketEvents
import org.bukkit.Bukkit

val server get() = Bukkit.getServer()

val serverVersion get() = PacketEvents.getAPI().serverManager.version