package com.typewritermc.engine.paper.content

import com.typewritermc.engine.paper.content.components.IntractableItem
import com.typewritermc.engine.paper.content.components.ItemsComponent
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import org.bukkit.entity.Player
import java.time.Duration

abstract class ContentMode(
    val context: ContentContext,
    val player: Player,
) : ComponentContainer {
    override val components = mutableListOf<ContentComponent>()

    /**
     * If the result is [Result.Failure], the content mode will not be started.
     */
    abstract suspend fun setup(): Result<Unit>

    open suspend fun initialize() {
        components.forEach { it.initialize(player) }
    }

    open suspend fun tick(deltaTime: Duration) {
        components.forEach { it.tick(player) }
    }

    open suspend fun dispose() {
        components.forEach { it.dispose(player) }
    }

    fun items(): Map<Int, IntractableItem> {
        return components.filterIsInstance<ItemsComponent>().flatMap { it.items(player).toList() }.toMap()
    }
}

interface ComponentContainer {
    val components: MutableList<ContentComponent>
    operator fun <C : ContentComponent> C.unaryPlus(): C {
        components.add(this)
        return this
    }
}

open class ContentModeTrigger(
    val context: ContentContext,
    val mode: ContentMode,
) : EventTrigger {
    override val id: String
        get() = "content.${mode::class.simpleName}"

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is ContentModeTrigger) return false

        return id == other.id
    }

    override fun hashCode(): Int {
        return id.hashCode()
    }
}

/**
 * Swaps the content mode to the given mode.
 *
 * If no content mode is currently active, this will start a new context.
 */
class ContentModeSwapTrigger(
    context: ContentContext,
    mode: ContentMode,
) : ContentModeTrigger(context, mode) {
    override val id: String
        get() = "content.swap.${mode::class.simpleName}"
}

data object ContentPopTrigger : EventTrigger {
    override val id: String
        get() = "system.content.pop"
}
