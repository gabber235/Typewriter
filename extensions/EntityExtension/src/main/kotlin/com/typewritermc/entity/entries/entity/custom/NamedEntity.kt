package com.typewritermc.entity.entries.entity.custom

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import com.typewritermc.entity.entries.data.minecraft.DisplayNameProperty
import com.typewritermc.entity.entries.data.minecraft.display.BillboardConstraintProperty
import com.typewritermc.entity.entries.data.minecraft.display.TranslationProperty
import com.typewritermc.entity.entries.data.minecraft.display.text.BackgroundColorProperty
import com.typewritermc.entity.entries.entity.minecraft.TextDisplayEntity
import me.tofaa.entitylib.meta.display.AbstractDisplayMeta
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player


val namePlate by snippet(
    "entity.nameplate", """
    <other>
    <reset><display_name>
""".trimIndent()
)

val namePlateOffset by snippet("entity.name.offset", 0.2)
val namePlateColor by snippet("entity.name.color", "#40000000")

@Entry(
    "named_entity_definition",
    "An entity with a name above it's head and the indicator",
    Colors.ORANGE,
    "mdi:account-tag"
)
/**
 * The `NamedEntityDefinition` is an entity that has the other defined entity as the base,
 * shows the name and the indicator above its head.
 *
 * ## How could this be used?
 * This can be used to allow for all entities to have a name and an indicator.
 */
class NamedEntityDefinition(
    override val id: String = "",
    override val name: String = "",
    val baseEntity: Ref<EntityDefinitionEntry> = emptyRef(),
) : SimpleEntityDefinition {
    override val displayName: Var<String> get() = baseEntity.get()?.displayName ?: ConstVar("")
    override val sound: Sound get() = baseEntity.get()?.sound ?: Sound.EMPTY
    override val data: List<Ref<EntityData<*>>> get() = baseEntity.get()?.data ?: emptyList()

    override fun create(player: Player): FakeEntity {
        val entity = baseEntity.get()?.create(player)
            ?: throw IllegalStateException("A base entity must be specified for entry $name ($id)")
        return NamedEntity(player, displayName, entity, ref())
    }
}

class NamedEntity(
    player: Player,
    private var displayName: Var<String>,
    private val baseEntity: FakeEntity,
    definition: Ref<out EntityDefinitionEntry>,
) : FakeEntity(player) {
    private val hologram = TextDisplayEntity(player)
    private val indicatorEntity = InteractionIndicatorEntity(player, definition)

    override val entityId: Int
        get() = baseEntity.entityId

    override val state: EntityState
        get() = baseEntity.state

    init {
        val hologramText = hologram()
        hologram.consumeProperties(
            LinesProperty(hologramText),
            TranslationProperty(Vector(y = namePlateOffset)),
            BillboardConstraintProperty(AbstractDisplayMeta.BillboardConstraints.CENTER),
            BackgroundColorProperty(Color.fromHex(namePlateColor))
        )
        indicatorEntity.consumeProperties(
            TranslationProperty(calculateIndicatorOffset(hologramText)),
            BillboardConstraintProperty(AbstractDisplayMeta.BillboardConstraints.CENTER),
            BackgroundColorProperty(Color.fromHex(namePlateColor))
        )
    }

    override fun applyProperties(properties: List<EntityProperty>) {
        baseEntity.consumeProperties(properties)
        properties.forEach { property ->
            when (property) {
                is DisplayNameProperty -> {
                    displayName = property.displayName
                }
            }
        }
    }

    override fun tick() {
        baseEntity.tick()
        val hologramText = hologram()
        hologram.consumeProperties(LinesProperty(hologramText))
        hologram.tick()
        indicatorEntity.consumeProperties(TranslationProperty(calculateIndicatorOffset(hologramText)))
        indicatorEntity.tick()
    }

    private fun hologram(): String {
        val other = property(LinesProperty::class)?.lines ?: ""
        val displayName = this.displayName

        return namePlate.parsePlaceholders(player).asMiniWithResolvers(
            Placeholder.parsed("other", other),
            Placeholder.parsed("display_name", displayName.get(player).parsePlaceholders(player)),
        ).asMini().trim()
    }

    private fun calculateIndicatorOffset(hologramText: String): Vector {
        val lines = hologramText.count { it == '\n' } + 1
        val height = lines * 0.3 + namePlateOffset
        return Vector(y = height)
    }

    override fun spawn(location: PositionProperty) {
        baseEntity.spawn(location)
        hologram.spawn(location)

        // Since bedrock players don't have TextDisplay entities,
        // we cannot show both the nameplate and the indicator at the same time.
        // So we will only show the nameplate if the player is not using a floodgate.
        if (player.isFloodgate) {
            baseEntity.addPassenger(hologram)
        } else {
            indicatorEntity.spawn(location)
            baseEntity.addPassenger(hologram)
            baseEntity.addPassenger(indicatorEntity)
        }
    }

    override fun addPassenger(entity: FakeEntity) {
        baseEntity.addPassenger(entity)
    }

    override fun removePassenger(entity: FakeEntity) {
        baseEntity.removePassenger(entity)
    }

    override fun contains(entityId: Int): Boolean {
        if (baseEntity.contains(entityId)) return true
        if (hologram.contains(entityId)) return true
        if (indicatorEntity.contains(entityId)) return true
        return false
    }

    override fun dispose() {
        baseEntity.dispose()
        hologram.dispose()
        indicatorEntity.dispose()
    }
}
