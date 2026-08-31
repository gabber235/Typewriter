package com.typewritermc.engine.paper.entry.entity

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.event.PacketListenerAbstract
import com.github.retrooper.packetevents.event.PacketReceiveEvent
import com.github.retrooper.packetevents.protocol.packettype.PacketType.Play
import com.github.retrooper.packetevents.protocol.player.InteractionHand
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientAttack
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientInteractEntity
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientInteractEntity.InteractAction
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.events.AsyncEntityDefinitionInteract
import com.typewritermc.engine.paper.events.AsyncFakeEntityInteract
import com.typewritermc.engine.paper.plugin
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
        val interaction = event.entityInteraction() ?: return

        val player = event.getPlayer<Player>()
        val entityId = interaction.entityId

        AsyncFakeEntityInteract(player, entityId, interaction.hand, interaction.action).callEvent()

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
            interaction.hand,
            interaction.action,
            interaction.shift,
        ).callEvent()
    }

    fun shutdown() {
        PacketEvents.getAPI().eventManager.unregisterListener(this)
    }
}

/** What a player did to an entity. */
private data class EntityInteraction(
    val entityId: Int,
    val hand: InteractionHand,
    val action: InteractAction,
    val shift: Boolean,
)

/**
 * Reads the interaction out of [this], or null when it is not one.
 *
 * Up to 1.21.11 an attack is the interact packet carrying the attack action. 26.1 gave the attack a
 * packet of its own and dropped the action from the interact one, which PacketEvents reports as
 * INTERACT_AT for every version from there on, so on those servers an attack only ever arrives here.
 */
private fun PacketReceiveEvent.entityInteraction(): EntityInteraction? = when (packetType) {
    Play.Client.INTERACT_ENTITY -> WrapperPlayClientInteractEntity(this).let {
        EntityInteraction(it.entityId, it.hand, it.action, it.isSneaking.orElse(false))
    }

    Play.Client.ATTACK -> WrapperPlayClientAttack(this).let {
        // The attack packet carries neither of these, so they come off the player instead.
        EntityInteraction(
            it.entityId,
            InteractionHand.MAIN_HAND,
            InteractAction.ATTACK,
            getPlayer<Player>().isSneaking,
        )
    }

    else -> null
}
