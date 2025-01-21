package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.triggerFor
import org.bukkit.entity.Player

@Entry(
    "trigger_audience",
    "Triggers a sequence when the player enters or exits the audience",
    Colors.GREEN,
    "mdi:account-arrow-right"
)
/**
 * The `Trigger Audience` entry is an audience filter that triggers a sequence when the player enters or exits the audience.
 *
 * ## How could this be used?
 * This can be used to bridge the gap between audiences and sequence pages.
 */
class TriggerAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The sequence to trigger when the player enters the audience.")
    val onEnter: Ref<TriggerableEntry> = emptyRef(),
    @Help("The sequence to trigger when the player exits the audience.")
    val onExit: Ref<TriggerableEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = TriggerAudienceDisplay(onEnter, onExit)
}

class TriggerAudienceDisplay(
    private val onEnter: Ref<TriggerableEntry>,
    private val onExit: Ref<TriggerableEntry>,
) : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {
        onEnter.triggerFor(player, context())
    }

    override fun onPlayerRemove(player: Player) {
        onExit.triggerFor(player, context())
    }
}