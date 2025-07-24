package com.typewritermc.basic.entries.action

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Page
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.temporal.TemporalSettings
import com.typewritermc.engine.paper.entry.temporal.TemporalStartTrigger


@Entry("cinematic", "Start a new cinematic", Colors.RED, "fa-solid:camera-retro")
/**
 * The `Cinematic` action is used to start a new cinematic.
 *
 * A cinematic can only be overridden
 * if another cinematic is triggered with a higher page priority than the current one.
 *
 * ## How could this be used?
 *
 * This action can be useful in situations where you want to start a cinematic.
 * See the [Cinematic](/docs/creating-stories/cinematics) tutorial for more information.
 */
class CinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @SerializedName("page")
    @Page(PageType.CINEMATIC)
    @Help("The cinematic page to start.")
    val pageId: String = "",
    @Default("true")
    @Help("Whether to block chat messages from showing to the player while in the cinematic.")
    val blockChatMessages: Boolean = true,
    @Default("true")
    @Help("Whether to block actionbar messages from showing to the player while in the cinematic.")
    val blockActionBarMessages: Boolean = true
) : ActionEntry {
    override val eventTriggers: List<EventTrigger>
        get() = listOf(TemporalStartTrigger(pageId, super.eventTriggers, TemporalSettings(blockChatMessages, blockActionBarMessages)))

    override fun ActionTrigger.execute() {}
}