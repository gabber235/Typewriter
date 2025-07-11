package com.typewritermc.core.entries

import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import kotlinx.serialization.Serializable
import java.util.*

val Entry.formattedName: String
    get() = name.split(".")
        .joinToString(" | ") { part -> part.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() } }
        .split("_")
        .joinToString(" ") { part -> part.replaceFirstChar { if (it.isLowerCase()) it.titlecase(Locale.getDefault()) else it.toString() } }

@Tags("entry")
interface Entry {
    val id: String
    val name: String
}

interface PriorityEntry : Entry {
    /**
     * Normally, the priority of an entry is determined by the priority of the page it is on.
     * Subtypes may want to allow the user to override the priority for that specific entry.
     * This is useful when entries need to have fine-grained control over their priority.
     */
    @Help("The priority of the entry. If not set, the priority of the page will be used.")
    val priorityOverride: Optional<Int>
}