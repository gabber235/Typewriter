package com.typewritermc.engine.paper.content.modes

import com.github.shynixn.mccoroutine.folia.entityDispatcher
import com.github.shynixn.mccoroutine.folia.launch
import com.typewritermc.core.entries.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.failure
import com.typewritermc.core.utils.ok
import com.typewritermc.engine.paper.content.ContentContext
import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.entryId
import com.typewritermc.engine.paper.content.fieldPath
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.fieldValue
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import kotlinx.coroutines.delay
import org.bukkit.entity.Player
import java.lang.reflect.Type
import kotlin.time.Duration.Companion.milliseconds

abstract class ImmediateFieldValueContentMode<T : Any>(context: ContentContext, player: Player) :
    ContentMode(context, player) {
    abstract val type: Type

    override suspend fun setup(): Result<Unit> {
        val entryId = context.entryId
            ?: return failure("No entryId found for ${this::class.simpleName}. This is a bug. Please report it.")

        val fieldPath = context.fieldPath
            ?: return failure("No fieldPath found for ${this::class.simpleName}. This is a bug. Please report it.")

        // Needs to complete the initialisation so that we can properly get the value and end the content mode
        plugin.launch(plugin.entityDispatcher(player)) {
            delay(200.milliseconds)
            try {
                val value = value()
                Ref(entryId, Entry::class).fieldValue(fieldPath, value, type)
            } catch (e: Exception) {
                logger.severe("Failed to set field value for ${this::class.simpleName}, with context: $context. This is a bug. Please report it.")
                e.printStackTrace()
            } finally {
                InteractionEndTrigger.triggerFor(player, context())
            }
        }

        return ok(Unit)
    }

    abstract fun value(): T

}