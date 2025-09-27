package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.OnlyTags
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityData
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sound
import com.typewritermc.entity.entries.entity.minecraft.PlayerEntity
import org.bukkit.entity.Player
import java.util.*

@Entry("self_npc_definition", "The definition of the self NPC", Colors.ORANGE, "mdi:account")
/**
 * The `Self NPC Definition` entry that defines a player entity with the skin of the viewer.
 *
 * ## How could this be used?
 * Showing the player themselves during a cinematic.
 */
class SelfNpcDefinition(
    override val id: String = "",
    override val name: String = "",
    @Help("Overrides the display name of the speaker")
    val overrideName: Optional<Var<String>> = Optional.empty(),
    override val sound: Var<Sound> = ConstVar(Sound.EMPTY),
    @OnlyTags("generic_entity_data", "living_entity_data", "player_data")
    override val data: List<Ref<EntityData<*>>> = emptyList(),
) : SimpleEntityDefinition {
    override val displayName: Var<String>
        get() = overrideName.orElseGet { ConstVar("%player_name%") }

    override fun create(player: Player): FakeEntity = SelfNpc(player)
}

class SelfNpc(
    player: Player,
) : FakeEntity(player) {
    private val playerEntity = PlayerEntity(player, ConstVar(player.name))

    override val state: EntityState
        get() = playerEntity.state

    init {
        setup()
    }

    private fun setup() {
        consumeProperties(player.skin)
    }

    override val entityId: Int
        get() = playerEntity.entityId

    override fun applyProperties(properties: List<EntityProperty>) {
        playerEntity.consumeProperties(properties)
    }

    override fun tick() {
        playerEntity.tick()
    }

    override fun spawn(location: PositionProperty) {
        // When in a cinematic, the equipment will be reset to empty. We want to keep the player's equipment.
        super.spawn(location)
        setup()
        playerEntity.spawn(location)
    }

    override fun addPassenger(entity: FakeEntity) {
        playerEntity.addPassenger(entity)
    }

    override fun removePassenger(entity: FakeEntity) {
        playerEntity.removePassenger(entity)
    }

    override fun contains(entityId: Int): Boolean = playerEntity.contains(entityId)

    override fun dispose() {
        super.dispose()
        playerEntity.dispose()
    }
}