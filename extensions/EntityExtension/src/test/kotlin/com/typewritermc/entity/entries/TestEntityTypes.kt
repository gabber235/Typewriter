package com.typewritermc.entity.entries

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.PacketEventsAPI
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.settings.PacketEventsSettings
import io.mockk.every
import io.mockk.mockk

/** Naming an [EntityTypes] constant loads the mappings, which are read through the settings and nothing else. */
internal fun loadEntityTypes() {
    if (PacketEvents.getAPI() != null) return
    val api = mockk<PacketEventsAPI<Any>>(relaxed = true)
    every { api.settings } returns PacketEventsSettings()
    PacketEvents.setAPI(api)
}
