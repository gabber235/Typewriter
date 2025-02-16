package com.typewritermc.entity.entries.entity.minecraft

import com.github.retrooper.packetevents.protocol.entity.pose.EntityPose
import com.github.retrooper.packetevents.protocol.entity.type.EntityTypes
import com.github.retrooper.packetevents.protocol.player.TextureProperty
import com.github.retrooper.packetevents.protocol.player.UserProfile
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
import com.typewritermc.engine.paper.utils.stripped
import com.typewritermc.engine.paper.utils.toPacketLocation
import com.typewritermc.entity.entries.data.minecraft.PoseProperty
import com.typewritermc.entity.entries.data.minecraft.applyGenericEntityData
import com.typewritermc.entity.entries.data.minecraft.living.applyLivingEntityData
import com.typewritermc.entity.entries.entity.custom.state
import me.tofaa.entitylib.EntityLib
import me.tofaa.entitylib.meta.types.PlayerMeta
import me.tofaa.entitylib.spigot.SpigotEntityLibAPI
import me.tofaa.entitylib.wrapper.WrapperEntity
import me.tofaa.entitylib.wrapper.WrapperPlayer
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.entity.Player
import java.util.*

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
    override val sound: Sound = Sound.EMPTY,
    @OnlyTags("generic_entity_data", "living_entity_data", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override fun create(player: Player): FakeEntity = PlayerEntity(player, displayName)
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

class PlayerEntity(
    player: Player,
    displayName: Var<String>,
) : FakeEntity(player) {
    private var sitEntity: WrapperEntity? = null

    private var entity: WrapperPlayer
    override val entityId: Int
        get() = entity.entityId

    override val state: EntityState
        get() = entity.entityType.state(properties)

    init {
        val uuid = UUID.randomUUID()
        var entityId: Int
        do {
            entityId = EntityLib.getPlatform().entityIdProvider.provide(uuid, EntityTypes.PLAYER)
        } while (EntityLib.getApi<SpigotEntityLibAPI>().getEntity(entityId) != null)

        entity = WrapperPlayer(UserProfile(uuid, "\u2063${displayName.get(player).stripped().replace(" ", "_")}"), entityId)

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
                is PositionProperty -> {
                    if (sitEntity?.isSpawned == true) {
                        sitEntity?.teleport(property.toPacketLocation())
                    }
                    if (entity.isSpawned) {
                        entity.teleport(property.toPacketLocation())
                        entity.rotateHead(property.yaw, property.pitch)
                    }
                }

                is SkinProperty -> entity.textureProperties =
                    listOf(TextureProperty("textures", property.texture, property.signature))

                is PoseProperty -> {
                    if (property.pose == EntityPose.SITTING) {
                        sit()
                    } else {
                        unsit()
                    }
                }

                else -> {
                }
            }
            if (applyGenericEntityData(entity, property)) return@forEach
            if (applyLivingEntityData(entity, property)) return@forEach
        }
    }

    override fun spawn(location: PositionProperty) {
        if (sitEntity != null) {
            sitEntity?.spawn(location.toPacketLocation())
            sitEntity?.addViewer(player.uniqueId)
        }
        entity.spawn(location.toPacketLocation())
        entity.addViewer(player.uniqueId)

        sitEntity?.addPassengers(this.entity)

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
            info
        ) sendPacketTo player

        WrapperPlayServerTeams(
            "typewriter-$entityId",
            WrapperPlayServerTeams.TeamMode.ADD_ENTITIES,
            Optional.empty(),
            listOf(entity.username.take(16))
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
        sitEntity?.let {
            if (it.entityId == entityId) return true
        }
        return this.entityId == entityId
    }

    override fun dispose() {
        WrapperPlayServerTeams(
            "typewriter-$entityId",
            WrapperPlayServerTeams.TeamMode.REMOVE,
            Optional.empty()
        ) sendPacketTo player
        entity.despawn()
        entity.remove()

        sitEntity?.despawn()
        sitEntity?.remove()
        sitEntity = null
    }

    private fun sit(location: PositionProperty? = null) {
        val loc = location ?: property<PositionProperty>() ?: return
        if (sitEntity != null) return
        sitEntity = WrapperEntity(EntityTypes.BLOCK_DISPLAY)
        sitEntity?.spawn(loc.toPacketLocation())
        sitEntity?.addViewer(player.uniqueId)
        if (entity.isSpawned) {
            sitEntity?.addPassengers(this.entity)
        }
    }

    private fun unsit() {
        val entity = sitEntity ?: return
        if (entity.hasPassenger(this.entity)) {
            entity.removePassengers(this.entity)
        }
        entity.removeViewer(player.uniqueId)
        entity.despawn()
        entity.remove()
        sitEntity = null
    }
}