package com.typewritermc.basic.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.CachableFactEntry
import com.typewritermc.engine.paper.entry.entries.GroupEntry

@Entry("session_fact", "Saved until a player logouts of the server", Colors.PURPLE, "fa6-solid:user-clock")
@Deprecated("Doesn't work, use permanent fact with a quit trigger to reset it instead")
/**
 * This [fact](/docs/creating-stories/facts) is stored until the player logs out.
 *
 * ## How could this be used?
 *
 * This could be used to slowly add up a player's total time played, and reward them with a badge or other reward when they reach a certain amount of time.
 */
class SessionFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
) : CachableFactEntry