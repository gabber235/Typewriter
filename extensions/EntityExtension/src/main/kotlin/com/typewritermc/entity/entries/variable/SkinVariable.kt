package com.typewritermc.entity.entries.variable

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.entry.entity.SkinProperty
import com.typewritermc.engine.paper.entry.entity.skin
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.entries.safeCast
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.logger
import java.util.*
import kotlin.reflect.safeCast

@Entry(
    "skin_variable",
    "A variable that returns a players skin based on the uuid",
    Colors.GREEN,
    "ant-design:skin-filled"
)
@GenericConstraint(SkinProperty::class)
@VariableData(SkinVariableData::class)
/**
 * The `SkinVariable` is a variable that returns a players skin based on the uuid.
 *
 * The UUID must be a valid UUID, or a placeholder that returns a valid UUID.
 *
 * ## How could this be used?
 * This could be used to show NPCs of players on a leaderboard.
 */
class SkinVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<SkinVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)
        val possibleUUID = data.uuid.parsePlaceholders(context.player)
        val uuid = try {
            UUID.fromString(possibleUUID)
        } catch (e: IllegalArgumentException) {
            logger.warning("Could not parse uuid '$possibleUUID' for entry $id, using player uuid instead")
            context.player.uniqueId
        }
        val skin = server.getOfflinePlayer(uuid).skin
        return context.safeCast(skin)
            ?: throw IllegalStateException("Could not cast skin to ${context.klass}, SkinProperty is only compatible with SkinProperty fields")
    }
}

data class SkinVariableData(
    @Placeholder
    val uuid: String = "",
)
