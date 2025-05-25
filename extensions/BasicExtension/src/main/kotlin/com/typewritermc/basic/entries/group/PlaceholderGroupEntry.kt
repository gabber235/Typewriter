package com.typewritermc.basic.entries.group

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.GroupId
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import org.bukkit.entity.Player
import java.nio.charset.StandardCharsets
import java.util.*

@Entry("placeholder_group", "Group based on a placeholder value", Colors.MYRTLE_GREEN, "bx:text-fields")
/**
 * The `Placeholder Group` is a group that includes all players with the same placeholder value.
 *
 * ## How could this be used?
 * This could be used to group players based on a specific placeholder value, such as their team, faction, or any other custom placeholder.
 */
class PlaceholderGroupEntry(
    override val id: String = "",
    override val name: String = "",
    @Placeholder
    val placeholder: String = ""
) : GroupEntry {
    override fun groupId(player: Player): GroupId {
        return GroupId(hashPlaceholder(placeholder.parsePlaceholders(player)))
    }

    /**
     * Hashes a placeholder value to a URL-safe string.
     * Uses Base64 URL-safe encoding to ensure the result can be safely used as a database key.
     *
     * @param value The placeholder value to hash
     * @return A URL-safe string representation of the hashed value
     */
    private fun hashPlaceholder(value: String): String {
        val valueBytes = value.toByteArray(StandardCharsets.UTF_8)
        return Base64.getUrlEncoder().withoutPadding().encodeToString(valueBytes)
    }
}