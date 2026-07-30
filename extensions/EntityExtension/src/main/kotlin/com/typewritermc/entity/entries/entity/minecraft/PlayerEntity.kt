package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.player.TextureProperty
import com.github.retrooper.packetevents.protocol.player.UserProfile
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoRemove
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.meta
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.engine.paper.utils.move
import com.typewritermc.engine.paper.utils.stripped
import com.typewritermc.engine.paper.utils.toPacketLocation
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.entity.RideableSittingSupport
import com.typewritermc.entity.entries.entity.custom.state
import me.tofaa.entitylib.EntityLib
import me.tofaa.entitylib.meta.types.PlayerMeta
import me.tofaa.entitylib.spigot.SpigotEntityLibAPI
import me.tofaa.entitylib.wrapper.WrapperPlayer
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.entity.Player
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry("player_definition", "A player entity", Colors.ORANGE, "material-symbols:account-box")
@Tags("player_definition")
/**
 * The `PlayerDefinition` class is an entry that represents a player entity.
 * It is a bare bone's version of a `NPC` entity.
 *
 * ## How could this be used?
 * This could be used to create a player entity.
 */
class PlayerDefinition(
    override val id: String = "",
    override val name: String = "",
    override val displayName: Var<String> = ConstVar(""),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = PlayerEntity(player, displayName, id)
}

@Entry("player_instance", "An instance of a player entity", Colors.YELLOW, "material-symbols:account-box")
/**
 * The `PlayerInstance` class is an entry that represents an instance of a player entity.
 */
class PlayerInstance(
    override val id: String = "",
    override val name: String = "",
    override val definition: Ref<PlayerDefinition> = emptyRef(),
    override val spawnLocation: Position = Position.ORIGIN,
    @OnlyTags("generic_entity_data", "living_entity_data", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
    override val activity: Ref<out SharedEntityActivityEntry> = emptyRef(),
) : SimpleEntityInstance

/**
 * A fake player shown to [player].
 *
 * [stableId] is whatever names the npc across respawns, so that it is shown under the profile it had before. A
 * client keeps every profile it has been told about in its social interactions panel, also after that profile is
 * removed again, so an npc without one leaves an entry there every time the viewer walks back into range. Leave
 * it out for a fake player that is only ever shown once.
 */
class PlayerEntity(
    player: Player,
    displayName: Var<String>,
    stableId: String? = null,
) : FakeEntity(player) {
    private val rideableSitting = RideableSittingSupport(
        player,
        passenger = { entity },
        isPassengerSpawned = { entity.isSpawned },
        location = { property<PositionProperty>() },
    )

    private var entity: WrapperPlayer
    override val entityId: Int
        get() = entity.entityId

    override val state: EntityState
        get() = entity.entityType.state(properties)

    init {
        val uuid = stableId?.let { claimProfile(player.uniqueId, it) } ?: UUID.randomUUID()
        var entityId: Int
        do {
            entityId = EntityLib.getPlatform().entityIdProvider.provide(uuid, EntityTypes.PLAYER)
        } while (EntityLib.getApi<SpigotEntityLibAPI>().getEntity(entityId) != null)

        entity =
            WrapperPlayer(UserProfile(uuid, "\u2063${displayName.get(player).stripped().replace(" ", "_")}"), entityId)

        entity.isInTablist = false
        entity.meta<PlayerMeta> {
            isCapeEnabled = true
            isHatEnabled = true
            isJacketEnabled = true
            isLeftSleeveEnabled = true
            isRightSleeveEnabled = true
            isLeftLegEnabled = true
            isRightLegEnabled = true
        }
    }

    override fun applyProperties(properties: List<EntityProperty>) {
        properties.forEach { property ->
            when (property) {
                is PositionProperty -> applyPosition(property)
                else -> applyProperty(property)
            }
        }
    }

    private fun applyProperty(property: EntityProperty) {
        when (property) {
            is PoseProperty -> {
                rideableSitting.applyPose(property.pose, property<PositionProperty>())
                if (property.pose == EntityPose.SITTING) return
            }

            is SkinProperty -> entity.textureProperties =
                listOf(TextureProperty("textures", property.texture, property.signature))

            else -> {}
        }
        if (applyGenericEntityData(entity, property)) return
        if (applyLivingEntityData(entity, property)) return
    }

    private fun applyPosition(property: PositionProperty) {
        rideableSitting.move(property)
        entity.move(property)
    }

    override fun spawn(location: PositionProperty) {
        rideableSitting.onSpawn(location)
        entity.spawn(location.toPacketLocation())
        entity.addViewer(player.uniqueId)
        rideableSitting.mountIfNeeded()

        val info = WrapperPlayServerTeams.ScoreBoardTeamInfo(
            Component.empty(),
            null,
            null,
            WrapperPlayServerTeams.NameTagVisibility.NEVER,
            WrapperPlayServerTeams.CollisionRule.NEVER,
            NamedTextColor.WHITE,
            WrapperPlayServerTeams.OptionData.NONE
        )
        WrapperPlayServerTeams(
            "typewriter-$entityId",
            WrapperPlayServerTeams.TeamMode.CREATE,
            info,
            entity.username.take(16)
        ) sendPacketTo player

        super.spawn(location)
    }

    override fun addPassenger(entity: FakeEntity) {
        if (entity.entityId == entityId) return
        if (this.entity.hasPassenger(entity.entityId)) return
        this.entity.addPassenger(entity.entityId)
    }

    override fun removePassenger(entity: FakeEntity) {
        if (entity.entityId == entityId) return
        if (!this.entity.hasPassenger(entity.entityId)) return
        this.entity.removePassenger(entity.entityId)
    }

    override fun contains(entityId: Int): Boolean {
        if (rideableSitting.contains(entityId)) return true
        return this.entityId == entityId
    }

    override fun dispose() {
        @Suppress("DEPRECATION")
        WrapperPlayServerTeams(
            "typewriter-$entityId",
            WrapperPlayServerTeams.TeamMode.REMOVE,
            Optional.empty()
        ) sendPacketTo player
        rideableSitting.dispose()
        entity.despawn()
        entity.remove()
        // EntityLib adds the profile to the client's player list on spawn and never takes it back out.
        WrapperPlayServerPlayerInfoRemove(entity.uuid) sendPacketTo player
        claimedProfiles -= entity.uuid
    }

    companion object {
        private val claimedProfiles = ConcurrentHashMap.newKeySet<UUID>()

        /**
         * The profile [viewer] is shown an npc named [stableId] under, held until that npc is disposed.
         *
         * A fake player exists per viewer, so a profile belongs to the viewer it is shown to as much as to the
         * npc itself. Two npcs sharing a [stableId] are handed a profile each, so that copies standing next to
         * each other are not shown as one player.
         */
        private fun claimProfile(viewer: UUID, stableId: String): UUID {
            var index = 0
            while (true) {
                val profile = UUID.nameUUIDFromBytes("typewriter:npc:$viewer:$stableId:${index++}".toByteArray())
                if (claimedProfiles.add(profile)) return profile
            }
        }
    }
}
