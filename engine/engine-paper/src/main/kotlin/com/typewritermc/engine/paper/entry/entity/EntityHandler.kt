package com.typewritermc.engine.paper.entry.entity

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.event.PacketListenerAbstract
import com.github.retrooper.packetevents.event.PacketReceiveEvent
import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientInteractEntity
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.events.AsyncEntityDefinitionInteract
import com.typewritermc.engine.paper.events.AsyncFakeEntityInteract
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.server
import me.tofaa.entitylib.APIConfig
import me.tofaa.entitylib.EntityLib
import me.tofaa.entitylib.spigot.SpigotEntityLibPlatform
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

class EntityHandler : PacketListenerAbstract(), KoinComponent {
    private val audienceManager: AudienceManager by inject()
    fun initialize() {
        val platform = SpigotEntityLibPlatform(plugin)
        val settings = APIConfig(PacketEvents.getAPI())
            .usePlatformLogger()

        EntityLib.init(platform, settings)

        PacketEvents.getAPI().eventManager.registerListener(this)
    }

    override fun onPacketReceive(event: PacketReceiveEvent?) {
        if (event == null) return
        if (event.packetType != Play.Client.INTERACT_ENTITY) return
        val packet = WrapperPlayClientInteractEntity(event)

        val player = event.getPlayer<Player>() ?: server.getPlayer(event.user.uuid) ?: return
        val entityId = packet.entityId

        AsyncFakeEntityInteract(player, entityId, packet.hand, packet.action).callEvent()

        val display = audienceManager
            .findDisplays(AudienceEntityDisplay::class)
            .firstOrNull { it.playerSeesEntity(event.user.uuid, entityId) } ?: return

        val definition = display.definition ?: return
        val instance = display.instanceEntryRef.get() ?: return
        AsyncEntityDefinitionInteract(
            player,
            entityId,
            definition,
            instance,
            packet.hand,
            packet.action,
            packet.isSneaking.orElse(false)
        ).callEvent()
    }

    fun shutdown() {
        PacketEvents.getAPI().eventManager.unregisterListener(this)
    }
}