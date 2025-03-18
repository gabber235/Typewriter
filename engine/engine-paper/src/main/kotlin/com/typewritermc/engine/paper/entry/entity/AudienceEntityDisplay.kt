package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import java.util.*
import kotlin.reflect.KClass

interface AudienceEntityDisplay {
    val creator: EntityCreator
    val definition: EntityDefinitionEntry?
        get() = creator as? EntityDefinitionEntry

    val instanceEntryRef: Ref<out EntityInstanceEntry>

    fun playerSeesEntity(playerId: UUID, entityId: Int): Boolean

    /**
     * The location of the entity for the player.
     */
    fun position(playerId: UUID): Position?

    /**
     * The entity state for the player.
     */
    fun entityState(playerId: UUID): EntityState

    /**
     * Get a specific property applied to the entity for a specific player.
     */
    fun <P : EntityProperty> property(playerId: UUID, type: KClass<P>): P?

    /**
     * Whether the player can view the entity.
     * This is regardless of whether the entity is spawned in for the player.
     * Just that the player has the ability to see the entity.
     *
     * @param playerId The player to check.
     */
    fun canView(playerId: UUID): Boolean

    /**
     * Whether the player has the entity spawned in for them.
     *
     * @param playerId The player to check.
     */
    fun isSpawnedIn(playerId: UUID): Boolean

    /**
     * Get the base entity id of the entity.
     * This might not be all of the entity ids that are displayed.
     * For example, the entity might be a child of another entity.
     *
     * If you need to check if the entity is visible to the player, use [playerSeesEntity].
     */
    fun entityId(playerId: UUID): Int
}

/**
 * Get a specific property applied to the entity for a specific player.
 */
inline fun <reified P : EntityProperty> AudienceEntityDisplay.property(playerId: UUID): P? {
    return property(playerId, P::class)
}