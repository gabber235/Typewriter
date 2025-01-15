package com.typewritermc.engine.paper.entry.entries

import com.typewritermc.core.entries.PriorityEntry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.utils.Sound
import org.bukkit.entity.Player
import kotlin.reflect.KClass

@Tags("speaker")
interface SpeakerEntry : PlaceholderEntry {
    @Colored
    @Placeholder
    @Help("The name of the entity that will be displayed in the chat (e.g. 'Steve' or 'Alex').")
    val displayName: Var<String>

    @Help("The sound that will be played when the entity speaks.")
    val sound: Sound

    override fun parser(): PlaceholderParser = placeholderParser {
        supply { player -> displayName.get(player) }
    }
}

/**
 * Must override equals and hashCode to compare the data.
 *
 * Must have a companion object that implements `PropertyCollectorSupplier`.
 */
interface EntityProperty

interface PropertyCollectorSupplier<P : EntityProperty> {
    val type: KClass<P>
    fun collector(suppliers: List<PropertySupplier<out P>>): PropertyCollector<P>
}

interface PropertySupplier<P : EntityProperty> {
    fun type(): KClass<P>
    fun build(player: Player): P
    fun canApply(player: Player): Boolean
}

interface PropertyCollector<P : EntityProperty> {
    val type: KClass<P>
    fun collect(player: Player): P?
}

@Tags("entity_data")
interface EntityData<P : EntityProperty> : AudienceEntry, PropertySupplier<P>, PriorityEntry {
    override fun canApply(player: Player): Boolean = player.inAudience(this)
    override fun display(): AudienceDisplay = PassThroughDisplay()
}

@Tags("generic_entity_data")
interface GenericEntityData<P : EntityProperty> : EntityData<P>


@Tags("living_entity_data")
interface LivingEntityData<P : EntityProperty> : EntityData<P>


@Tags("entity_definition")
interface EntityDefinitionEntry : ManifestEntry, SpeakerEntry, EntityCreator {
    val data: List<Ref<EntityData<*>>>
}

@Tags("entity_instance")
interface EntityInstanceEntry : AudienceFilterEntry, SoundSourceEntry {
    val definition: Ref<out EntityDefinitionEntry>


    override fun getEmitter(player: Player): SoundEmitter {
        val display = ref().findDisplay() as? ActivityEntityDisplay ?: return SoundEmitter(player.entityId)
        val entityId = display.entityId(player.uniqueId)
        return SoundEmitter(entityId)
    }
}

@Tags("entity_activity")
interface EntityActivityEntry : ActivityCreator, ManifestEntry

@Tags("shared_entity_activity")
interface SharedEntityActivityEntry : EntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<ActivityContext> {
        if (context !is SharedActivityContext) throw WrongActivityContextException(
            context,
            SharedActivityContext::class,
            this
        )
        return create(context, currentLocation) as EntityActivity<ActivityContext>
    }

    fun create(context: SharedActivityContext, currentLocation: PositionProperty): EntityActivity<SharedActivityContext>
}

@Tags("individual_entity_activity")
interface IndividualEntityActivityEntry : EntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<ActivityContext> {
        if (context !is IndividualActivityContext) throw WrongActivityContextException(
            context,
            IndividualActivityContext::class,
            this
        )
        return create(context, currentLocation) as EntityActivity<ActivityContext>
    }

    fun create(
        context: IndividualActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<IndividualActivityContext>
}

@Tags("generic_entity_activity")
interface GenericEntityActivityEntry : SharedEntityActivityEntry, IndividualEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<ActivityContext>

    override fun create(
        context: SharedActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<SharedActivityContext> {
        return create(context as ActivityContext, currentLocation) as EntityActivity<SharedActivityContext>
    }

    override fun create(
        context: IndividualActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<IndividualActivityContext> {
        return create(context as ActivityContext, currentLocation) as EntityActivity<IndividualActivityContext>
    }
}

class WrongActivityContextException(
    context: ActivityContext,
    expected: KClass<out ActivityContext>,
    entry: EntityActivityEntry
) : IllegalStateException(
    """
    |The activity context for ${entry.name} is not of the expected type.
    |Expected: $expected
    |Actual: $context
    |
    |This happens when you try to mix shared and individual activities.
    |For example, you can't use a shared activity on an individual entity.
    |And you can't use an individual activity on a shared entity.
    |
    |To fix this, you need to make sure that the activity matches the entity visibility.
    |If you need more help, please join the TypeWriter Discord! https://discord.gg/gs5QYhfv9x
""".trimMargin()
)