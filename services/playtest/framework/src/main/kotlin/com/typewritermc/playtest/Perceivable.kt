package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Camera
import com.typewritermc.playtest.wire.Message.Entity
import com.typewritermc.playtest.wire.Message.Item
import com.typewritermc.playtest.wire.Message.Perception
import kotlin.math.hypot
import com.typewritermc.playtest.wire.Message.BlockPos as WireBlockPos

/** Something a player can perceive, judged from one perception record. */
interface Perceivable {
    /** How a failure names it, for example `chat "Hello"`. */
    val description: String

    /** Whether [perception] shows this after [stimulus], the window's anchor. */
    fun shownIn(
        perception: Perception,
        stimulus: Stimulus,
    ): Boolean

    /** How a report names what [perception] shows of this; a broad fact names the instance it found. */
    fun shownAs(
        perception: Perception,
        stimulus: Stimulus,
    ): String = description
}

/**
 * The window's anchor as a fact sees it: the [tick] in which the last stimulus ran, and the record the
 * player perceived then, or null when none came before it. Facts about a change compare with it.
 */
class Stimulus(
    val tick: Int,
    val perceived: Perception?,
)

/** A chat line holding [text] that arrived after the window's stimulus and is drawn legibly in the chat. */
fun chat(text: String): Perceivable =
    fact("chat \"$text\"") { perception, stimulus ->
        perception.chat().any { it.tick() > stimulus.tick && text in it.text() } &&
            perception.texts().any { it.element() == "chat" && text in it.text() }
    }

/** Any chat line that arrived after the window's stimulus, drawn or not: `outsider.never sees anyChat()`. */
fun anyChat(): Perceivable =
    object : Perceivable {
        override val description = "any chat"

        override fun shownIn(
            perception: Perception,
            stimulus: Stimulus,
        ) = arrived(perception, stimulus) != null

        override fun shownAs(
            perception: Perception,
            stimulus: Stimulus,
        ) = arrived(perception, stimulus)?.let { "chat \"${it.text()}\"" } ?: description

        private fun arrived(
            perception: Perception,
            stimulus: Stimulus,
        ) = perception.chat().firstOrNull { it.tick() > stimulus.tick }
    }

/** Any text a toast draws in the corner of the screen: `player.never sees anyToast()`. */
fun anyToast(): Perceivable =
    object : Perceivable {
        override val description = "any toast"

        override fun shownIn(
            perception: Perception,
            stimulus: Stimulus,
        ) = drawn(perception) != null

        override fun shownAs(
            perception: Perception,
            stimulus: Stimulus,
        ) = drawn(perception)?.let { "toast \"${it.text()}\"" } ?: description

        private fun drawn(perception: Perception) = perception.texts().firstOrNull { it.element() == "toast" }
    }

/** The command suggestion list shows exactly [names], top to bottom. */
fun suggestions(vararg names: String): Perceivable =
    fact("suggestions ${names.joinToString()}") { perception, _ ->
        perception.texts().filter { it.element() == "suggestions" }.map { it.text() } == names.toList()
    }

/** The hotbar's selection frame marks a slot showing [item], an item id such as `stick` or `minecraft:stick`. */
fun held(item: String): Perceivable = drawnItem("held", "hotbar", item) { it.selected() }

/** The off hand slot beside the hotbar shows [item]. */
fun offhand(item: String): Perceivable = drawnItem("offhand", "offhand", item)

/** The open screen draws [item] on the pointer, picked up from a slot. */
fun carried(item: String): Perceivable = drawnItem("carried", "carried", item)

/** Facts about the view the frame was drawn from, compared with the view at the stimulus. */
object CameraFacts {
    /** The eye is higher than at the stimulus. */
    fun rose(): Perceivable = change("camera rose") { now, then -> now.y() > then.y() }

    /** The eye is lower than at the stimulus. */
    fun sank(): Perceivable = change("camera sank") { now, then -> now.y() < then.y() }

    /** The spyglass overlay covers the view. */
    fun scoped(): Perceivable = fact("camera scoped") { perception, _ -> perception.camera()?.scoped() == true }

    /** The eye stands within [within] blocks of [x], [z], measured across the ground. */
    fun near(
        x: Double,
        z: Double,
        within: Double,
    ): Perceivable =
        fact("camera near $x $z within $within") { perception, _ ->
            val eye = perception.camera() ?: return@fact false
            hypot(eye.x() - x, eye.z() - z) <= within
        }

    private fun change(
        description: String,
        changed: (now: Camera, then: Camera) -> Boolean,
    ): Perceivable =
        fact(description) { perception, stimulus ->
            val now = perception.camera()
            val then = stimulus.perceived?.camera()
            now != null && then != null && changed(now, then)
        }
}

/** The view the frame was drawn from: `player sees camera.rose()`. */
val camera: CameraFacts get() = CameraFacts

/** Facts about a block an arrangement placed and watches. */
class BlockFacts internal constructor(
    private val block: BlockRef,
) {
    /** The block changed to [id] after the stimulus, and the player perceives it so. */
    fun becomes(id: String): Perceivable = changedTo("block $block becomes $id", id.id())

    /** The block changed to air after the stimulus, and the player perceives the gap. */
    fun gone(): Perceivable = changedTo("block $block gone", "minecraft:air")

    private fun changedTo(
        description: String,
        id: String,
    ): Perceivable =
        fact(description) { perception, stimulus ->
            val at = WireBlockPos(block.at.x, block.at.y, block.at.z)
            perception.blocks().any { it.at() == at && it.block() == id && it.seen() && it.changed() > stimulus.tick }
        }
}

/** Facts about [ref], a block a probe placed: `player sees block(leaves).gone()`. */
fun block(ref: BlockRef): BlockFacts = BlockFacts(ref)

/** Facts about an entity an arrangement spawned and watches. */
class EntityFacts internal constructor(
    private val entity: EntityRef,
) {
    /** The frame draws the entity with the red tint of a hit. */
    fun hurt(): Perceivable = drawn("entity $entity hurt") { it.hurt() }

    /** The frame draws the entity with a name tag holding [name]. */
    fun named(name: String): Perceivable = drawn("entity $entity named \"$name\"") { it.name()?.contains(name) == true }

    private fun drawn(
        description: String,
        shows: (Entity) -> Boolean,
    ): Perceivable = fact(description) { perception, _ -> perception.entities().any { it.uuid() == entity.uuid && shows(it) } }
}

/** Facts about [ref], an entity a probe spawned: `player sees entity(guide).named("Ouch")`. */
fun entity(ref: EntityRef): EntityFacts = EntityFacts(ref)

private fun drawnItem(
    name: String,
    element: String,
    item: String,
    marked: (Item) -> Boolean = { true },
): Perceivable {
    val id = item.id()
    return fact("$name $item") { perception, _ -> perception.items().any { it.element() == element && it.item() == id && marked(it) } }
}

private fun fact(
    description: String,
    shown: (Perception, Stimulus) -> Boolean,
): Perceivable =
    object : Perceivable {
        override val description = description

        override fun shownIn(
            perception: Perception,
            stimulus: Stimulus,
        ) = shown(perception, stimulus)
    }
